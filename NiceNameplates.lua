------------------------------------------------------------------------------------
-- NiceNameplates by Demorto#2660 Version: 8.0.1.4
------------------------------------------------------------------------------------

local INFO_POINT            = 'TOP'
local INFO_RELATIVE_POINT   = 'BOTTOM'
local INFO_X                = 0
local INFO_Y                = 0

local NAMEPLATE_ALPHA       = 0.7


NiceNameplates = LibStub('AceAddon-3.0'):NewAddon('NiceNameplates', 'AceHook-3.0', 'AceEvent-3.0')

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local NiceNameplatesTooltip = CreateFrame('GameTooltip', 'NiceNameplatesTooltip', nil, 'GameTooltipTemplate')

local BLACKLIST = {
	['89713'] = true; 	-- Koak Hoburn, heirloom mount driver
	['89715'] = true;	-- Franklin Martin, heirloom mount driver
}


function NiceNameplates:OnEnable()
    SetCVar('nameplateShowAll', true)
    SetCVar('nameplateShowFriends', true)
    SetCVar('nameplateShowFriendlyNPCs', true)
    SetCVar('showQuestTrackingTooltips', true)

    self:RegisterEvent('NAME_PLATE_CREATED')
    self:RegisterEvent('NAME_PLATE_UNIT_ADDED')
    self:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
    self:RegisterEvent('UNIT_THREAT_LIST_UPDATE')

    self:SecureHook('CompactUnitFrame_UpdateName')

    DEFAULT_CHAT_FRAME:AddMessage(GetAddOnMetadata(self:GetName(), "Title").." loaded!")
end


function NiceNameplates:CompactUnitFrame_UpdateName(frame)
    if ( strsub(frame.unit, 1, 9) == "nameplate" ) then
        self:NiceNameplateInfo_Update(frame.unit)
        self:NiceNameplateFrames_Update(frame.unit)
    end
end


function NiceNameplates:NAME_PLATE_CREATED(_, frame)
    self:NiceNameplateInfo_Create(frame)
end


function NiceNameplates:NAME_PLATE_UNIT_ADDED(_, unit)
    self:NiceNameplateInfo_Update(unit)
    self:NiceNameplateFrames_Update(unit)
end


function NiceNameplates:NAME_PLATE_UNIT_REMOVED(_, unit)
    self:NiceNameplateInfo_Update(unit)
    self:NiceNameplateFrames_Update(unit)
end


function NiceNameplates:UNIT_THREAT_LIST_UPDATE(_, unit)
    if unit and unit:match('nameplate') then
        self:NiceNameplateInfo_Update(unit)
        self:NiceNameplateFrames_Update(unit)
    end
end


local function GetUnitProperties(unit)
	local guid = UnitGUID(unit)
	if not guid then return end
	local unitType, _, _, _, _, ID = strsplit('-',guid)
	return unitType, ID
end


local function IsNPC(unit)
	local unitType, ID = GetUnitProperties(unit)
	return 	not UnitIsBattlePet(unit) and		-- unit should not be battlepet
			not UnitIsPlayer(unit) and			-- unit should not be player
			not UnitPlayerControlled(unit) and 		-- unit should not be bodyguard
			not UnitIsEnemy('player', unit) and -- unit should not be enemy
			not UnitCanAttack('player', unit) and
			(unitType == 'Creature') and	-- GUID should start with Creature
			(not BLACKLIST[ID])				-- check with blacklist
end


local function RGBToHex(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    local string = string.format("%02x%02x%02x", r*255, g*255, b*255)
    return string
end


function NiceNameplates:MakeInfoString(unit, item)
    NiceNameplatesTooltip:SetOwner(WorldFrame, 'ANCHOR_NONE')
    NiceNameplatesTooltip:SetUnit(unit)

    if item == 'name' then
        local name, _ = UnitName(unit)
        return name
    elseif item == 'realm' then
        local _, realm = UnitName(unit)
        return realm
    elseif item == 'level' then
        local level = UnitLevel(unit)
        if level == -1 then level = '??' end
        return level
    elseif item == 'levelcolor' then
        local level = UnitLevel(unit)
        if level == -1 then level = 255 end
        local levelcolor = GetCreatureDifficultyColor(level)
        return levelcolor
    elseif item == 'fullname' then
        local _, realm = UnitName(unit)
        local TooltipTextLeft1 = NiceNameplatesTooltipTextLeft1:GetText()
        local fullname =    ( not realm and TooltipTextLeft1 ) or
                            ( realm and TooltipTextLeft1:gsub('-'..realm, '(*)'))
        return fullname
    elseif item == 'guild' then
        local guild, _, _ = GetGuildInfo(unit)
        return guild
    elseif item == 'profession' then
        if NiceNameplatesTooltip:NumLines() > 2 then
            for i = 2, NiceNameplatesTooltip:NumLines() do
                local TooltipTextLeft = _G['NiceNameplatesTooltipTextLeft' .. i]:GetText()
                if not ( TooltipTextLeft:lower():match(LEVEL_GAINED:gsub('%%d', '[%%d?]+'):lower()) or TooltipTextLeft:lower():match(LEVEL:lower()..' ([%d?]+)%s?%(?([^)]*)%)?')) then
                    return TooltipTextLeft
                else
                    TooltipTextLeft = _G['NiceNameplatesTooltipTextLeft' .. i + 1]:GetText()
                    return not TooltipTextLeft:match(PVP) and TooltipTextLeft
                end
            end
        end


        --[[
        local TooltipTextLeft = NiceNameplatesTooltipTextLeft2:GetText()
        local isWrong = TooltipTextLeft:lower():match(LEVEL_GAINED:gsub('%%d', '[%%d?]+'):lower()) or TooltipTextLeft:lower():match(LEVEL:lower()..' ([%d?]+)%s?%(?([^)]*)%)?')
        if not isWrong then
            return TooltipTextLeft
        else
            for i = 2, NiceNameplatesTooltip:NumLines() do
                TooltipTextLeft = _G['NiceNameplatesTooltipTextLeft' .. i]:GetText()
                if TooltipTextLeft:lower():match(LEVEL:lower()) then
                    TooltipTextLeft = _G['NiceNameplatesTooltipTextLeft' .. i+1]
                    break
                end
            end
            return TooltipTextLeft
            --return false
        end
        ]]--
    elseif item == 'localizedclass' then
        local localizedclass, _ = UnitClass(unit)
        return localizedclass
    elseif item == 'englishclass' then
        local _, englishclass = UnitClass(unit)
        return englishclass
    elseif item == 'classcolor' then
        local _, englishclass = UnitClass(unit)
        local classcolor = RAID_CLASS_COLORS[englishclass]
        return classcolor
    elseif item == 'localizedrace' then
        local localizedrace, _ = UnitRace(unit)
        return localizedrace
    elseif item == 'englishrace' then
        local _, englishrace = UnitRace(unit)
        return englishrace
    elseif item == 'creaturetype' then
        local creaturetype = UnitCreatureType(unit)
        return creaturetype
    elseif item == 'creaturefamily' then
        local creaturefamily = UnitCreatureFamily(unit)
        return creaturefamily
    elseif item == 'questinfo' then
        local ObjectiveCount = 0
        local QuestName

        if NiceNameplatesTooltip:NumLines() >= 3 then
            for i = 3, NiceNameplatesTooltip:NumLines() do
                local QuestLine = _G['NiceNameplatesTooltipTextLeft' .. i]
                local QuestLineText = QuestLine and QuestLine:GetText()

                local PlayerName, ProgressText = strmatch(QuestLineText, '^ ([^ ]-) ?%- (.+)$')

                if not ( PlayerName and PlayerName ~= '' and PlayerName ~= UnitName('player') ) then
                    local x, y
                    if not QuestName and ProgressText then
                        QuestName = _G['NiceNameplatesTooltipTextLeft' .. i - 1]:GetText()
                    end
                    if ProgressText then
                        x, y = strmatch(ProgressText, '(%d+)/(%d+)')
                        if x and y then
                            local NumLeft = y - x
                            if NumLeft > ObjectiveCount then -- track highest number of objectives
                                ObjectiveCount = NumLeft
                                if ProgressText then
                                    return ProgressText
                                else
                                    return false
                                end
                            end
                        else
                            if ProgressText then
                                return QuestName .. ': ' .. ProgressText
                            else
                                return false
                            end
                        end
                    end
                end
            end
        else
            return false
        end
    elseif item == 'questcolorinfo' then
        local ObjectiveCount = 0
        local QuestName
        local ProgressColored


        if NiceNameplatesTooltip:NumLines() >= 3 then
            for i = 3, NiceNameplatesTooltip:NumLines() do
                local QuestLine = _G['NiceNameplatesTooltipTextLeft' .. i]
                local QuestLineText = QuestLine and QuestLine:GetText()

                local PlayerName, ProgressText = strmatch(QuestLineText, '^ ([^ ]-) ?%- (.+)$')

                if not ( PlayerName and PlayerName ~= '' and PlayerName ~= UnitName('player') ) then
                    local x, y
                    if not QuestName and ProgressText then
                        QuestName = _G['NiceNameplatesTooltipTextLeft' .. i - 1]:GetText()
                    end
                    if ProgressText then
                        x, y = strmatch(ProgressText, '(%d+)/(%d+)')
                        if x and y then
                            local NumLeft = y - x
                            if NumLeft > ObjectiveCount then -- track highest number of objectives
                                ObjectiveCount = NumLeft
                                ProgressColored = ProgressText
                            end
                        else
                            ProgressColored = QuestName .. ': ' .. ProgressText
                        end
                    end
                end
            end
            if ProgressColored then
                for i = 1, GetNumQuestLogEntries() do
                    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(i)
                    if not isHeader and title == QuestName then
                        local colors = GetQuestDifficultyColor(level)
                        return '|cFF'..RGBToHex(colors.r, colors.g, colors.b)..ProgressColored..'|r'
                    end
                --[[
                    if not isHeader then
                        for objectiveID = 1, GetNumQuestLeaderBoards(i) or 0 do
                            local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveID, false)
                            if objectiveText == ProgressColored then

                                local colors = GetQuestDifficultyColor(level)
                                return '|cFF'..RGBToHex(colors.r, colors.g, colors.b)..ProgressColored..'|r'
                            end
                        end
                    end
                    ]]--
                end
            else
                return false
            end
        else
            return false
        end
    end

end


function NiceNameplates:NiceNameplateFrames_Update(unit)
    if not UnitIsUnit('player', unit) then
        local NamePlate = GetNamePlateForUnit(unit)
        if not NamePlate then return end
        local UnitFrame = NamePlate and NamePlate.UnitFrame
        local healthBar = UnitFrame.healthBar
        local NiceNameplateInfo = UnitFrame.NiceNameplateInfo
        local classificationIndicator = UnitFrame.ClassificationFrame.classificationIndicator

        local isFriend = UnitIsFriend('player', unit)
        local isPlayer = UnitIsPlayer(unit)
        local isTarget = UnitIsUnit('target', unit)
        local isCombat = UnitThreatSituation('player', unit)
        local classification = UnitClassification(unit)
        local isBoss = ( false or ( classification == 'elite' or classification == 'worldboss' or classification == 'rareelite' ) )

        UnitFrame:SetAlpha((isTarget and 1) or NAMEPLATE_ALPHA) -- Set alpha for not target units
        healthBar.border:SetScale((isTarget and 1.2) or 1) -- Set alpha for not target units

        if healthBar then
            healthBar:SetShown( isCombat or not (isFriend or not isTarget) or (isPlayer and isTarget) or (isPlayer and not isFriend) )
            --healthBar:SetShown( not IsNPC(unit) and ( isCombat or not (isFriend or not isTarget) or (UnitIsPlayer(unit) and isTarget) ) )
            classificationIndicator:SetShown( isCombat and isBoss or (isBoss and not (isFriend or not isTarget) ) )
        end

        if NiceNameplateInfo then
            NiceNameplateInfo:SetShown(UnitFrame.name:GetText() and UnitFrame.name:IsVisible() and not healthBar:IsVisible())
        end
    end
end


function NiceNameplates:NiceNameplateInfo_Create(frame)
    if not UnitIsUnit('player', frame:GetName()) then
        local NamePlate = frame
        if not NamePlate then return end
        local UnitFrame = NamePlate and NamePlate.UnitFrame

        if UnitFrame and not UnitFrame.NiceNameplateInfo then
            UnitFrame.NiceNameplateInfo = UnitFrame:CreateFontString(nil)
            UnitFrame.NiceNameplateInfo:SetFontObject(SystemFont_NamePlate)
            UnitFrame.NiceNameplateInfo:SetPoint(INFO_POINT, NamePlate.UnitFrame.name, INFO_RELATIVE_POINT, INFO_X, INFO_Y)
            UnitFrame.NiceNameplateInfo:Hide()
        end
    end
end


function NiceNameplates:NiceNameplateInfo_Update(unit)
    if not UnitIsUnit('player', unit) then
        local NamePlate = GetNamePlateForUnit(unit)
        if not NamePlate then return end
        local UnitFrame = NamePlate and NamePlate.UnitFrame
        local UnitName = UnitFrame and UnitFrame.name
        local NiceNameplateInfo = UnitFrame and UnitFrame.NiceNameplateInfo

        local isFriend = UnitIsFriend('player', unit)
        local isPlayer = UnitIsPlayer(unit)
        local isEnemy = UnitIsEnemy('player', unit) or UnitCanAttack('player', unit)
        local isNPC = IsNPC(unit)
        if NiceNameplateInfo then
            --print()
            if ( isPlayer and not isEnemy ) then
                local classColor = self:MakeInfoString(unit, 'classcolor')
                NiceNameplateInfo:SetText(self:MakeInfoString(unit, 'guild'))
                UnitName:SetTextColor(classColor.r, classColor.g, classColor.b)
                UnitName:SetText(self:MakeInfoString(unit, 'fullname'))
            elseif ( isPlayer and isEnemy ) then
                NiceNameplateInfo:SetText(self:MakeInfoString(unit, 'guild'))
                UnitName:SetText(self:MakeInfoString(unit, 'fullname'))
            elseif ( isEnemy and not self:MakeInfoString(unit, 'questinfo') ) then
                local levelColor = self:MakeInfoString(unit, 'levelcolor') or {r = 1, g = 1, b = 1 }

                local InfoString = format('%s, '..LEVEL_GAINED:gsub('%%d', '|cFF%%s%%s|r'), self:MakeInfoString(unit, 'creaturetype') or ENEMY, RGBToHex(levelColor.r, levelColor.g, levelColor.b), self:MakeInfoString(unit, 'level'))
                NiceNameplateInfo:SetText(InfoString)
            elseif ( isNPC and not self:MakeInfoString(unit, 'questinfo') ) then
                NiceNameplateInfo:SetText(self:MakeInfoString(unit, 'profession'))
            elseif ( self:MakeInfoString(unit, 'questinfo') ) then
                NiceNameplateInfo:SetText(self:MakeInfoString(unit, 'questcolorinfo'))
            else
                NiceNameplateInfo:SetText(nil)
            end
        end
    end
end


function NiceNameplates:NiceNameplateInfo_Delete(unit)
    if not UnitIsUnit('player', unit) then
        local NamePlate = GetNamePlateForUnit(unit)
        if not NamePlate then return end
        local UnitFrame = NamePlate and NamePlate.UnitFrame
        local NiceNameplateInfo = UnitFrame and UnitFrame.NiceNameplateInfo

        NiceNameplateInfo:SetText(nil)
        NiceNameplateInfo:Hide()
    end
end