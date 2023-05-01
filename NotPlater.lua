NotPlater = LibStub("AceAddon-3.0"):NewAddon("NotPlater", "AceEvent-3.0", "AceHook-3.0")

local UnitName = UnitName
local UnitExists = UnitExists

local frames = {}

NotPlater.frame = CreateFrame("Frame")
function NotPlater:OnInitialize()
	self.defaults = {
		profile = {
			general = 
			{ 
				frameStrata =
				{
					frame = "LOW",
					targetFrame = "MEDIUM"
				},
				nameplateStacking =
				{
					enabled = false,
					overlappingCastbars = true,
					xMargin = 0,
					yMargin = 0
				}
			},
			threat = 
			{
				general = 
				{
					mode = "hdps",
					enableMouseoverUpdate = true
				},
				nameplateColors =
				{
					enabled = true,
					dpsHealerAggroOnYou = {r = 1, g = 0.109, b = 0, a = 1},
					dpsHealerHighThreat = {r = 1, g = 0.8, b = 0, a = 1},
					dpsHealerDefaultNoAggro = {r = 0.5, g = 0.5, b = 1, a = 1},
					tankNoAggro = {r = 1, g = 0.109, b = 0, a = 1},
					tankDpsClose = {r = 1, g = 0.8, b = 0, a = 1},
					tankAggroOnYou = {r = 0.5, g = 0.5, b = 1, a = 1}
				},
				threatPercentBarText =
				{
					fontEnabled = false,
					fontName = "Arial Narrow",
					fontSize = 8,
					fontBorder = "NONE",
					fontColor = {r = 0, g = 0, b = 0, a = 1},
					fontUseThreatColors = false,
					fontAnchor = "CENTER",
					fontXOffset = 0,
					fontYOffset = 0,
					fontShadowEnabled = false,
					fontShadowColor = { r = 0, g = 0, b = 0, a = 1 },
					fontShadowXOffset = 0, 
					fontShadowYOffset = 0,
					barEnabled = false,
					barUseThreatColors = true,
					barTexture = "Smooth",
					barColor = {r = 1, g = 0, b = 0, a = 1},
					barBorderEnabled = true,
					barBorderThickness = 1,
					barBorderColor = {r = 0, g = 0, b = 0, a = 1},
					barBackgroundColor = {r = 0, g = 0, b = 0, a = 0.3},
					barAnchor = "TOPLEFT",
					barXOffset = 0,
					barYOffset = 12,
					barXSize = 30,
					barYSize = 10,
					dpsHealerOneHundredPercent = {r = 1, g = 0, b = 0, a = 1},
					dpsHealerAboveNinetyPercent = {r = 1, g = 0.65, b = 0, a = 1},
					dpsHealerBelowNinetyPercent = {r = 0, g = 1, b = 0, a = 1},
					tankOneHundredPercent = {r = 0, g = 1, b = 0, a = 1},
					tankAboveNinetyPercent = {r = 1, g = 0.65, b = 0, a = 1},
					tankBelowNinetyPercent = {r = 1, g = 0, b = 0, a = 1}
				},
				threatDifferentialText =
				{
					enabled = false,
					anchor = "LEFT",
					xOffset = -35,
					yOffset = 0,
					fontName = "Arial Narrow", 
					fontSize = 11, 
					fontBorder = "OUTLINE", 
					fontShadowEnabled = false, 
					fontShadowColor = { r = 0, g = 0, b = 0, a = 1 },
					fontShadowXOffset = 0, 
					fontShadowYOffset = 0,
					dpsHealerAggroOnYou = {r = 1, g = 0, b = 0, a = 1},
					dpsHealerHighThreat = {r = 1, g = 0.65, b = 0, a = 1},
					dpsHealerDefaultNoAggro = {r = 0, g = 1, b = 0, a = 1},
					tankNoAggro = {r = 1, g = 0, b = 0, a = 1},
					tankDpsClose = {r = 1, g = 0.65, b = 0, a = 1},
					tankAggroOnYou = {r = 0, g = 1, b = 0, a = 1}
				},
				threatNumberText = 
				{
					enabled = false,
					anchor = "RIGHT",
					xOffset = 25,
					yOffset = 0,
					fontName = "Arial Narrow", 
					fontSize = 20, 
					fontBorder = "NONE", 
					fontShadowEnabled = false, 
					fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
					fontShadowXOffset = 0, 
					fontShadowYOffset = 0,
					dpsHealerFirstOnThreat = {r = 1, g = 0, b = 0, a = 1},
					dpsHealerUpperTwentyPercentOnThreat = {r = 1, g = 0.65, b = 0, a = 1},
					dpsHealerLowerEightyPercentOnThreat = {r = 0, g = 1, b = 0, a = 1},
					tankFirstOnThreat = {r = 0, g = 1, b = 0, a = 1},
					tankUpperTwentyPercentOnThreat = {r = 1, g = 0.65, b = 0, a = 1},
					tankLowerEightyPercentOnThreat = {r = 1, g = 0, b = 0, a = 1}
				},
			},
			healthBar = 
			{ 
				texture = "Smooth", 
				backgroundColor = {r = 0, g = 0, b = 0, a = 0.5}, 
				hideBorder = false, 
				hideTargetBorder = false, 
				position = 
				{
					xSize = 112,
					ySize = 15,
				},
				healthText = 
				{
					type = "both", 
					fontColor = {r = 1, g = 1, b = 1, a = 1},
					anchor = "CENTER",
					xOffset = 0,
					yOffset = 0,
					fontName = "Arial Narrow", 
					fontSize = 9, 
					fontBorder = "OUTLINE", 
					fontShadowEnabled = false, 
					fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
					fontShadowXOffset = 0, 
					fontShadowYOffset = 0
				},
			},
			castBar = 
			{ 
				enabled = true,
				texture = "Smooth", 
				barColor = {r = 0.765, g = 0.525, b = 0, a = 1}, 
				backgroundColor = {r = 0, g = 0, b = 0, a = 0.7}, 
				position = 
				{
					anchor = "BOTTOMLEFT",
					xOffset = 0,
					yOffset = -15,
					xSize = 112,
					ySize = 15,
				},
				castSpellIcon =
				{
					opacity = 1,
					anchor = "LEFT",
					xOffset = -15,
					yOffset = 0,
					xSize = 15,
					ySize = 15,
				},
				castTimeText = 
				{
					type = "timeleft", 
					fontColor = {r = 1, g = 1, b = 1, a = 1},
					anchor = "RIGHT",
					xOffset = -5,
					yOffset = 0,
					fontName = "Arial Narrow", 
					fontSize = 11, 
					fontBorder = "OUTLINE", 
					fontShadowEnabled = false, 
					fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
					fontShadowXOffset = 0, 
					fontShadowYOffset = 0
				},
				castNameText = 
				{
					fontColor = {r = 1, g = 1, b = 1, a = 1},
					anchor = "CENTER",
					xOffset = 0,
					yOffset = 0,
					fontName = "Arial Narrow", 
					fontSize = 11, 
					fontBorder = "OUTLINE", 
					fontShadowEnabled = false, 
					fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
					fontShadowXOffset = 0, 
					fontShadowYOffset = 0
				},
			},
			nameText = 
			{ 
				fontEnabled = true,
				anchor = "CENTER",
				xOffset = 0,
				yOffset = -15,
				fontName = "Arial Narrow", 
				fontSize = 11, 
				fontBorder = "", 
				fontShadowEnabled = true, 
				fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
				fontShadowXOffset = 0, 
				fontShadowYOffset = 0
			},
			levelText = 
			{ 
				fontOpacity = 0.7,
				anchor = "TOPRIGHT",
				xOffset = -5,
				yOffset = 10,
				fontName = "Arial Narrow", 
				fontSize = 8, 
				fontBorder = "", 
				fontShadowEnabled = true, 
				fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
				fontShadowXOffset = 0, 
				fontShadowYOffset = 0
			},
			raidIcon = 
			{ 
				opacity = 1,
				anchor = "RIGHT",
				xOffset = 25,
				yOffset = 0,
				xSize = 20,
				ySize = 20,
			},
			bossIcon = 
			{ 
				opacity = 1,
				anchor = "LEFT",
				xOffset = -25,
				yOffset = 0,
				xSize = 20,
				ySize = 20,
			},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("NotPlaterDB", self.defaults)
	self.revision = tonumber(string.match("$Revision$", "(%d+)") or 1)

	self:PARTY_MEMBERS_CHANGED()
	self:RAID_ROSTER_UPDATE()
	
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:Reload()

	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")
end

function NotPlater:IsTarget(frame)
    local targetExists = UnitExists('target')
    if (not targetExists) then
        return false
    end

	local nameText  = select(5,frame:GetRegions())
    local targetName = UnitName('target')

    return targetName == nameText:GetText() and frame:GetAlpha() >= 0.99
end

function NotPlater:PrepareFrame(frame)
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetRegions()
	local health, cast = frame:GetChildren()

	-- Hooks and creation (only once that way settings can be applied while frame is visible)
	if not frame.npHooked then
		frame.npHooked = true
		
		-- Hide highlight texture
		highlightTexture:SetTexture(0, 0, 0, 0)
		highlightTexture:Hide()
	
		-- Hide default border
		healthBorder:Hide()

		-- Construct everything
		self:ConstructThreatComponents(health)
		self:ConstructHealthBar(health)
		self:ConstructCastBar(frame)
		self:ConstructTargetBorder(health, frame)
		self:ConstructStacking(frame)

		--  General hook to set everything that is changed on show
		self:HookScript(health, "OnShow", function(health)
			NotPlater:HealthBarOnShow(health)
			NotPlater:CastBarOnShow(frame)
			NotPlater:LevelTextOnShow(levelText, health)
			NotPlater:ThreatComponentsOnShow(health)
		end)
	end
	
	-- Configure everything
	self:ConfigureThreatComponents(health)
	self:ConfigureHealthBar(health)
	self:ConfigureCastBar(frame)
	self:ConfigureStacking(frame)
	self:ConfigureIcon(bossIcon, health, self.db.profile.bossIcon)
	self:ConfigureIcon(raidIcon, health, self.db.profile.raidIcon)
	self:ConfigureLevelText(levelText, health)
	self:ConfigureNameText(nameText, health)
end

function NotPlater:HookFrames(...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		local region = frame:GetRegions()
		if( not frames[frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			frames[frame] = true
			self:PrepareFrame(frame)
		end
	end
end

function NotPlater:Reload()
	if self.db.profile.castBar.enabled then
		self:RegisterCastBarEvents(NotPlater.frame)
	else
		self:UnregisterCastBarEvents(NotPlater.frame)
	end

	if self.db.profile.threat.general.enableMouseoverUpdate then
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	else
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end

	for frame in pairs(frames) do
		self:PrepareFrame(frame)
	end
end

function NotPlater:UPDATE_MOUSEOVER_UNIT()
	local mouseOverGuid = UnitGUID("mouseover")
	if UnitCanAttack("player", "mouseover") and not UnitIsDeadOrGhost("mouseover") and UnitAffectingCombat("mouseover") then
		local targetGuid = UnitGUID("target")
		for frame in pairs(frames) do
			if mouseOverGuid == targetGuid then
				if self:IsTarget(frame) then
					local health = frame:GetChildren()
					self:MouseoverThreatCheck(health, targetGuid)
				end
			else
				local health = frame:GetChildren()
				local _, _, _, _, nameText, levelText = frame:GetRegions()
				local name = nameText:GetText()
				local level = levelText:GetText()
				local _, healthMaxValue = health:GetMinMaxValues()
				local healthValue = health:GetValue()
				if name == UnitName("mouseover") and level == tostring(UnitLevel("mouseover")) and healthValue == UnitHealth("mouseover") and healthValue ~= healthMaxValue then
					self:MouseoverThreatCheck(health, mouseOverGuid)
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
	-- this fires before we can see it on the nameplate unlucky
	for frame in pairs(frames) do
		local health = frame:GetChildren()
		if unit == "target" then
			if NotPlater:IsTarget(frame) then
				health.lastUnitMatch = UnitGUID(unit)
				NotPlater:CastBarOnCast(frame, event, unit)
			end
		else
			local _, _, _, _, nameText, levelText = frame:GetRegions()
			local name = nameText:GetText()
			local level = levelText:GetText()
			local _, healthMaxValue = health:GetMinMaxValues()
			local healthValue = health:GetValue()
			if name == UnitName(unit) and level == tostring(UnitLevel(unit)) and healthValue == UnitHealth(unit) and healthValue ~= healthMaxValue then
				health.lastUnitMatch = UnitGUID(unit)
				NotPlater:CastBarOnCast(frame, event, unit)
			end
		end
	end
end)