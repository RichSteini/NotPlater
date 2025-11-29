local addonName = ...
local GetBuildInfo = GetBuildInfo
local CLIENT_INTERFACE = GetBuildInfo and select(4, GetBuildInfo()) or 0
local IS_WRATH_CLIENT = CLIENT_INTERFACE >= 30000
NotPlater = LibStub("AceAddon-3.0"):NewAddon("NotPlater", "AceEvent-3.0", "AceHook-3.0")
NotPlater.clientInterface = CLIENT_INTERFACE
NotPlater.isWrathClient = IS_WRATH_CLIENT
NotPlater.revision = "v3.0.0"
NotPlater.addonName = addonName or NotPlater.addonName or "NotPlater-2.4.3"

local UnitName = UnitName
local UnitLevel = UnitLevel
local UnitHealth = UnitHealth
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetCVar = GetCVar
local SetCVar = SetCVar

local NAMEPLATE_CASTBAR_CVAR = "ShowVKeyCastbar"
local WRATH_NAMEPLATE_TEXTURE = "Interface\\TargetingFrame\\UI-TargetingFrame-Flash"
local LEGACY_NAMEPLATE_TEXTURE = "Interface\\Tooltips\\Nameplate-Border"

local frames = {}
local DEFAULT_TRACKED_UNITS = {"target", "focus", "mouseover"}
local MAX_ARENA_UNIT_IDS = type(MAX_ARENA_ENEMIES) == "number" and MAX_ARENA_ENEMIES or 5

local function SetFrameClassColorFromUnit(frame, unit)
	if not frame or not unit or not UnitExists(unit) then
		return false
	end
	local classToken = select(2, UnitClass(unit))
	if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
		frame.unitClass = RAID_CLASS_COLORS[classToken]
		return true
	end
	return false
end

local function ShouldUseArenaUnits()
	if type(IsActiveBattlefieldArena) == "function" and IsActiveBattlefieldArena() then
		return true
	end
	if type(GetNumArenaOpponents) == "function" then
		local opponentCount = GetNumArenaOpponents()
		if opponentCount and opponentCount > 0 then
			return true
		end
	end
	return false
end

local function GetOrderedFrameRegions(frame)
	if IS_WRATH_CLIENT then
		return frame:GetRegions()
	end
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetRegions()
	return nil, healthBorder, castBorder, nil, spellIcon, highlightTexture, nameText, levelText, nil, raidIcon, bossIcon
end

local function GetFrameTexts(frame)
	local nameText = frame.nameText
	local levelText = frame.levelText
	if not nameText or not levelText then
		local regions = {GetOrderedFrameRegions(frame)}
		if not nameText then
			nameText = regions[7]
		end
		if not levelText then
			levelText = regions[8]
		end
	end
	return nameText, levelText
end

NotPlater.frame = CreateFrame("Frame")

function NotPlater:SetTrackedMatchUnits(units)
	self.trackedMatchUnits = {}
	if type(units) == "table" then
		for index = 1, #units do
			self.trackedMatchUnits[#self.trackedMatchUnits + 1] = units[index]
		end
	end
	if #self.trackedMatchUnits == 0 then
		for index = 1, #DEFAULT_TRACKED_UNITS do
			self.trackedMatchUnits[index] = DEFAULT_TRACKED_UNITS[index]
		end
	end
end

function NotPlater:GetTrackedMatchUnits()
	if not self.trackedMatchUnits or #self.trackedMatchUnits == 0 then
		self:SetTrackedMatchUnits(DEFAULT_TRACKED_UNITS)
	end
	return self.trackedMatchUnits
end

function NotPlater:DisableDefaultNameplateCastBar()
	if not GetCVar or not SetCVar then
		return
	end
	local current = GetCVar(NAMEPLATE_CASTBAR_CVAR)
	if not self._originalNameplateCastBarCVar then
		self._originalNameplateCastBarCVar = current
	end
	if current ~= "0" then
		SetCVar(NAMEPLATE_CASTBAR_CVAR, "0")
	end
end

function NotPlater:RestoreDefaultNameplateCastBar()
	if not GetCVar or not SetCVar then
		return
	end
	if self._originalNameplateCastBarCVar then
		SetCVar(NAMEPLATE_CASTBAR_CVAR, self._originalNameplateCastBarCVar)
		self._originalNameplateCastBarCVar = nil
	end
end

function NotPlater:UpdateNameplateCastBarCVar()
	if not GetCVar or not SetCVar then
		return
	end
	if self.db and self.db.profile and self.db.profile.castBar and self.db.profile.castBar.statusBar.general.enable then
		self:DisableDefaultNameplateCastBar()
	else
		self:RestoreDefaultNameplateCastBar()
	end
end

function NotPlater:GetAuraModule()
	return self.Auras
end

function NotPlater:OnInitialize()
	self:LoadDefaultConfig()

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("NotPlaterDB", self.defaults)
	if self.db and self.db.RegisterCallback then
		self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdated")
		self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdated")
		self.db.RegisterCallback(self, "OnProfileReset", "OnProfileUpdated")
	end
	self:SetTrackedMatchUnits(DEFAULT_TRACKED_UNITS)
	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	
	if self.Auras then
		if self.Auras.Init then
			self.Auras:Init()
		end
		if self.Auras.Enable then
			self.Auras:Enable()
		end
	end

	self:PARTY_MEMBERS_CHANGED()
	self:RAID_ROSTER_UPDATE()
	
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:Reload()
end

function NotPlater:IsTarget(frame)
    local targetExists = UnitExists('target')
    if not targetExists then
        return false
    end

	local nameText = GetFrameTexts(frame)
	local targetName = UnitName('target')

	return nameText and targetName == nameText:GetText() and frame:GetAlpha() >= 0.99
end

function NotPlater:PlateMatchesUnit(frame, unit)
	if not unit or not UnitExists(unit) then
		return false
	end
	if not frame or not frame.healthBar then
		return false
	end
	if not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
		return false
	end
	local nameText, levelText = GetFrameTexts(frame)
	if not nameText then
		return false
	end
	local plateName = nameText:GetText()
	if not plateName or plateName ~= UnitName(unit) then
		return false
	end
	if levelText then
		local plateLevel = levelText:GetText()
		if plateLevel then
			local unitLevel = UnitLevel(unit)
			local levelString = unitLevel and tostring(unitLevel) or plateLevel
			if plateLevel ~= levelString then
				return false
			end
		end
	end
	local healthBar = frame.healthBar
	if healthBar then
		local healthValue = healthBar:GetValue()
		if healthValue ~= UnitHealth(unit) then
			return false
		end
	end
	return true
end

function NotPlater:SetFrameMatch(frame, unit)
	local healthFrame = frame.healthBar
	if not healthFrame then
		return
	end
	local guid = unit and UnitGUID(unit) or nil
	frame.lastUnitMatch = unit
	healthFrame.lastUnitMatch = unit
	frame.lastGuidMatch = guid
	healthFrame.lastGuidMatch = guid
end

function NotPlater:MatchGroupTargetUnit(frame)
	local group = self.raid or self.party
	if not group then
		return false
	end
	for _, unitID in pairs(group) do
		local targetString = unitID .. "-target"
		if self:PlateMatchesUnit(frame, targetString) then
			SetFrameClassColorFromUnit(frame, targetString)
			return true
		end
	end
	return false
end

function NotPlater:UpdateFrameMatch(frame)
	if not frame or not frame:IsShown() or not frame.healthBar then
		return
	end
	local match
	for _, unit in ipairs(self:GetTrackedMatchUnits()) do
		if self:PlateMatchesUnit(frame, unit) then
			match = unit
			break
		end
	end
	if not match then
		local group = self.raid or self.party
		if group then
			for _, unitID in pairs(group) do
				local targetString = unitID .. "-target"
				if self:PlateMatchesUnit(frame, targetString) then
					match = targetString
					break
				end
			end
		end
	end
	self:SetFrameMatch(frame, match)
end

function NotPlater:PrepareFrame(frame)
	local threatGlow, healthBorder, castBorder, castNoStop, spellIcon, highlightTexture, nameText, levelText, dangerSkull, raidIcon, bossIcon = GetOrderedFrameRegions(frame)
	local health, cast = frame:GetChildren()

	-- Hooks and creation (only once that way settings can be applied while frame is visible)
	if not frame.npHooked then
		frame.npHooked = true

		local resolvedNameText, resolvedLevelText = GetFrameTexts(frame)
		frame.nameText = resolvedNameText or nameText
		frame.levelText = resolvedLevelText or levelText
		frame.bossIcon = bossIcon or frame.bossIcon
		frame.raidIcon = raidIcon or frame.raidIcon
		if NotPlater.isWrathClient then
			if not frame.highlightTexture or frame.highlightTexture == highlightTexture then
				frame.highlightTexture = frame:CreateTexture(nil, "ARTWORK")
			end
		else
			frame.highlightTexture = highlightTexture or frame.highlightTexture or frame:CreateTexture(nil, "ARTWORK")
		end

		-- Hide default border
		if healthBorder then healthBorder:Hide() end
		if threatGlow then threatGlow:SetTexCoord(0, 0, 0, 0) end
		if castNoStop then castNoStop:SetTexCoord(0, 0, 0, 0) end
		if dangerSkull then dangerSkull:SetTexCoord(0, 0, 0, 0) end
		if highlightTexture and NotPlater.isWrathClient then
			frame.defaultHighlightTexture = highlightTexture
			highlightTexture:SetTexCoord(0, 0, 0, 0)
			frame.useHighlightProxy = not frame.isSimulatorFrame
			frame.highlightTexture:Hide()
		end


		-- Construct everything
		self:ConstructHealthBar(frame, health)
		self:ConstructThreatComponents(frame.healthBar)
		self:ConstructCastBar(frame)
		self:ConstructTarget(frame)
		local auraModule = self:GetAuraModule()
		if auraModule and auraModule.AttachToFrame then
			auraModule:AttachToFrame(frame)
		end

		-- Hide old healthbar
		health:Hide()
    
		self:HookScript(frame, "OnShow", function(self)
			self.unitClass = nil
			NotPlater:CastBarOnShow(self)
			NotPlater:HealthBarOnShow(health)
			NotPlater:StackingCheck(self)
			NotPlater:ThreatComponentsOnShow(self)
			NotPlater:TargetCheck(self)
			self.targetChanged = true
			NotPlater:UpdateFrameMatch(self)
		end)

		self:HookScript(frame, 'OnUpdate', function(self, elapsed)
			if not self.targetCheckElapsed then self.targetCheckElapsed = 0 end
			self.targetCheckElapsed = self.targetCheckElapsed + elapsed
			if self.targetCheckElapsed >= 0.1 then
				if self.targetChanged then
					NotPlater:TargetCheck(self)
					self.targetChanged = nil
				end
				if NotPlater.db.profile.threat.nameplateColors.general.useClassColors then
					if not self.unitClass then
						NotPlater:ClassCheck(self)
					end
					if self.unitClass then
						frame.healthBar:SetStatusBarColor(self.unitClass.r, self.unitClass.g, self.unitClass.b, 1)
					end
				end
				NotPlater:SetTargetTargetText(self)
				NotPlater:UpdateFrameMatch(self)
				self.targetCheckElapsed = 0
			end
			if NotPlater.isWrathClient and self.useHighlightProxy and self.defaultHighlightTexture and self.highlightTexture then
				if self.defaultHighlightTexture:IsShown() then
					if not self.highlightTexture:IsShown() then
						self.highlightTexture:Show()
					end
				else
					if self.highlightTexture:IsShown() then
						self.highlightTexture:Hide()
					end
				end
			end
			if NotPlater:IsTarget(self) then
				self:SetAlpha(1)
			else
				if NotPlater.db.profile.target.general.nonTargetAlpha.enable then
					self:SetAlpha(NotPlater.db.profile.target.general.nonTargetAlpha.opacity)
				end
			end
			if NotPlater.db.profile.levelText.general.enable then
				NotPlater:LevelTextOnShow(levelText, self.healthBar)
				levelText:Show()
			else
				levelText:Hide()
			end
			if NotPlater.db.profile.nameText.general.enable then
				NotPlater:NameTextOnShow(nameText)
			end
		end)
	end
	
	-- Configure everything
	self:ConfigureThreatComponents(frame)
	self:ConfigureHealthBar(frame, health)
	self:ConfigureCastBar(frame)
	self:ConfigureStacking(frame)
		self:ConfigureGeneralisedIcon(frame.bossIcon, frame.healthBar, self.db.profile.bossIcon)
		self:ConfigureGeneralisedIcon(frame.raidIcon, frame.healthBar, self.db.profile.raidIcon)
		self:ConfigureLevelText(frame.levelText, frame.healthBar)
		self:ConfigureNameText(frame.nameText, frame.healthBar)
	self:ConfigureTarget(frame)
		self:ApplyStackingOrder(frame)
	self:UpdateFrameMatch(frame)
	self:TargetCheck(frame)
end

function NotPlater:HookFrames(...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		local region = frame:GetRegions()
		if not frames[frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" then
			local texture = region:GetTexture()
			if texture == WRATH_NAMEPLATE_TEXTURE or texture == LEGACY_NAMEPLATE_TEXTURE then
			frames[frame] = true
			self:PrepareFrame(frame)
			end
		end
	end
end

function NotPlater:Reload()
	if self.db.profile.castBar.statusBar.general.enable then
		self:RegisterCastBarEvents(NotPlater.frame)
	else
		self:UnregisterCastBarEvents(NotPlater.frame)
	end
	self:UpdateNameplateCastBarCVar()

	if self.db.profile.threat.general.enableMouseoverUpdate then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	else
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end

	for frame in pairs(frames) do
		self:PrepareFrame(frame)
	end

	local auraModule = self:GetAuraModule()
	if auraModule and auraModule.ApplyProfile then
		auraModule:ApplyProfile()
	end
end

function NotPlater:OnProfileUpdated()
	self:Reload()
	if self.simulatorFrame and self.simulatorFrame:IsShown() then
		self:SimulatorReload()
	end
end

function NotPlater:PLAYER_TARGET_CHANGED()
	for frame in pairs(frames) do
		frame.targetChanged = true
	end
end

function NotPlater:OnDisable()
	self:RestoreDefaultNameplateCastBar()
end

function NotPlater:ClassCheck(frame)
	if frame.unitClass then return end

	if self:IsTarget(frame) then
		SetFrameClassColorFromUnit(frame, "target")
		return
	end

	if ShouldUseArenaUnits() then
		for index = 1, MAX_ARENA_UNIT_IDS do
			local arenaUnit = "arena" .. index
			if self:PlateMatchesUnit(frame, arenaUnit) then
				SetFrameClassColorFromUnit(frame, arenaUnit)
				return
			end
		end
	end

	if self:MatchGroupTargetUnit(frame) then
		return
	end

	local nameText, levelText = GetFrameTexts(frame)
	if not nameText or not levelText then
		return
	end
	local name = nameText:GetText()
	local level = levelText:GetText()
	--local _, healthMaxValue = frame.healthBar:GetMinMaxValues()
	local healthBar = frame.healthBar
	if not healthBar then
		return
	end
	local healthValue = healthBar:GetValue()
	if name == UnitName("mouseover") and level == tostring(UnitLevel("mouseover")) and healthValue == UnitHealth("mouseover") then
		SetFrameClassColorFromUnit(frame, "mouseover")
		return
	end
	if name == UnitName("focus") and level == tostring(UnitLevel("focus")) and healthValue == UnitHealth("focus") then
		SetFrameClassColorFromUnit(frame, "focus")
	end
end

function NotPlater:UPDATE_MOUSEOVER_UNIT()
	if UnitCanAttack("player", "mouseover") and not UnitIsDeadOrGhost("mouseover") and UnitAffectingCombat("mouseover") then
		local mouseOverGuid = UnitGUID("mouseover")
		local targetGuid = UnitGUID("target")
		for frame in pairs(frames) do
			if frame:IsShown() then
				if mouseOverGuid == targetGuid then
					if self:IsTarget(frame) then
						self:SetFrameMatch(frame, "mouseover")
						self:MouseoverThreatCheck(frame.healthBar, targetGuid)
						frame.highlightTexture:Show()
					end
				else
					local _, healthMaxValue = frame.healthBar:GetMinMaxValues()
					if self:PlateMatchesUnit(frame, "mouseover") and frame.healthBar:GetValue() ~= healthMaxValue then
						self:SetFrameMatch(frame, "mouseover")
						self:MouseoverThreatCheck(frame.healthBar, mouseOverGuid)
					end
				end
			end
		end
	end
end

local numChildren = -1
NotPlater.frame:SetScript("OnUpdate", function(self, elapsed)
	if(WorldFrame:GetNumChildren() ~= numChildren) then
		numChildren = WorldFrame:GetNumChildren()
		NotPlater:HookFrames(WorldFrame:GetChildren())
	end
end)

NotPlater.frame:SetScript("OnEvent", function(self, event, unit)
	for frame in pairs(frames) do
		if frame:IsShown() then
			if unit == "target" then
				if NotPlater:IsTarget(frame) then
					NotPlater:SetFrameMatch(frame, "target")
					NotPlater:CastBarOnCast(frame, event, unit)
				end
			else
				local _, healthMaxValue = frame.healthBar:GetMinMaxValues()
				if NotPlater:PlateMatchesUnit(frame, unit) and frame.healthBar:GetValue() ~= healthMaxValue then
					NotPlater:SetFrameMatch(frame, unit)
					NotPlater:CastBarOnCast(frame, event, unit)
				end
			end
		end
	end
end)
