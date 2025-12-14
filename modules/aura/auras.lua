if not NotPlater then
	return
end

local Auras = {}
NotPlater.Auras = Auras
local AuraTracker = NotPlater.AuraTracker

local DEFAULT_TRACKED_UNITS = {"target", "focus", "mouseover"}
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local EMPTY_TABLE = {}

local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitLevel = UnitLevel
local UnitHealth = UnitHealth
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local UnitIsPlayer = UnitIsPlayer
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GameTooltip = GameTooltip
local DebuffTypeColor = DebuffTypeColor
local GetSpellInfo = GetSpellInfo
local tinsert = table.insert
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local format = string.format
local floor = math.floor
local huge = math.huge
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil

local DEFAULT_COOLDOWN_STYLE = "vertical"

local function SafeUnit(unit)
	return unit and UnitExists(unit) and not UnitIsDeadOrGhost(unit)
end

local function ToGUID(candidate)
	if not candidate then
		return nil
	end
	if candidate:match("^%x%x%x%x%x%x%x%x%-") then
		return candidate
	end
	return UnitGUID(candidate)
end

function Auras:AttachTracker()
	self.tracker = self.tracker or AuraTracker or NotPlater.AuraTracker
	if self.tracker and self.tracker.EnsureInit then
		self.tracker:EnsureInit()
	end
	if self.tracker and self.tracker.RegisterListener and not self.trackerListener then
		self.tracker:RegisterListener(self)
		self.trackerListener = true
	end
end

function Auras:DetachTracker()
	if self.tracker and self.tracker.UnregisterListener and self.trackerListener then
		self.tracker:UnregisterListener(self)
	end
	self.trackerListener = false
end

function Auras:EnsureInit()
	if self.initialized then
		return
	end
	self:AttachTracker()
	self:Init()
end

function Auras:Init()
	if self.initialized then
		return
	end
	self.frames = {}
	self.guidToFrame = {}
	self.unitToFrame = {}
	self.activeIcons = {}
	self.elapsed = 0
	self.playerGUID = UnitGUID("player")
	self.updater = CreateFrame("Frame")
	self.updater:SetScript("OnUpdate", function(_, elapsed)
		self:OnUpdate(elapsed)
	end)
	self.updater:Hide()
	self.eventFrame = CreateFrame("Frame")
	self.eventFrame:SetScript("OnEvent", function(_, event, ...)
		self:HandleEvent(event, ...)
	end)
	self.mouseoverWatcher = CreateFrame("Frame")
	self.mouseoverWatcher:SetScript("OnUpdate", function(_, elapsed)
		self:OnMouseoverUpdate(elapsed)
	end)
	self.mouseoverWatcher:Hide()
	self.mouseoverWatcherActive = false
	self.mouseoverElapsed = 0
	self.initialized = true
end

local function ResolveCooldownProvider(style)
	if style == "richsteini" and NotPlater.AuraCooldownRichSteini then
		return NotPlater.AuraCooldownRichSteini
	end
	if style == "swirl" and NotPlater.AuraCooldownSwirl then
		return NotPlater.AuraCooldownSwirl
	end
	if NotPlater.AuraCooldownVertical then
		return NotPlater.AuraCooldownVertical
	end
	return NotPlater.AuraCooldownSwirl
end

function Auras:GetCooldownProvider()
	local style = (self.swipe and self.swipe.style) or DEFAULT_COOLDOWN_STYLE
	return ResolveCooldownProvider(style)
end

function Auras:EnsureIconCooldownProvider(icon)
	local provider = self:GetCooldownProvider()
	if icon.cooldownProvider ~= provider then
		if icon.cooldownProvider and icon.cooldownProvider.Detach then
			icon.cooldownProvider:Detach(icon)
		end
		if provider and provider.Attach then
			provider:Attach(icon, self, self.swipe)
		end
		icon.cooldownProvider = provider
	end
	return provider
end

function Auras:ResetIconCooldown(icon)
	if icon.cooldownProvider and icon.cooldownProvider.Reset then
		icon.cooldownProvider:Reset(icon)
	end
end

function Auras:UpdateIconCooldown(icon)
	if icon.cooldownProvider and icon.cooldownProvider.Update then
		icon.cooldownProvider:Update(icon, self.swipe, self)
	end
end


function Auras:RegisterEvents()
	if not self.eventFrame then
		return
	end
	self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	self.eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self.eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self.eventFrame:RegisterEvent("UNIT_AURA")
	self.eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
end

function Auras:UnregisterEvents()
	if self.eventFrame then
		self.eventFrame:UnregisterAllEvents()
	end
end

function Auras:HandleEvent(event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		self:OnPlayerEnteringWorld()
	elseif event == "UNIT_AURA" then
		self:UNIT_AURA(...)
	elseif event == "ARENA_OPPONENT_UPDATE" then
		self:OnArenaOpponentUpdate(...)
	else
		self:OnTrackedUnitEvent()
	end
end

function Auras:Enable()
	self:EnsureInit()
	if self.enabled then
		self:ApplyProfile()
		return
	end
	self.enabled = true
	self:AttachTracker()
	if self.tracker and self.tracker.Enable then
		self.tracker:Enable()
	end
	self.playerGUID = UnitGUID("player")
	self:RefreshConfig()
	self:RegisterEvents()
	self.updater:Show()
	self:UpdateAllFrames()
end

function Auras:Disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	self:DetachTracker()
	if self.tracker and self.tracker.Disable then
		self.tracker:Disable()
	end
	self:HideAllFrames()
	self:UnregisterEvents()
	self.updater:Hide()
	if self.mouseoverWatcher then
		self.mouseoverWatcher:Hide()
		self.mouseoverWatcherActive = false
	end
end

function Auras:OnUpdate(elapsed)
	if not self.general or not self.general.enable then
		return
	end
	self.elapsed = self.elapsed + elapsed
	if self.elapsed < 0.05 then
		return
	end
	self.elapsed = 0
	for icon in pairs(self.activeIcons) do
		self:UpdateIconTimer(icon)
		self:UpdateIconCooldown(icon)
	end
end

function Auras:RefreshConfig()
	self:EnsureInit()
	self.db = NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.buffs or {}
	self.general = self.db.general or {}
	self.general.showAnimations = self.general.showAnimations ~= false
	self.db.auraFrame1 = self.db.auraFrame1 or {}
	self.db.auraFrame2 = self.db.auraFrame2 or {}
	local legacyPerRow = self.db.aurasPerRow
	if legacyPerRow then
		if legacyPerRow.frame1 and self.db.auraFrame1.rowCount == nil then
			self.db.auraFrame1.rowCount = legacyPerRow.frame1
		end
		if legacyPerRow.frame2 and self.db.auraFrame2.rowCount == nil then
			self.db.auraFrame2.rowCount = legacyPerRow.frame2
		end
		self.db.aurasPerRow = nil
	end
	local legacySize1 = self.db.auraSize1
	if legacySize1 then
		self.db.auraFrame1.width = self.db.auraFrame1.width or legacySize1.width
		self.db.auraFrame1.height = self.db.auraFrame1.height or legacySize1.height
		self.db.auraFrame1.borderThickness = self.db.auraFrame1.borderThickness or legacySize1.borderThickness
		self.db.auraSize1 = nil
	end
	local legacySize2 = self.db.auraSize2
	if legacySize2 then
		self.db.auraFrame2.width = self.db.auraFrame2.width or legacySize2.width
		self.db.auraFrame2.height = self.db.auraFrame2.height or legacySize2.height
		self.db.auraFrame2.borderThickness = self.db.auraFrame2.borderThickness or legacySize2.borderThickness
		self.db.auraSize2 = nil
	end
	self.auraFrameConfig = {
		[1] = self.db.auraFrame1 or {},
		[2] = self.db.auraFrame2 or {},
	}
	self.stackCounter = self.db.stackCounter or {}
	self.auraTimer = self.db.auraTimer or {}
	self.swipe = self.db.swipeAnimation or {}
	self.borderColors = self.db.borderColors or {}
	self.tracking = self.db.tracking or {}
	self.tracking.mode = self.tracking.mode or "AUTOMATIC"
	self.tracking.automatic = self.tracking.automatic or {}
	self.tracking.lists = self.tracking.lists or {}
	self.swipe.showSwipe = self.swipe.showSwipe ~= false
	self.swipe.invertSwipe = self.swipe.invertSwipe == true
	self.swipe.style = self.swipe.style or DEFAULT_COOLDOWN_STYLE
	if self.tracker and self.tracker.ApplySettings then
		self.tracker:ApplySettings()
	end
	self:UpdateMouseoverWatcher()
	self:RebuildLists()
end

function Auras:RegisterListEntry(target, entry)
	if not target or not entry then
		return
	end
	if entry.spellID and entry.spellID ~= 0 then
		target[entry.spellID] = true
	end
	if entry.name and entry.name ~= "" then
		target[entry.name:lower()] = true
	end
end

function Auras:IsAuraListed(list, aura)
	if not list or not aura then
		return false
	end
	if aura.spellID and list[aura.spellID] then
		return true
	end
	if aura.name and list[aura.name:lower()] then
		return true
	end
	return false
end

function Auras:RebuildLists()
	self.blacklist = {
		buffs = {},
		debuffs = {},
	}
	self.whitelist = {
		buffs = {},
		debuffs = {},
	}
	local lists = self.tracking.lists
	for _, entry in ipairs(lists.blacklistBuffs or EMPTY_TABLE) do
		self:RegisterListEntry(self.blacklist.buffs, entry)
	end
	for _, entry in ipairs(lists.blacklistDebuffs or EMPTY_TABLE) do
		self:RegisterListEntry(self.blacklist.debuffs, entry)
	end
	for _, entry in ipairs(lists.extraBuffs or EMPTY_TABLE) do
		self:RegisterListEntry(self.whitelist.buffs, entry)
	end
	for _, entry in ipairs(lists.extraDebuffs or EMPTY_TABLE) do
		self:RegisterListEntry(self.whitelist.debuffs, entry)
	end
end

function Auras:ApplyProfile()
	self:EnsureInit()
	self:RefreshConfig()
	for frame in pairs(self.frames) do
		if frame.npAuras then
			self:ConfigureFrame(frame)
			self:UpdateFrameAuras(frame)
		end
	end
end

function Auras:AttachToFrame(frame)
	self:EnsureInit()
	if self.frames[frame] then
		return
	end
	self.frames[frame] = true
	frame.npAuras = frame.npAuras or {}
	frame.npAuras.frames = frame.npAuras.frames or {}
	if not frame.npAuras.frames[1] then
		frame.npAuras.frames[1] = self:CreateContainer(frame, 1)
	end
	if not frame.npAuras.frames[2] then
		frame.npAuras.frames[2] = self:CreateContainer(frame, 2)
	end
	frame:HookScript("OnShow", function(f)
		Auras:OnPlateShow(f)
	end)
	frame:HookScript("OnHide", function(f)
		Auras:OnPlateHide(f)
	end)
	self:ConfigureFrame(frame)
end

function Auras:CreateContainer(frame, index)
	local parent = frame.healthBar or frame
	local container = CreateFrame("Frame", nil, parent)
	container.index = index
	container.icons = {}
	local baseLevel = (parent and parent:GetFrameLevel()) or (frame and frame:GetFrameLevel()) or 0
	container:SetFrameLevel(baseLevel + 10 + index)
	local parentStrata = (parent and parent:GetFrameStrata()) or (frame and frame:GetFrameStrata()) or "MEDIUM"
	if parentStrata == "UNKNOWN" or not parentStrata then
		parentStrata = "HIGH"
	end
	container:SetFrameStrata(parentStrata)
	container:Hide()
	return container
end

function Auras:OnPlateShow(frame)
	self:SetFrameGUID(frame, nil)
	self:SetFrameUnit(frame, nil)
	self:UpdateFrameAuras(frame)
end

function Auras:OnPlateHide(frame)
	self:SetFrameGUID(frame, nil)
	self:SetFrameUnit(frame, nil)
	self:HideContainers(frame)
end

function Auras:HideContainers(frame)
	if not frame.npAuras then
		return
	end
	for _, container in ipairs(frame.npAuras.frames) do
		if container then
			self:HideContainer(container)
		end
	end
end

function Auras:HideContainer(container)
	for _, icon in ipairs(container.icons) do
		self:HideIcon(icon)
	end
	container:Hide()
end

function Auras:HideIcon(icon)
	self.activeIcons[icon] = nil
	icon:Hide()
	icon.currentSpellID = nil
	icon.currentApplied = nil
	if icon.showAnimation then
		icon.showAnimation:Stop()
	end
	icon:SetScale(1)
	self:ResetIconCooldown(icon)
end

function Auras:EnsureIconAnimation(icon)
	if icon.showAnimation then
		return
	end
	local group = CreateAnimationGroup(icon)
	group.width = group:CreateAnimation("Width")
	group.width:SetDuration(0.15)
	group.height = group:CreateAnimation("Height")
	group.height:SetDuration(0.15)
	icon.showAnimation = group
end

function Auras:PlayIconAnimation(icon)
	if not icon or not self.general.showAnimations then
		return
	end
	self:EnsureIconAnimation(icon)
	if icon.showAnimation then
		--icon.showAnimation:Stop()
		local iconWidth = icon:GetWidth()
		local iconHeight = icon:GetHeight()
		icon:SetWidth(iconWidth * 0.2)
		icon:SetHeight(iconHeight * 0.7)
		icon.showAnimation.width:SetChange(iconWidth)
		icon.showAnimation.height:SetChange(iconHeight)
		icon.showAnimation:Play()
	end
end

function Auras:SetFrameGUID(frame, guid)
	if frame.npGUID == guid then
		return
	end
	if frame.npGUID and self.guidToFrame[frame.npGUID] == frame then
		self.guidToFrame[frame.npGUID] = nil
	end
	frame.npGUID = guid
	if guid then
		self.guidToFrame[guid] = frame
	end
end

function Auras:SetFrameUnit(frame, unit)
	if frame.npUnit == unit then
		return
	end
	if frame.npUnit and self.unitToFrame[frame.npUnit] == frame then
		self.unitToFrame[frame.npUnit] = nil
	end
	frame.npUnit = unit
	if unit then
		self.unitToFrame[unit] = frame
	end
end

function Auras:OnPlayerEnteringWorld()
	self.playerGUID = UnitGUID("player")
	self:UpdateAllFrames()
end

function Auras:OnTrackedUnitEvent()
	self:UpdateAllFrames()
end

function Auras:OnArenaOpponentUpdate(unit, state)
	if not unit or not self.tracker or not self.tracker:IsTrackedUnit(unit) then
		self:OnTrackedUnitEvent()
		return
	end
	if state == "seen" or state == "destroyed" or state == "cleared" then
		self:UpdateByUnit(unit)
	else
		self:OnTrackedUnitEvent()
	end
end

function Auras:UpdateMouseoverWatcher()
	if not self.mouseoverWatcher then
		return
	end
	local shouldWatch = self.general and self.general.enable and self.tracker and self.tracker.IsTrackedUnit and self.tracker:IsTrackedUnit("mouseover") and self.tracker.enableCombatLogTracking == false
	if shouldWatch then
		self.mouseoverWatcherActive = true
		self.mouseoverElapsed = 0
		self.mouseoverLastExists = UnitExists("mouseover") and true or false
		self.mouseoverWatcher:Show()
	else
		self.mouseoverWatcherActive = false
		self.mouseoverElapsed = 0
		self.mouseoverLastExists = nil
		self.mouseoverWatcher:Hide()
	end
end

function Auras:OnMouseoverUpdate(elapsed)
	if not self.mouseoverWatcherActive then
		return
	end
	self.mouseoverElapsed = (self.mouseoverElapsed or 0) + (elapsed or 0)
	if self.mouseoverElapsed < 0.1 then
		return
	end
	self.mouseoverElapsed = 0
	local exists = UnitExists("mouseover")
	if exists then
		self.mouseoverLastExists = true
		return
	end
	if self.mouseoverLastExists then
		self.mouseoverLastExists = false
		self:HandleMouseoverCleared()
	end
end

function Auras:HandleMouseoverCleared()
	if not (self.tracker and self.tracker.enableCombatLogTracking == false) then
		return
	end
	local frame = self.unitToFrame and self.unitToFrame["mouseover"]
	if not frame then
		return
	end
	self:UpdateFrameAuras(frame)
end

function Auras:UNIT_AURA(unit)
	if not unit then
		return
	end
	if self.tracker and self.tracker:IsTrackedUnit(unit) then
		self:UpdateByUnit(unit)
	end
end

function Auras:UpdateByUnit(unit)
	local frame = self.unitToFrame[unit]
	if frame then
		self:UpdateFrameAuras(frame, unit)
	else
		self:UpdateAllFrames()
	end
end

function Auras:OnAuraTrackerUpdate(guid)
	if not guid then
		self:UpdateAllFrames()
		return
	end
	local frame = self.guidToFrame[guid]
	if frame then
		self:UpdateFrameAuras(frame)
	end
end

function Auras:UpdateAllFrames()
	self:EnsureInit()
	for frame in pairs(self.frames) do
		self:UpdateFrameAuras(frame)
	end
end

function Auras:HideAllFrames()
	self:EnsureInit()
	for frame in pairs(self.frames) do
		self:HideContainers(frame)
		self:SetFrameGUID(frame, nil)
		self:SetFrameUnit(frame, nil)
	end
end

function Auras:ConfigureFrame(frame)
	if not frame.npAuras then
		return
	end
	for index, container in ipairs(frame.npAuras.frames) do
		local cfg = self.auraFrameConfig[index] or EMPTY_TABLE
		container.config = cfg
		container:ClearAllPoints()
		local anchor = cfg.anchor or "TOP"
		local relativeAnchor = NotPlater.oppositeAnchors[anchor] or anchor
		local relativeFrame = frame.healthBar or frame
		if index > 1 then
			local previous = frame.npAuras.frames[index - 1]
			if previous then
				relativeFrame = previous
				-- align to the opposite edge of the previous container so offsets are relative to its top
				relativeAnchor = NotPlater.oppositeAnchors[anchor] or anchor
			end
		end
		container:SetPoint(relativeAnchor, relativeFrame, anchor, cfg.xOffset or 0, cfg.yOffset or 0)
		container:SetAlpha(self.general.alpha or 1)
		self:ConfigureIcons(container, index)
	end
end

function Auras:ConfigureIcons(container, index)
	for _, icon in ipairs(container.icons) do
		self:ConfigureIconFonts(icon)
		self:ApplyIconSize(icon, index)
	end
end

function Auras:ConfigureIconFonts(icon)
	local stackConfig = self.stackCounter
	local timerConfig = self.auraTimer
	if icon.stackText then
		self:ApplyFont(icon.stackText, stackConfig)
		if stackConfig.position then
			icon.stackText:ClearAllPoints()
			local anchor = stackConfig.position.anchor
			local relativeAnchor = NotPlater.oppositeAnchors[anchor] or anchor
			icon.stackText:SetPoint(relativeAnchor, icon, anchor, stackConfig.position.xOffset or -1, stackConfig.position.yOffset or 1)
		end
	end
	if icon.timerText then
		self:ApplyFont(icon.timerText, timerConfig)
		if timerConfig.position then
			icon.timerText:ClearAllPoints()
			local anchor = timerConfig.position.anchor
			local relativeAnchor = NotPlater.oppositeAnchors[anchor] or anchor
			icon.timerText:SetPoint(relativeAnchor, icon, anchor, timerConfig.position.xOffset or 0, timerConfig.position.yOffset or 0)
		end
	end
end

function Auras:ApplyFont(fontString, config)
	if not fontString or not config or not config.general then
		return
	end
	local general = config.general
	if general.name and NotPlater.SML then
		fontString:SetFont(NotPlater.SML:Fetch(NotPlater.SML.MediaType.FONT, general.name), general.size or 10, general.border or "")
	elseif general.name then
		fontString:SetFont(general.name, general.size or 10, general.border or "")
	end
	if general.color then
		fontString:SetTextColor(general.color[1] or 1, general.color[2] or 1, general.color[3] or 1, general.color[4] or 1)
	end
	if config.shadow and config.shadow.enable then
		fontString:SetShadowOffset(config.shadow.xOffset or 0, config.shadow.yOffset or 0)
		fontString:SetShadowColor(config.shadow.color and config.shadow.color[1] or 0, config.shadow.color and config.shadow.color[2] or 0, config.shadow.color and config.shadow.color[3] or 0, config.shadow.color and config.shadow.color[4] or 1)
	else
		fontString:SetShadowColor(0, 0, 0, 0)
	end
end

function Auras:GetSizeConfig(index)
	return self.auraFrameConfig[index] or EMPTY_TABLE
end

function Auras:ApplyIconSize(icon, index)
	local size = self:GetSizeConfig(index)
	local width = size.width or 22
	local height = size.height or 22
	NotPlater:SetSize(icon, width, height)
	if icon.border then
		local thickness = size.borderThickness or 1
		icon.border:SetPoint("TOPLEFT", -thickness, thickness)
		icon.border:SetPoint("BOTTOMRIGHT", thickness, -thickness)
	end
end

function Auras:GetAurasPerRow(index, defaultWidth)
	local config = self.auraFrameConfig[index] or EMPTY_TABLE
	local fallback = 10
	return config.rowCount or fallback
end

function Auras:UpdateFrameAuras(frame, forcedUnit)
	if not self.general.enable then
		self:HideContainers(frame)
		return
	end
	if forcedUnit and not SafeUnit(forcedUnit) then
		forcedUnit = nil
	end
	local unit = forcedUnit or self:IdentifyUnit(frame)
	if unit and not SafeUnit(unit) then
		unit = nil
	end
	if unit then
		self:SetFrameUnit(frame, unit)
	else
		self:SetFrameUnit(frame, nil)
	end
	local guid = frame.lastGuidMatch or (unit and UnitGUID(unit)) or frame.npGUID
	if not unit and not (self.tracker and self.tracker.enableCombatLogTracking) then
		self:SetFrameGUID(frame, nil)
		self:HideContainers(frame)
		return
	end
	if guid then
		self:SetFrameGUID(frame, guid)
	end
	local targetIsPlayer = false
	if guid then
		targetIsPlayer = self:IsPlayerGUID(guid)
	elseif unit then
		targetIsPlayer = UnitIsPlayer(unit)
	end
	frame.npIsPlayer = targetIsPlayer
	local auras = self:CollectAuras(unit, frame.npGUID)
	if not auras or #auras == 0 then
		self:HideContainers(frame)
		return
	end
	local filtered
	if frame.npSimulatedAuras then
		filtered = auras
	else
		filtered = self:FilterAuras(auras, targetIsPlayer)
	end
	if #filtered == 0 then
		self:HideContainers(frame)
		return
	end
	self:DisplayAuras(frame, filtered)
end

function Auras:IdentifyUnit(frame)
	local matched = frame.lastUnitMatch
	if matched and SafeUnit(matched) then
		return matched
	end
	local trackedList = (self.tracker and self.tracker.trackedUnitList and #self.tracker.trackedUnitList > 0) and self.tracker.trackedUnitList or DEFAULT_TRACKED_UNITS
	for _, unit in ipairs(trackedList) do
		if self:VerifyUnit(frame, unit) then
			return unit
		end
	end
	local group = NotPlater.raid or NotPlater.party
	if group then
		for _, unitID in pairs(group) do
			local targetString = unitID .. "-target"
			if self:VerifyUnit(frame, targetString) then
				return targetString
			end
		end
	end
	return nil
end

function Auras:VerifyUnit(frame, unit)
	if not SafeUnit(unit) then
		return false
	end
	local nameText = frame.defaultNameText or frame.nameText
	local levelText = frame.levelText
	local plateName = nameText and nameText:GetText()
	local plateLevel = levelText and levelText:GetText()
	if plateName ~= UnitName(unit) then
		return false
	end
	local level = UnitLevel(unit)
	local levelString = level and tostring(level) or plateLevel
	if plateLevel ~= levelString then
		return false
	end
	local health = frame.healthBar:GetValue()
	if health ~= UnitHealth(unit) then
		return false
	end
	return true
end

function Auras:IsPlayerGUID(guid)
	if not guid then
		return false
	end
	if guid == self.playerGUID then
		return true
	end
	if self.tracker then
		if self.tracker.GetUnitTypeFromGUID then
			return self.tracker:GetUnitTypeFromGUID(guid) == "player"
		end
		if self.tracker.IsPlayerGUID then
			return self.tracker:IsPlayerGUID(guid)
		end
	end
	return false
end

function Auras:CollectAuras(unit, guid)
	if not self.tracker then
		return nil
	end
	return self.tracker:CollectAuras(unit, guid)
end


function Auras:FilterAuras(candidates, targetIsPlayer)
	local filtered = {}
	local manual = self.tracking.mode == "MANUAL"
	for _, aura in ipairs(candidates) do
		aura.sourceIsPlayer = aura.sourceIsPlayer ~= nil and aura.sourceIsPlayer or self:IsPlayerGUID(aura.casterGUID)
		aura.isEnrage = aura.dispelType == "Enrage"
		aura.isDispellable = aura.dispelType and aura.dispelType ~= "" and aura.dispelType ~= "none"
		aura.remaining = aura.expirationTime and math_max(0, aura.expirationTime - GetTime()) or 0
		if self:PassesFilters(aura, targetIsPlayer, manual) then
			aura.priority = self:GetPriority(aura)
			aura.borderKey = self:GetBorderKey(aura)
			tinsert(filtered, aura)
		end
	end
	table.sort(filtered, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end
		return (a.expirationTime or huge) < (b.expirationTime or huge)
	end)
	if self.general.stackSimilarAuras then
		return self:CollapseStacks(filtered)
	end
	return filtered
end

function Auras:PassesFilters(aura, targetIsPlayer, manualMode)
	if aura.isDebuff and self:IsAuraListed(self.blacklist.debuffs, aura) then
		return false
	end
	if aura.isBuff and self:IsAuraListed(self.blacklist.buffs, aura) then
		return false
	end
	local forced = (aura.isDebuff and self:IsAuraListed(self.whitelist.debuffs, aura)) or (aura.isBuff and self:IsAuraListed(self.whitelist.buffs, aura))
	if manualMode then
		return forced and true or false
	end
	if forced then
		return true
	end
	local auto = self.tracking.automatic or EMPTY_TABLE
	if aura.sourceIsPlayer then
		if aura.casterGUID == self.playerGUID then
			if auto.showPlayerAuras == false then
				return false
			end
		else
			if auto.showOtherPlayerAuras == false then
				return false
			end
		end
	else
		if auto.showOtherNPCAuras == false then
			return false
		end
	end
	if aura.isBuff and not targetIsPlayer and auto.showNpcBuffs == false then
		return false
	end
	if aura.isDebuff and not targetIsPlayer and auto.showNpcDebuffs == false then
		return false
	end
	if aura.isCrowdControl then
		return auto.showCrowdControl ~= false
	end
	if aura.isEnrage then
		return auto.showEnrageBuffs ~= false
	end
	if aura.isBuff and aura.dispelType == "Magic" and auto.showMagicBuffs == false then
		return false
	end
	if aura.isBuff and aura.isDispellable then
		if auto.showDispellableBuffs == false then
			return false
		end
		if auto.onlyShortDispellableOnPlayers and targetIsPlayer and aura.duration and aura.duration > 10 then
			return false
		end
	end
	return true
end

function Auras:GetPriority(aura)
	if aura.isCrowdControl then
		return 6
	end
	if aura.isEnrage then
		return 5
	end
	if aura.isDispellable then
		return 4
	end
	if aura.isBuff then
		return 2
	end
	return 1
end

function Auras:GetBorderKey(aura)
	if aura.isCrowdControl then
		return "crowdControl"
	end
	if aura.isEnrage then
		return "enrage"
	end
	if aura.isDispellable then
		return "dispellable"
	end
	if aura.isBuff and aura.sourceIsPlayer then
		return "offensiveCD"
	end
	if aura.isBuff and aura.casterGUID == aura.targetGUID then
		return "defensiveCD"
	end
	if aura.isBuff then
		return "buff"
	end
	return "default"
end

function Auras:CollapseStacks(auras)
	local collapsed = {}
	local tracker = {}
	for _, aura in ipairs(auras) do
		local key = aura.spellID .. (aura.isDebuff and ":D" or ":B")
		local existing = tracker[key]
		if not existing then
			tracker[key] = aura
			tinsert(collapsed, aura)
		else
			existing.count = math_max(existing.count or 0, aura.count or 0)
			if self.general.showShortestStackTime then
				if aura.expirationTime < existing.expirationTime then
					existing.expirationTime = aura.expirationTime
					existing.duration = aura.duration
				end
			else
				if aura.expirationTime > existing.expirationTime then
					existing.expirationTime = aura.expirationTime
					existing.duration = aura.duration
				end
			end
		end
	end
	return collapsed
end

function Auras:DisplayAuras(frame, auras)
	if not frame.npAuras then
		return
	end
	local assignments = {
		[1] = {},
		[2] = {},
	}
	if self.db.auraFrame2 and self.db.auraFrame2.enable then
		for _, aura in ipairs(auras) do
			if aura.isDebuff then
				tinsert(assignments[1], aura)
			else
				tinsert(assignments[2], aura)
			end
		end
	else
		assignments[1] = auras
	end
	for index, container in ipairs(frame.npAuras.frames) do
		self:DisplayContainer(frame, container, assignments[index])
	end
end

function Auras:DisplayContainer(frame, container, auras)
	if not container then
		return
	end
	local defaultWidth = frame.healthBar:GetWidth()
	if not auras or #auras == 0 then
		self:HideContainer(container)
		return
	end
	container:Show()
	local perRow = self:GetAurasPerRow(container.index, defaultWidth)
	local spacing = self.general.iconSpacing or 0
	local rowSpacing = self.general.rowSpacing or 0
	local grow = (container.config and container.config.growDirection) or "RIGHT"
	local size = self:GetSizeConfig(container.index)
	local iconWidth = (size and size.width or 22)
	local iconHeight = (size and size.height or 22)
	local rows = math_max(1, math_ceil(#auras / perRow))
	local border = (size and size.borderThickness or 0)
	local effectiveSpacing = spacing + border * 2
	local effectiveRowSpacing = rowSpacing + border * 2
	local containerWidth = perRow * iconWidth + effectiveSpacing * math_max(0, perRow - 1)
	local containerHeight = rows * iconHeight + effectiveRowSpacing * math_max(0, rows - 1)
	NotPlater:SetSize(container, containerWidth, containerHeight)
	for i, aura in ipairs(auras) do
		local icon = self:AcquireIcon(container, i)
		self:SetupIcon(icon, aura, size, container.index)
		self:PositionIcon(container, icon, i, perRow, #auras, grow, size, spacing, rowSpacing)
		icon:Show()
		self.activeIcons[icon] = true
	end
	for i = #auras + 1, #container.icons do
		self:HideIcon(container.icons[i])
	end
end

function Auras:AcquireIcon(container, index)
	if not container.icons[index] then
		container.icons[index] = self:CreateIcon(container)
	end
	self:ConfigureIconFonts(container.icons[index])
	self:ApplyIconSize(container.icons[index], container.index)
	return container.icons[index]
end

function Auras:CreateIcon(container)
	local icon = CreateFrame("Frame", nil, container)
	NotPlater:SetSize(icon, 24, 24)
	icon:SetScale(1)
	icon.icon = icon:CreateTexture(nil, "OVERLAY")
	icon.icon:SetAllPoints()
	icon.border = icon:CreateTexture(nil, "ARTWORK")
	icon.border:SetTexture(1, 1, 1, 1)
	icon.stackText = icon:CreateFontString(nil, "OVERLAY")
	icon.timerText = icon:CreateFontString(nil, "OVERLAY")
	icon:EnableMouse(true)
	icon:SetScript("OnEnter", function(frameIcon)
		if self.general.showTooltip and frameIcon.spellID then
			GameTooltip:SetOwner(frameIcon, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetSpellByID(frameIcon.spellID)
		end
	end)
	icon:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return icon
end

function Auras:SetupIcon(icon, aura, size, index)
	icon.spellID = aura.spellID
	icon.aura = aura
	local appliedTime = nil
	if aura.expirationTime and aura.duration and aura.duration > 0 then
		appliedTime = aura.expirationTime - aura.duration
	elseif aura.expirationTime then
		appliedTime = aura.expirationTime
	end
	local isNewAssignment = icon.currentSpellID ~= aura.spellID or icon.currentApplied ~= appliedTime
	icon.currentSpellID = aura.spellID
	icon.currentApplied = appliedTime
	icon.icon:SetTexture(aura.icon or DEFAULT_ICON)
	self:ApplyIconSize(icon, index)
	self:SetIconBorder(icon, aura, size)
	if aura.count and aura.count > 1 and self.stackCounter.general and self.stackCounter.general.enable then
		icon.stackText:SetText(aura.count)
		icon.stackText:Show()
	else
		icon.stackText:SetText("")
		icon.stackText:Hide()
	end
	if self.auraTimer.general and self.auraTimer.general.enable and aura.duration and aura.duration > 0 and aura.expirationTime < huge then
		icon.timerText:Show()
	else
		icon.timerText:SetText("")
		icon.timerText:Hide()
	end
	local hasCooldown = aura.duration and aura.duration > 0 and aura.expirationTime < huge
	if hasCooldown and self.swipe.showSwipe then
		local provider = self:EnsureIconCooldownProvider(icon)
		if provider and provider.Setup then
			provider:Setup(icon, aura, self.swipe, self)
		end
	else
		self:ResetIconCooldown(icon)
	end
	aura.remaining = aura.expirationTime and math_max(0, aura.expirationTime - GetTime()) or 0
	self:UpdateIconTimer(icon)
	if isNewAssignment then
		self:PlayIconAnimation(icon)
	end
end

function Auras:SetIconBorder(icon, aura, size)
	local color = self:GetBorderColor(aura)
	icon.border:SetTexture(color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1)
	local thickness = (size and size.borderThickness) or 1
	icon.border:SetPoint("TOPLEFT", -thickness, thickness)
	icon.border:SetPoint("BOTTOMRIGHT", thickness, -thickness)
end

function Auras:GetBorderColor(aura)
	if aura.isDispellable and self.borderColors.useTypeColors and aura.dispelType and DebuffTypeColor[aura.dispelType] then
		local c = DebuffTypeColor[aura.dispelType]
		return {c.r, c.g, c.b, 1}
	end
	local color = self.borderColors[aura.borderKey] or self.borderColors.default or {0, 0, 0, 1}
	return color
end

function Auras:PositionIcon(container, icon, index, perRow, totalAuras, growDirection, size, spacing, rowSpacing)
	local iconWidth = (size and size.width or 22)
	local iconHeight = (size and size.height or 22)
	local border = (size and size.borderThickness or 0)
	local effectiveSpacing = spacing + border * 2
	local effectiveRowSpacing = rowSpacing + border * 2
	local stepX = iconWidth + effectiveSpacing
	local stepY = iconHeight + effectiveRowSpacing
	local row = floor((index - 1) / perRow)
	local column = (index - 1) % perRow
	local totalRows = math_max(1, math_ceil(totalAuras / perRow))
	local isLastRow = (row == totalRows - 1)
	local iconsInRow = isLastRow and math_max(1, totalAuras - row * perRow) or perRow
	icon:ClearAllPoints()
	if growDirection == "LEFT" then
		icon:SetPoint("TOPRIGHT", container, "TOPRIGHT", -(column * stepX), -row * stepY)
	elseif growDirection == "CENTER" then
		local offset = column - ((iconsInRow - 1) / 2)
		icon:SetPoint("TOP", container, "TOP", offset * stepX, -row * stepY)
	else
		icon:SetPoint("TOPLEFT", container, "TOPLEFT", column * stepX, -row * stepY)
	end
end

function Auras:UpdateIconTimer(icon)
	if not icon.timerText or not icon.aura then
		return
	end
	if not (self.auraTimer.general and self.auraTimer.general.enable) then
		return
	end
	local aura = icon.aura
	if not aura.expirationTime or aura.expirationTime == huge or not aura.duration or aura.duration == 0 then
		icon.timerText:SetText("")
		return
	end
	local remaining = aura.expirationTime - GetTime()
	if remaining <= 0 then
		icon.timerText:SetText("")
		self.activeIcons[icon] = nil
		return
	end
	if remaining >= 60 then
		icon.timerText:SetText(format("%dm", math_ceil(remaining / 60)))
	elseif self.auraTimer.general.showDecimals and remaining < 10 then
		icon.timerText:SetText(format("%.1f", remaining))
	else
		icon.timerText:SetText(format("%d", remaining))
	end
end
