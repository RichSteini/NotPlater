if not NotPlater then return end

local L = NotPlaterLocals

local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local GetZoneText = GetZoneText
local GetSubZoneText = GetSubZoneText
local abs = math.abs

local playerFaction = UnitFactionGroup("player")

local NAMEPLATE_COLORS = {
	hostile = {1, 0, 0},
	neutral = {1, 1, 0},
	friendly = {0, 1, 0},
	friendlyPlayer = {0, 0.6, 1},
	tapped = {0.5, 0.5, 0.5},
}

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

	if criteria.name.enable then
		if not unitName or unitName ~= criteria.name.value then
			return false
		end
	end

	if criteria.zone.enable then
		local zoneName = GetZoneText()
		if zoneName ~= criteria.zone.value then
			return false
		end
	end

	if criteria.subzone.enable then
		local subzoneName = GetSubZoneText()
		if subzoneName ~= criteria.subzone.value then
			return false
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
