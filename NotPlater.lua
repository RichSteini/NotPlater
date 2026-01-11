local addonName = ...
local GetBuildInfo = GetBuildInfo
local CLIENT_INTERFACE = GetBuildInfo and select(4, GetBuildInfo()) or 0
local IS_WRATH_CLIENT = CLIENT_INTERFACE >= 30000
NotPlater = LibStub("AceAddon-3.0"):NewAddon("NotPlater", "AceEvent-3.0", "AceHook-3.0")
NotPlater.clientInterface = CLIENT_INTERFACE
NotPlater.isWrathClient = IS_WRATH_CLIENT
NotPlater.revision = "v3.2.2"
NotPlater.addonName = addonName or NotPlater.addonName or "NotPlater-2.4.3"

local UnitName = UnitName
local UnitGUID = UnitGUID
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local UnitIsPlayer = UnitIsPlayer
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local unpack = unpack
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetCVar = GetCVar
local SetCVar = SetCVar
local MouseIsOver = MouseIsOver

local NAMEPLATE_CASTBAR_CVAR = "ShowVKeyCastbar"
local NAMEPLATE_CLASS_COLOR_CVAR = "ShowClassColorInNameplate"

local WRATH_NAMEPLATE_TEXTURE = "Interface\\TargetingFrame\\UI-TargetingFrame-Flash"
local LEGACY_NAMEPLATE_TEXTURE = "Interface\\Tooltips\\Nameplate-Border"

local frames = {}
local classCache = {}
local classTokenCache = {}
local factionCache = {}
NotPlater.classCache = classCache
NotPlater.classTokenCache = classTokenCache
NotPlater.factionCache = factionCache
NotPlater.frames = frames

local function GetOrderedFrameRegions(frame)
	if IS_WRATH_CLIENT then
		return frame:GetRegions()
	end
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetRegions()
	return nil, healthBorder, castBorder, nil, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon
end

local function IsFrameMouseOver(frame)
	if not frame then
		return false
	end
	if frame.IsMouseOver then
		return frame:IsMouseOver()
	end
	if MouseIsOver then
		return MouseIsOver(frame)
	end
	return false
end

function NotPlater:GetFrameTexts(frame)
	local nameText = frame.defaultNameText or frame.nameText
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

function NotPlater:UpdateMouseoverNameText(frame, isMouseover)
	local mouseoverConfig = self.db.profile.target and self.db.profile.target.mouseoverHighlight
	local nameConfig = mouseoverConfig and mouseoverConfig.nameText
	if not nameConfig or not nameConfig.enable then
		isMouseover = false
	end
	local nameText = frame.nameText
	if isMouseover then
		if not nameText.npMouseoverColor then
			local r, g, b, a = nameText:GetTextColor()
			nameText.npMouseoverColor = {r, g, b, a}
		end
		nameText:SetTextColor(self:GetColor(nameConfig.color))
	else
		if nameText.npMouseoverColor then
			nameText:SetTextColor(unpack(nameText.npMouseoverColor))
			nameText.npMouseoverColor = nil
		end
	end
end

local function CreateNameTextProxy(frame, defaultNameText)
	if not frame or not defaultNameText then
		return defaultNameText
	end
	if frame.npNameTextProxy then
		return frame.npNameTextProxy
	end
	local proxy = frame:CreateFontString(nil, "ARTWORK")
	local config = NotPlater and NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.nameText
	if config then
		NotPlater:SetupFontString(proxy, config)
	else
		local fallbackFont, fallbackSize, fallbackFlags = defaultNameText:GetFont()
		if not fallbackFont and GameFontNormal and GameFontNormal.GetFont then
			fallbackFont, fallbackSize, fallbackFlags = GameFontNormal:GetFont()
		end
		if fallbackFont then
			proxy:SetFont(fallbackFont, fallbackSize, fallbackFlags)
		end
	end

	local function SetProxyTextFromDefault(text)
		if not proxy then
			return
		end
		proxy.npOriginalText = text or ""
		local activeConfig = NotPlater and NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.nameText
		if activeConfig and activeConfig.general and activeConfig.general.maxLetters then
			NotPlater:SetMaxLetterText(proxy, text, activeConfig)
		else
			proxy:SetText(text)
		end
	end

	SetProxyTextFromDefault(defaultNameText:GetText())
	defaultNameText:SetAlpha(0)
	defaultNameText:Hide()
	hooksecurefunc(defaultNameText, "Show", function(text)
		text:SetAlpha(0)
		text:Hide()
	end)
	hooksecurefunc(defaultNameText, "SetText", function(_, text)
		SetProxyTextFromDefault(text)
	end)

	frame.npNameTextProxy = proxy
	return proxy
end

NotPlater.frame = CreateFrame("Frame")

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

function NotPlater:UpdateNameplateClassColorCVar()
	if not GetCVar or not SetCVar or not self.isWrathClient then
		return
	end
	local shouldEnable = self.db.profile.healthBar.statusBar.general.useClassColors or self.db.profile.nameText.general.useClassColor
	if shouldEnable then
		local current = GetCVar(NAMEPLATE_CLASS_COLOR_CVAR)
		if current ~= "1" then
			SetCVar(NAMEPLATE_CLASS_COLOR_CVAR, "1")
		end
	end
end

function NotPlater:OnInitialize()
	self:LoadDefaultConfig()

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("NotPlaterDB", self.defaults)
	if self.db and self.db.RegisterCallback then
		self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileUpdated")
		self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileUpdated")
		self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
	end
	self:SetTrackedMatchUnits()
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
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UNIT_TARGET")
	self:Reload()
end

function NotPlater:IsTarget(frame)
	if frame and frame.isTemplatePreview then
		if frame.simulatedTarget ~= nil then
			return frame.simulatedTarget
		end
		return false
	end
    local targetExists = UnitExists('target')
    if not targetExists then
        return false
    end

	local nameText = frame and frame.defaultNameText or select(1, self:GetFrameTexts(frame))
	local targetName = UnitName('target')

	return nameText and targetName == nameText:GetText() and frame:GetAlpha() >= 0.99
end

function NotPlater:PrepareFrame(frame)
	local threatGlow, healthBorder, castBorder, castNoStop, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon, eliteIcon = GetOrderedFrameRegions(frame)
	local health, cast = frame:GetChildren()

	-- Hooks and creation (only once that way settings can be applied while frame is visible)
	if not frame.npHooked then
		frame.npHooked = true

		local resolvedNameText, resolvedLevelText = self:GetFrameTexts(frame)
		frame.defaultNameText = resolvedNameText or nameText
		frame.defaultHealthBar = health
		frame.levelText = resolvedLevelText or levelText
		frame.bossIcon = bossIcon or frame.bossIcon
		frame.raidIcon = raidIcon or frame.raidIcon
		frame.eliteIcon = eliteIcon or frame.eliteIcon
		frame.nameText = CreateNameTextProxy(frame, frame.defaultNameText)
		if not frame.highlightTexture or frame.highlightTexture == highlightTexture then
			frame.highlightTexture = frame:CreateTexture(nil, "ARTWORK")
		end

		-- Hide default border
		if healthBorder then healthBorder:Hide() end
		if threatGlow then threatGlow:SetTexCoord(0, 0, 0, 0) end
		if castNoStop then castNoStop:SetTexCoord(0, 0, 0, 0) end
		if highlightTexture then
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
		self:ConstructRange(frame)
		self:ConstructEliteIcon(frame)
		self:ConstructClassIcon(frame)
		self:ConstructFactionIcon(frame)
		self:ConstructNpcIcons(frame)
		self.Auras:AttachToFrame(frame)

		-- Hide old healthbar
		health:Hide()
    
		if not frame.isTemplatePreview then
			self:HookScript(frame, "OnShow", function(self)
				local unitName = self.defaultNameText:GetText()
				local cachedClass = classCache[unitName]
				self.unitClass = cachedClass
				self.unitClassToken = classTokenCache[unitName]
				NotPlater:FactionCheck(self)
				self.unitFaction = factionCache[unitName]
				NotPlater:CastBarOnShow(self)
				NotPlater:HealthBarOnShow(health)
				NotPlater:StackingCheck(self)
				NotPlater:ThreatComponentsOnShow(self)
				NotPlater:RangeComponentsOnShow(self)
				NotPlater:TargetCheck(self)
				NotPlater:NameTextOnShow(self)
				NotPlater:MatchTrackerOnShow(self)
				NotPlater.Auras:OnPlateShow(self)
				NotPlater:UpdateClassIcon(self)
				NotPlater:UpdateEliteIcon(self)
				NotPlater:UpdateFactionIcon(self)
				NotPlater:UpdateNpcIcons(self)
				NotPlater:ApplyFilters(self)
				self.targetChanged = true
			end)

			self:HookScript(frame, 'OnUpdate', function(self, elapsed)
				if not self.targetCheckElapsed then self.targetCheckElapsed = 0 end
				self.targetCheckElapsed = self.targetCheckElapsed + elapsed
				if self.targetCheckElapsed >= 0.1 then
					if self.targetChanged then
						NotPlater:TargetCheck(self)
						self.targetChanged = nil
					end
					if NotPlater.db.profile.healthBar.statusBar.general.useClassColors then
						if not self.unitClass then
							NotPlater:ClassCheck(self)
						end
						if self.unitClass then
							self.healthBar:SetStatusBarColor(self.unitClass.r, self.unitClass.g, self.unitClass.b, 1)
						end
					end
					if not self.unitClass then
						NotPlater:ClassCheck(self)
					end
					if not self.unitFaction then
						NotPlater:FactionCheck(self)
					end
					local nameTextConfig = NotPlater:GetActiveNameTextConfig(self)
					if nameTextConfig.general.useClassColor and not self.filterHideNameText then
						if self.unitClass then
							self.nameText:SetTextColor(self.unitClass.r, self.unitClass.g, self.unitClass.b, 1)
						end
					end
					if NotPlater.db.profile.icons.classIcon.general.enable then
						if not self.unitClass then
							NotPlater:ClassCheck(self)
						end
						NotPlater:UpdateClassIcon(self)
					end
					if NotPlater.db.profile.icons.factionIcon.general.enable then
						NotPlater:UpdateFactionIcon(self)
					end
					NotPlater:SetTargetTargetText(self)
					NotPlater:RangeCheck(self, self.targetCheckElapsed)
					NotPlater:ApplyFilters(self)
					self.targetCheckElapsed = 0
				end
				local isMouseOver = IsFrameMouseOver(self)
				if self.useHighlightProxy and self.highlightTexture then
					if isMouseOver then
						if not self.highlightTexture:IsShown() then
							self.highlightTexture:Show()
						end
					else
						if self.highlightTexture:IsShown() then
							self.highlightTexture:Hide()
						end
					end
				end
				NotPlater:UpdateMouseoverNameText(self, isMouseOver)
				local mouseoverConfig = NotPlater.db.profile.target.mouseoverHighlight
				if mouseoverConfig.enable and mouseoverConfig.border and mouseoverConfig.border.enable and isMouseOver then
					self.mouseoverBorder:Show()
				else
					self.mouseoverBorder:Hide()
				end
				if NotPlater:IsTarget(self) then
					self:SetAlpha(1)
				else
					if NotPlater.db.profile.target.nonTargetAlpha.enable then
						self:SetAlpha(NotPlater.db.profile.target.nonTargetAlpha.opacity)
					end
				end
				if NotPlater.db.profile.levelText.general.enable then
					NotPlater:LevelTextOnShow(levelText, self.healthBar)
					levelText:Show()
				else
					levelText:Hide()
				end
			end)
			self:HookScript(frame, "OnHide", function(self)
				NotPlater:MatchTrackerOnHide(self)
				NotPlater.Auras:OnPlateHide(self)
				self.unitClass = nil
				self.unitClassToken = nil
				self.unitFaction = nil
				self.highlightTexture:Hide()
			end)
		end
	end
	
	-- Configure everything
	self:ConfigureThreatComponents(frame)
	self:ConfigureHealthBar(frame, health)
	self:ConfigureCastBar(frame)
	self:ConfigureStacking(frame)
	self:ConfigureGeneralisedIcon(frame.bossIcon, frame.healthBar, self.db.profile.icons.bossIcon)
	self:ConfigureGeneralisedIcon(frame.raidIcon, frame.healthBar, self.db.profile.icons.raidIcon)
	self:ConfigureEliteIcon(frame)
	self:ConfigureClassIcon(frame)
	self:ConfigureFactionIcon(frame)
	self:ConfigureNpcIcons(frame)
	self:ConfigureLevelText(frame.levelText, frame.healthBar)
	self:ConfigureNameText(frame.nameText, frame.healthBar)
	self:ConfigureTarget(frame)
	self:ConfigureRange(frame)
	self:ApplyStackingOrder(frame)
	self:TargetCheck(frame)
	self:ApplyFilters(frame)
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
	self:UpdateNameplateClassColorCVar()

	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	for frame in pairs(frames) do
		self:PrepareFrame(frame)
	end

	self.Auras:ApplyProfile()
end

function NotPlater:OnProfileUpdated()
	self:Reload()
	if self.simulatorFrame and self.simulatorFrame:IsShown() then
		self:SimulatorReload()
	end
end

function NotPlater:OnProfileReset()
	if self.db and self.db.profile then
		self.db.profile.filters = { list = {} }
	end
	local config = self:GetModule("Config", true)
	if config and config.RefreshFilterOptions then
		config:RefreshFilterOptions()
	end
	self:OnProfileUpdated()
end

function NotPlater:OnDisable()
	self:RestoreDefaultNameplateCastBar()
end

local numChildren = -1
NotPlater.frame:SetScript("OnUpdate", function(self, elapsed)
	if(WorldFrame:GetNumChildren() ~= numChildren) then
		numChildren = WorldFrame:GetNumChildren()
		NotPlater:HookFrames(WorldFrame:GetChildren())
	end
end)

