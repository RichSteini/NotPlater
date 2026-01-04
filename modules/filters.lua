if not NotPlater then return end

local L = NotPlaterLocals

local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local IsInInstance = IsInInstance
local sfind = string.find
local slower = string.lower
local GetZoneText = GetZoneText
local GetSubZoneText = GetSubZoneText
local SetMapToCurrentZone = SetMapToCurrentZone
local GetCurrentMapAreaID = GetCurrentMapAreaID
local abs = math.abs

local playerFaction = UnitFactionGroup("player")

local function IsFactionMatch(factionId)
	local enums = NotPlater.NPCEnums and NotPlater.NPCEnums.Faction
	if not enums then
		return false
	end
	if playerFaction == "Horde" then
		return factionId == enums.Horde
	end
	if playerFaction == "Alliance" then
		return factionId == enums.Alliance
	end
	return false
end

local NAMEPLATE_COLORS = {
	hostile = {1, 0, 0},
	neutral = {1, 1, 0},
	friendly = {0, 1, 0},
	friendlyPlayer = {0, 0.6, 1},
	tapped = {0.5, 0.5, 0.5},
}

local cachedZoneName
local cachedZoneId
local cachedSubzoneName
local cachedSubzoneId

local function GetCurrentZoneAreaId()
	if not SetMapToCurrentZone or not GetCurrentMapAreaID then
		return nil
	end
	local zoneName = GetZoneText()
	if cachedZoneName == zoneName and cachedZoneId then
		return cachedZoneId
	end
	SetMapToCurrentZone()
	cachedZoneName = zoneName
	cachedSubzoneName = nil
	cachedSubzoneId = nil
	cachedZoneId = GetCurrentMapAreaID()
	return cachedZoneId
end

local function GetCurrentSubzoneAreaId()
	if not SetMapToCurrentZone or not GetCurrentMapAreaID then
		return nil
	end
	local zoneName = GetZoneText()
	local subzoneName = GetSubZoneText()
	if cachedZoneName == zoneName and cachedSubzoneName == subzoneName and cachedSubzoneId then
		return cachedSubzoneId
	end
	SetMapToCurrentZone()
	cachedZoneName = zoneName
	cachedSubzoneName = subzoneName
	cachedSubzoneId = GetCurrentMapAreaID()
	return cachedSubzoneId
end

local function GetNameplateColorKey(r, g, b)
	for key, color in pairs(NAMEPLATE_COLORS) do
		if abs(color[1] - r) <= 0.1 and abs(color[2] - g) <= 0.1 and abs(color[3] - b) <= 0.1 then
			return key
		end
	end
	if r and g and b and abs(r) <= 0.1 and abs(g) <= 0.1 and abs(b - 1) <= 0.1 then
		return "friendlyPlayer"
	end
	return nil
end

function NotPlater:GetNameplateColorKeyFromRGB(r, g, b)
	return GetNameplateColorKey(r, g, b)
end

function NotPlater:GetNameplateColorOptions()
	return {
		hostile = L["Hostile"],
		neutral = L["Neutral"],
		friendly = L["Friendly"],
		friendlyPlayer = L["Friendly Player"],
		tapped = L["Tapped"],
	}
end

local function GetNpcClassToken(classId)
	local enums = NotPlater.NPCEnums and NotPlater.NPCEnums.Class
	if not enums then
		return nil
	end
	if classId == enums.Warrior then return "WARRIOR" end
	if classId == enums.Paladin then return "PALADIN" end
	if classId == enums.Hunter then return "HUNTER" end
	if classId == enums.Rogue then return "ROGUE" end
	if classId == enums.Priest then return "PRIEST" end
	if classId == enums.DeathKnight then return "DEATHKNIGHT" end
	if classId == enums.Shaman then return "SHAMAN" end
	if classId == enums.Mage then return "MAGE" end
	if classId == enums.Warlock then return "WARLOCK" end
	if classId == enums.Druid then return "DRUID" end
	return nil
end

local function GetFrameName(frame)
	return frame and frame.defaultNameText and frame.defaultNameText:GetText() or nil
end

local function GetFrameLevel(frame)
	local levelText = frame and frame.levelText
	if not levelText then
		return nil
	end
	return tonumber(levelText:GetText())
end

function NotPlater:FilterMatches(frame, filter)
	local criteria = filter.criteria
	local unitName = GetFrameName(frame)
	local npcData = unitName and NotPlater.NPCData and NotPlater.NPCData[unitName]

	if criteria.faction.enable then
		local faction = frame and frame.unitFaction
		if npcData then
			if npcData.faction == NotPlater.NPCEnums.Faction.Horde then
				faction = "Horde"
			elseif npcData.faction == NotPlater.NPCEnums.Faction.Alliance then
				faction = "Alliance"
			else
				faction = "Neutral"
			end
		end
		local values = criteria.faction.values or {}
		local matchesDirect = values[faction]
		local matchesMyFaction = values.MyFaction and playerFaction and faction == playerFaction
		if not (matchesDirect or matchesMyFaction) then
			return false
		end
	end

	if criteria.class.enable then
		local classToken = nil
		local matchedUnit = frame.lastUnitMatch
		if frame and frame.unitClassToken then
			classToken = frame.unitClassToken
		elseif matchedUnit and UnitExists(matchedUnit) then
			classToken = select(2, UnitClass(matchedUnit))
		end
		if not criteria.class.values[classToken] then
			return false
		end
	end

	if criteria.npcType and criteria.npcType.enable then
		if not npcData or not npcData.flags or not IsFactionMatch(npcData.faction) then
			return false
		end
		local values = criteria.npcType.values or {}
		local enums = NotPlater.NPCEnums
		local flagEnums = enums and enums.Flags
		local matched = false
		if values.vendor and flagEnums and flagEnums.Vendor and bit.band(npcData.flags, flagEnums.Vendor) > 0 then
			matched = true
		end
		if values.repair and flagEnums and flagEnums.Repair and bit.band(npcData.flags, flagEnums.Repair) > 0 then
			matched = true
		end
		if values.innkeeper and flagEnums and flagEnums.Innkeeper and bit.band(npcData.flags, flagEnums.Innkeeper) > 0 then
			matched = true
		end
		if values.flightMaster and flagEnums and flagEnums.FlightMaster and bit.band(npcData.flags, flagEnums.FlightMaster) > 0 then
			matched = true
		end
		if values.auctioneer and flagEnums and flagEnums.Auctioneer and bit.band(npcData.flags, flagEnums.Auctioneer) > 0 then
			matched = true
		end
		if values.banker and flagEnums and flagEnums.Banker and bit.band(npcData.flags, flagEnums.Banker) > 0 then
			matched = true
		end
		if values.classTrainer and npcData.trainer and npcData.trainer > 0 then
			matched = true
		end
		if not matched then
			return false
		end
	end

	if criteria.instanceType and criteria.instanceType.enable then
		local _, instanceType = IsInInstance()
		local key = instanceType == "none" and "world" or instanceType
		local values = criteria.instanceType.values or {}
		if not values[key] then
			return false
		end
	end

	if criteria.name.enable then
		local value = criteria.name.value
		if not value or value == "" or not unitName then
			return false
		end
		local mode = criteria.name.matchMode or "EXACT"
		local haystack = slower(unitName)
		local needle = slower(value)
		if mode == "CONTAINS" then
			if not sfind(haystack, needle, 1, true) then
				return false
			end
		else
			if haystack ~= needle then
				return false
			end
		end
	end

	if criteria.zone.enable then
		local zoneId = criteria.zone.id
		if zoneId then
			local currentZoneId = GetCurrentZoneAreaId()
			if not currentZoneId or currentZoneId ~= zoneId then
				return false
			end
		else
			local zoneName = GetZoneText()
			local value = criteria.zone.value
			if not value or value == "" or not zoneName then
				return false
			end
			local mode = criteria.zone.matchMode or "EXACT"
			local haystack = slower(zoneName)
			local needle = slower(value)
			if mode == "CONTAINS" then
				if not sfind(haystack, needle, 1, true) then
					return false
				end
			else
				if haystack ~= needle then
					return false
				end
			end
		end
	end

	if criteria.subzone.enable then
		local subzoneId = criteria.subzone.id
		if subzoneId then
			local currentSubzoneId = GetCurrentSubzoneAreaId()
			if not currentSubzoneId or currentSubzoneId ~= subzoneId then
				return false
			end
		else
			local subzoneName = GetSubZoneText()
			local value = criteria.subzone.value
			if not value or value == "" or not subzoneName then
				return false
			end
			local mode = criteria.subzone.matchMode or "EXACT"
			local haystack = slower(subzoneName)
			local needle = slower(value)
			if mode == "CONTAINS" then
				if not sfind(haystack, needle, 1, true) then
					return false
				end
			else
				if haystack ~= needle then
					return false
				end
			end
		end
	end

	if criteria.healthColor.enable then
		local key = frame and frame.defaultHealthColorKey
		if not key and frame and frame.defaultHealthColor then
			key = GetNameplateColorKey(frame.defaultHealthColor[1], frame.defaultHealthColor[2], frame.defaultHealthColor[3])
		end
		if key == "friendly" then
			key = "friendlyNpc"
		end
		local values = criteria.healthColor.values
		if values then
			if not (values[key] or (key == "friendlyNpc" and values.friendly)) then
				return false
			end
		else
			local value = criteria.healthColor.value
			if value == "friendly" then
				value = "friendlyNpc"
			end
			if not key or key ~= value then
				return false
			end
		end
	end

	if criteria.level.enable then
		local level = npcData and npcData.level
		if not level then
			level = GetFrameLevel(frame)
		end
		if not level then
			return false
		end
		local minLevel = criteria.level.min
		local maxLevel = criteria.level.max
		if minLevel and level < minLevel then
			return false
		end
		if maxLevel and level > maxLevel then
			return false
		end
	end

	if criteria.healthPercent and criteria.healthPercent.enable then
		local healthBar = frame and frame.healthBar
		if not healthBar or not healthBar.GetMinMaxValues or not healthBar.GetValue then
			return false
		end
		local minValue, maxValue = healthBar:GetMinMaxValues()
		local value = healthBar:GetValue()
		local range = maxValue and minValue and (maxValue - minValue) or nil
		if not value or not range or range <= 0 then
			return false
		end
		local percent = (value - minValue) / range * 100
		local minPercent = criteria.healthPercent.min
		local maxPercent = criteria.healthPercent.max
		if minPercent and percent < minPercent then
			return false
		end
		if maxPercent and percent > maxPercent then
			return false
		end
	end

	return true
end

function NotPlater:ApplyFilterEffects(frame, filter)
	if not frame then
		return
	end
	local hide = filter and filter.effects and filter.effects.hide or nil
	frame.filterHiddenComponents = frame.filterHiddenComponents or {}

	local order = self:GetStackingComponentOrder()
	local hideHealthBar = hide and hide.healthBar
	if hideHealthBar then
		for index = 1, #order do
			local key = order[index]
			if key ~= "healthBar" then
				local region = self:GetStackingComponentRegion(frame, key)
				if region and region.npVisibilityAnchor == frame.healthBar and not (hide and hide[key]) then
					region.npVisibilityOverride = true
					region.npVisibilityOverrideShown = region:IsShown()
				end
			end
		end
	end
	for index = 1, #order do
		local key = order[index]
		local shouldHide = hide and hide[key]
		local region = self:GetStackingComponentRegion(frame, key)
		if region then
			if shouldHide then
				if not frame.filterHiddenComponents[key] then
					frame.filterHiddenComponents[key] = region:IsShown()
				end
				region.npFilterHidden = true
				region:Hide()
			else
				region.npFilterHidden = nil
				if frame.filterHiddenComponents[key] ~= nil then
					if frame.filterHiddenComponents[key] then
						region:Show()
					end
					frame.filterHiddenComponents[key] = nil
				end
				if hideHealthBar and region.npVisibilityAnchor == frame.healthBar then
					region.npVisibilityOverride = true
					region.npVisibilityOverrideShown = true
					region:Show()
				end
			end
		end
	end
	if not hideHealthBar then
		for index = 1, #order do
			local key = order[index]
			local region = self:GetStackingComponentRegion(frame, key)
			if region and region.npVisibilityOverride and region.npVisibilityAnchor == frame.healthBar then
				local shouldShow = region.npVisibilityAnchor and region.npVisibilityAnchor:IsShown()
				region.npVisibilityOverride = nil
				region.npVisibilityOverrideShown = nil
				if region.npFilterHidden then
					region:Hide()
				elseif shouldShow then
					region:Show()
				else
					region:Hide()
				end
			end
		end
	end

	local hideNameText = hide and hide.nameText
	if hideNameText then
		frame.filterHideNameText = true
		if frame.nameText then
			frame.nameText:Hide()
		end
		return
	end

	frame.filterHideNameText = nil
	local nameTextConfig = filter and filter.effects and filter.effects.nameText
	local config = nameTextConfig and nameTextConfig.config
	if config then
		frame.filterNameTextConfig = config
		self:ConfigureNameTextWithConfig(frame.nameText, frame.healthBar, config)
	else
		frame.filterNameTextConfig = nil
		self:ConfigureNameText(frame.nameText, frame.healthBar)
	end
end

function NotPlater:ApplyFilters(frame)
	if frame and frame.isSimulatorFrame then
		self:ApplyFilterEffects(frame, nil)
		return
	end
	local filters = self.db.profile.filters and self.db.profile.filters.list
	if not filters or #filters == 0 then
		self:ApplyFilterEffects(frame, nil)
		return
	end
	for index = 1, #filters do
		local filter = filters[index]
		if filter and filter.enabled and self:FilterMatches(frame, filter) then
			self:ApplyFilterEffects(frame, filter)
			return
		end
	end
	self:ApplyFilterEffects(frame, nil)
end

function NotPlater:ApplyFiltersAll()
	if self.frames then
		for frame in pairs(self.frames) do
			if frame:IsShown() then
				self:ApplyFilters(frame)
			end
		end
	end
	if self.simulatorFrame and self.simulatorFrame.defaultFrame then
		self:ApplyFilters(self.simulatorFrame.defaultFrame)
	end
end
