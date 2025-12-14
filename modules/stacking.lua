if( not NotPlater ) then return end

local L = NotPlaterLocals
local tinsert = table.insert
local UnitAffectingCombat = UnitAffectingCombat
local format = string.format
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)

local DEFAULT_COMPONENT_ORDER = NotPlater.defaultStackingComponents or {}

function NotPlater:GetStackingSettings()
	local stacking = self.db.profile.stacking or {}
	return stacking.stackingSettings or {}
end

local function GetSafeStrata(frame, fallback)
	local strata = frame and frame:GetFrameStrata() or fallback or "LOW"
	if not strata or strata == "" or strata == "UNKNOWN" then
		strata = fallback or "LOW"
	end
	return strata
end

local function SetContainerVisibility(container, shouldShow)
	if shouldShow then
		container:Show()
	else
		container:Hide()
	end
end

local function SyncContainerVisibility(container, anchorFrame)
	if not container then
		return
	end
	if container.npVisibilityAnchor == anchorFrame then
		if anchorFrame then
			SetContainerVisibility(container, anchorFrame:IsShown())
		else
			SetContainerVisibility(container, true)
		end
		return
	end

	container.npVisibilityAnchor = anchorFrame

	if not anchorFrame then
		SetContainerVisibility(container, true)
		return
	end

	local function UpdateVisibility()
		if container.npVisibilityAnchor ~= anchorFrame then
			return
		end

		SetContainerVisibility(container, anchorFrame:IsShown())
	end

	-- only works in 3.3.5
	--anchorFrame:HookScript("OnShow", UpdateVisibility)
	--anchorFrame:HookScript("OnHide", UpdateVisibility)

	-- works in 2.4.3
	hooksecurefunc(anchorFrame, "Show", UpdateVisibility)
	hooksecurefunc(anchorFrame, "Hide", UpdateVisibility)

	UpdateVisibility()
end

local function EnsureRegionContainer(frame, key, region, anchorFrame)
	if not frame or not region then
		return nil
	end
	frame.stackingContainers = frame.stackingContainers or {}
	local container = frame.stackingContainers[key]
	if not container then
		container = CreateFrame("Frame", nil, frame)
		container:EnableMouse(false)
		frame.stackingContainers[key] = container
	end
	container:ClearAllPoints()
	container:SetAllPoints(anchorFrame or frame)
	container:SetFrameStrata(GetSafeStrata(anchorFrame or frame, "LOW"))
	container:SetFrameLevel((anchorFrame and anchorFrame:GetFrameLevel()) or frame:GetFrameLevel())
	region:SetParent(container)
	SyncContainerVisibility(container, anchorFrame)
	return container
end

local stackingComponentDefinitions = {
	healthBar = {
		label = L["Health Bar"],
		get = function(frame)
			return frame and frame.healthBar
		end,
	},
	healthText = {
		label = L["Health Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "healthText", frame and frame.healthBar and frame.healthBar.healthText, frame and frame.healthBar)
		end,
	},
	castBar = {
		label = L["Cast Bar"],
		get = function(frame)
			return frame and frame.castBar
		end,
	},
	castSpellIcon = {
		label = L["Spell Icon"],
		get = function(frame)
			return frame and frame.castBar and frame.castBar.icon
		end,
	},
	castSpellNameText = {
		label = L["Spell Name Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "castSpellNameText", frame and frame.castBar and frame.castBar.spellNameText, frame and frame.castBar)
		end,
	},
	castSpellTimeText = {
		label = L["Spell Time Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "castSpellTimeText", frame and frame.castBar and frame.castBar.spellTimeText, frame and frame.castBar)
		end,
	},
	nameText = {
		label = L["Name Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "nameText", frame and frame.nameText, frame and frame.healthBar)
		end,
	},
	levelText = {
		label = L["Level Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "levelText", frame and frame.levelText, frame and frame.healthBar)
		end,
	},
	targetOverlay = {
		label = L["Target Overlay"],
		get = function(frame)
			return EnsureRegionContainer(frame, "targetOverlay", frame and frame.targetOverlay, frame and frame.healthBar)
		end,
	},
	bossIcon = {
		label = L["Boss Icon"],
		get = function(frame)
			return EnsureRegionContainer(frame, "bossIcon", frame and frame.bossIcon, frame and frame.healthBar)
		end,
	},
	raidIcon = {
		label = L["Raid Icon"],
		get = function(frame)
			return EnsureRegionContainer(frame, "raidIcon", frame and frame.raidIcon, frame and frame.healthBar)
		end,
	},
	threatPercentBar = {
		label = L["Threat Percent Bar"],
		get = function(frame)
			return frame and frame.healthBar and frame.healthBar.threatPercentBar
		end,
	},
	threatPercentText = {
		label = L["Threat Percent Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "threatPercentText", frame and frame.healthBar and frame.healthBar.threatPercentText, frame and frame.healthBar)
		end,
	},
	threatDifferentialText = {
		label = L["Threat Differential Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "threatDifferentialText", frame and frame.healthBar and frame.healthBar.threatDifferentialText, frame and frame.healthBar)
		end,
	},
	threatNumberText = {
		label = L["Threat Number Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "threatNumberText", frame and frame.healthBar and frame.healthBar.threatNumberText, frame and frame.healthBar)
		end,
	},
	targetTargetText = {
		label = L["Target-Target Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "targetTargetText", frame and frame.targetTargetText, frame and frame.healthBar)
		end,
	},
	rangeStatusBar = {
		label = L["Range Status Bar"],
		get = function(frame)
			return frame and frame.rangeBar
		end,
	},
	rangeText = {
		label = L["Range Text"],
		get = function(frame)
			return EnsureRegionContainer(frame, "rangeText", frame and frame.rangeText, frame and frame.healthBar)
		end,
	},
	aurasDebuffs = {
		label = L["Aura Frame 1"],
		get = function(frame)
			if frame and frame.npAuras and frame.npAuras.frames then
				return frame.npAuras.frames[1]
			end
		end,
	},
	aurasBuffs = {
		label = L["Aura Frame 2 (Buffs)"],
		get = function(frame)
			if frame and frame.npAuras and frame.npAuras.frames then
				return frame.npAuras.frames[2]
			end
		end,
	},
}

function NotPlater:EnsureStackingComponentOrder()
	local defaults = self.defaultStackingComponents or DEFAULT_COMPONENT_ORDER
	local stacking = self.db.profile.stacking
	local components = stacking.componentOrdering.components
	if type(components) ~= "table" then
		self.db.profile.stacking.componentOrdering.components = CopyTable(defaults)
		return
	end
	local cleaned, seen = {}, {}
	for _, key in ipairs(components) do
		if stackingComponentDefinitions[key] and not seen[key] then
			tinsert(cleaned, key)
			seen[key] = true
		end
	end
	for _, key in ipairs(defaults) do
		if stackingComponentDefinitions[key] and not seen[key] then
			tinsert(cleaned, key)
			seen[key] = true
		end
	end
	self.db.profile.stacking.componentOrdering.components = cleaned
end

function NotPlater:GetStackingComponentLabel(key)
	local definition = stackingComponentDefinitions[key]
	if definition and definition.label then
		return definition.label
	end
	return key
end

function NotPlater:GetStackingSelectorValues()
	self:EnsureStackingComponentOrder()
	local values = {}
	local components = self.db.profile.stacking.componentOrdering.components or {}
	for index, key in ipairs(components) do
		values[index] = format("%d. %s", index, self:GetStackingComponentLabel(key))
	end
	return values
end

function NotPlater:GetStackingComponentByIndex(index)
	self:EnsureStackingComponentOrder()
	local components = self.db.profile.stacking.componentOrdering.components
	if components then
		return components[index]
	end
end

function NotPlater:GetStackingSelectedComponent()
	self:EnsureStackingComponentOrder()
	local components = self.db.profile.stacking.componentOrdering.components or {}
	if not self.stackingSelectedComponent and components[1] then
		self.stackingSelectedComponent = components[1]
	end
	for _, key in ipairs(components) do
		if key == self.stackingSelectedComponent then
			return self.stackingSelectedComponent
		end
	end
	self.stackingSelectedComponent = nil
	return nil
end

function NotPlater:GetStackingSelectedIndex()
	local selected = self:GetStackingSelectedComponent()
	if not selected then
		return nil
	end
	for index, key in ipairs(self.db.profile.stacking.componentOrdering.components or {}) do
		if key == selected then
			return index
		end
	end
	return nil
end

function NotPlater:SetStackingSelectedComponentByIndex(index)
	index = tonumber(index)
	if not index then
		self.stackingSelectedComponent = nil
		return
	end
	self:EnsureStackingComponentOrder()
	local key = self:GetStackingComponentByIndex(index)
	if key then
		self.stackingSelectedComponent = key
	else
		self.stackingSelectedComponent = nil
	end
end

function NotPlater:ShiftStackingComponent(direction)
	if not direction or direction == 0 then
		return
	end
	self:EnsureStackingComponentOrder()
	local selected = self:GetStackingSelectedComponent()
	if not selected then
		return
	end
	local components = self.db.profile.stacking.componentOrdering.components
	local currentIndex
	for index, key in ipairs(components) do
		if key == selected then
			currentIndex = index
			break
		end
	end
	if not currentIndex then
		return
	end
	local newIndex = currentIndex + direction
	if newIndex < 1 or newIndex > #components then
		return
	end
	components[currentIndex], components[newIndex] = components[newIndex], components[currentIndex]
	self.stackingSelectedComponent = components[newIndex]
	self:ApplyStackingOrderAll()
	if AceConfigRegistry then
		AceConfigRegistry:NotifyChange("NotPlater-Stacking")
	end
end

function NotPlater:ResetStackingOrder()
	local defaults = self.defaultStackingComponents or DEFAULT_COMPONENT_ORDER
	self.db.profile.stacking.componentOrdering.components = CopyTable(defaults)
	self.stackingSelectedComponent = nil
	self:ApplyStackingOrderAll()
	if AceConfigRegistry then
		AceConfigRegistry:NotifyChange("NotPlater-Stacking")
	end
end

function NotPlater:GetStackingComponentFrame(frame, key)
	local definition = stackingComponentDefinitions[key]
	if not definition then
		return nil
	end
	return definition.get(frame)
end

function NotPlater:ApplyStackingOrder(frame)
	if not frame or not frame.healthBar then
		return
	end
	if UnitAffectingCombat("player") then
		return
	end
	self:EnsureStackingComponentOrder()
	local frameStrata = GetSafeStrata(frame, "LOW")
	local baseLevel = frame:GetFrameLevel()
	local step = 5
	local currentStep = 0
	for _, key in ipairs(self.db.profile.stacking.componentOrdering.components or {}) do
		local componentFrame = self:GetStackingComponentFrame(frame, key)
		if componentFrame and componentFrame.SetFrameLevel then
			currentStep = currentStep + 1
			componentFrame:SetFrameStrata(frameStrata)
			componentFrame:SetFrameLevel(baseLevel + currentStep * step)
		end
	end
end

function NotPlater:ApplyStackingOrderAll()
	if UnitAffectingCombat("player") then
		return
	end
	if self.frames then
		for frame in pairs(self.frames) do
			self:ApplyStackingOrder(frame)
		end
	end
	if self.simulatorFrame and self.simulatorFrame.defaultFrame then
		self:ApplyStackingOrder(self.simulatorFrame.defaultFrame)
	end
end

function NotPlater:SetTargetFrameStrata(frame)
	local stackingConfig = self:GetStackingSettings()
	if UnitAffectingCombat("player") then
		return
	end
	if stackingConfig.general.enable then
		if frame:GetFrameStrata() ~= stackingConfig.frameStrata.targetFrame then
			frame:SetFrameStrata(stackingConfig.frameStrata.targetFrame)
		end
	end
	self:ApplyStackingOrder(frame)
end

function NotPlater:SetNormalFrameStrata(frame)
	local stackingConfig = self:GetStackingSettings()
	if UnitAffectingCombat("player") then
		return
	end
	if stackingConfig.general.enable then
		if frame:GetFrameStrata() ~= stackingConfig.frameStrata.normalFrame then
			frame:SetFrameStrata(stackingConfig.frameStrata.normalFrame)
		end
	end
	self:ApplyStackingOrder(frame)
end

function NotPlater:ConfigureStacking(frame)
	self:StackingCheck(frame)
end

function NotPlater:StackingCheck(frame)
	local stackingConfig = self:GetStackingSettings()
	local healthBarConfig = self.db.profile.healthBar.statusBar
	local castBarConfig = self.db.profile.castBar.statusBar
	if stackingConfig.general.enable and not UnitAffectingCombat("player") then
		-- Set the clickable frame size
		if stackingConfig.general.overlappingCastbars then
			self:SetSize(frame, healthBarConfig.size.width + stackingConfig.margin.xStacking * 2, healthBarConfig.size.height + stackingConfig.margin.yStacking * 2)
		else
			self:SetSize(frame, healthBarConfig.size.width + stackingConfig.margin.xStacking * 2, healthBarConfig.size.height + castBarConfig.size.height + stackingConfig.margin.yStacking * 2)
		end
	end
	self:ApplyStackingOrder(frame)
end
