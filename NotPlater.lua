NotPlater = LibStub("AceAddon-3.0"):NewAddon("NotPlater", "AceEvent-3.0", "AceHook-3.0")
local Threat = LibStub("Threat-2.0")

local frames = {}
local SML

local party = {}
local raid = {}
local lastThreat = {}

local targetCheckElapsed = 0

function NotPlater:OnInitialize()
	self.defaults = {
		profile = {
			threat = 
			{ 
				mode = "hdps",
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
				threatDifferentialText = 
				{
					enabled = false,
					anker = "LEFT",
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
					anker = "RIGHT",
					xOffset = 25,
					yOffset = 0,
					fontName = "Arial Narrow", 
					fontSize = 15, 
					fontBorder = "OUTLINE", 
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
				backgroundColor = {r = 0, g = 0, b = 0, a = 0.7}, 
				hideBorder = false, 
				hideTargetBorder = false, 
				position = 
				{
					anker = "TOP",
					xOffset = 0,
					yOffset = 0,
					xSize = 112,
					ySize = 15,
				},
				healthText = 
				{
					type = "both", 
					fontColor = {r = 1, g = 1, b = 1, a = 1},
					anker = "CENTER",
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
				texture = "Smooth", 
				backgroundColor = {r = 0, g = 0, b = 0, a = 0.7}, 
				position = 
				{
					anker = "TOP",
					xOffset = 0,
					yOffset = -15,
					xSize = 112,
					ySize = 15,
				},
				castSpellIcon =
				{
					opacity = 1,
					anker = "LEFT",
					xOffset = -15,
					yOffset = 0,
					xSize = 15,
					ySize = 15,
				},
				castTimeText = 
				{
					type = "timeleft", 
					fontColor = {r = 1, g = 1, b = 1, a = 1},
					anker = "RIGHT",
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
					anker = "CENTER",
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
				anker = "CENTER",
				xOffset = 0,
				yOffset = 0,
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
				anker = "TOPRIGHT",
				xOffset = -25,
				yOffset = 10,
				fontName = "Arial Narrow", 
				fontSize = 8, 
				fontBorder = "", 
				fontShadowEnabled = true, 
				fontShadowColor = { r = 0, g = 0, b = 0, a = 1 }, 
				fontShadowXOffset = 0, 
				fontShadowYOffset = 0
			},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("NotPlaterDB", self.defaults)
	self.revision = tonumber(string.match("$Revision$", "(%d+)") or 1)

	self:PARTY_MEMBERS_CHANGED()
	self:RAID_ROSTER_CHANGED()
	
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_CHANGED")
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
end

function NotPlater:GetColor(config)
	return config.r, config.g, config.b, config.a
end

function NotPlater:SetupFontString(text, type, color)
	local config = type

	if text then
		text:SetFont(SML:Fetch(SML.MediaType.FONT, config.fontName), config.fontSize, config.fontBorder)

		-- Set color
		if color then
			text:SetTextColor(config.fontColor.r, config.fontColor.g, config.fontColor.b, config.fontColor.a)
		end

		-- Set shadow
		if( config.fontShadowEnabled ) then
			if( not text.npOriginalShadow ) then
				local x, y = text:GetShadowOffset()
				local r, g, b, a = text:GetShadowColor()
				
				text.npOriginalShadow = { r = r, g = g, b = b, a = a, y = y, x = x }
			end
			
			text:SetShadowColor(config.fontShadowColor.r, config.fontShadowColor.g, config.fontShadowColor.b, config.fontShadowColor.a)
			text:SetShadowOffset(config.fontShadowXOffset, config.fontShadowYOffset)
		-- Restore original
		elseif( text.npOriginalShadow ) then
			text:SetShadowColor(text.npOriginalShadow.r, text.npOriginalShadow.g, text.npOriginalShadow.b, text.npOriginalShadow.a)
			text:SetShadowOffset(text.npOriginalShadow.x, text.npOriginalShadow.y)
			text.npOriginalShadow = nil
		end
	end
end

function NotPlater:ThreatCheck(health, healthValue)
	local threatProfile = self.db.profile.threat
	local frame = health:GetParent()
	local _, _, _, _, nameText, levelText = frame:GetRegions()
	local name = nameText:GetText()
	local level = levelText:GetText()
	local _, healthMaxValue = health:GetMinMaxValues()
	if UnitInParty("party1") or UnitInRaid("player") then
		local group = UnitInRaid("player") and raid or party
		for gMember,unitID in pairs(group) do
			local targetString = unitID .. "-target"
			local unit = UnitGUID(targetString)
			if UnitCanAttack("player", targetString) and not UnitIsDeadOrGhost(targetString) and UnitAffectingCombat(targetString) and UnitAffectingCombat(unitID) then
				if name == UnitName(targetString) and level == tostring(UnitLevel(targetString)) and healthValue == UnitHealth(targetString) and healthValue ~= maxHealthValue then
					health.lastUnitMatch = unit
					break
				end
			end
		end
		unit = health.lastUnitMatch
		if unit then
			local player = UnitGUID("player")
			local playerThreat = Threat:GetThreat(player, unit)
			local playerThreatNumber = 1
			local highestThreat = playerThreat
			local secondHighestThreat = 0
			if playerThreat ~=0 then
				for gMember,_ in pairs(group) do
					if gMember ~= player then
						local gMemberThreat = Threat:GetThreat(gMember, unit)
						if gMemberThreat then
							if gMemberThreat > highestThreat then
								highestThreat = gMemberThreat
							elseif gMemberThreat > secondHighestThreat then
								secondHighestThreat = gMemberThreat
							end

							if gMemberThreat > playerThreat then
								playerThreatNumber = playerThreatNumber + 1
							end
						end
					end
				end

				if threatProfile.nameplateColors.enabled or threatProfile.threatDifferentialText.enabled then
					local nameplateColorsConfig = threatProfile.nameplateColors
					local threatDiffColorsConfig = threatProfile.threatDifferentialText
					local statusBarColor = nil
					local threatDiffColor = nil
					if threatProfile.mode == "hdps" then
						if highestThreat == playerThreat then
							statusBarColor = nameplateColorsConfig.dpsHealerAggroOnYou
							threatDiffColor = threatDiffColorsConfig.dpsHealerAggroOnYou
						elseif lastThreat[unit] and highestThreat - (playerThreat + 3*(playerThreat - lastThreat[unit])) < 0 then
							statusBarColor = nameplateColorsConfig.dpsHealerHighThreat
							threatDiffColor = threatDiffColorsConfig.dpsHealerHighThreat
						else
							statusBarColor = nameplateColorsConfig.dpsHealerDefaultNoAggro
							threatDiffColor = threatDiffColorsConfig.dpsHealerDefaultNoAggro
						end
					else -- "tank"
						if highestThreat == playerThreat then
							if lastThreat[unit] and playerThreat + 3*(playerThreat - lastThreat[unit]) - secondHighestThreat < 0 then
								statusBarColor = nameplateColorsConfig.tankDpsClose
								threatDiffColor = threatDiffColorsConfig.tankDpsClose
							else
								statusBarColor = nameplateColorsConfig.tankAggroOnYou
								threatDiffColor = threatDiffColorsConfig.tankAggroOnYou
							end
						else
							statusBarColor = nameplateColorsConfig.tankNoAggro
							threatDiffColor = threatDiffColorsConfig.tankNoAggro
						end
					end

					if threatProfile.nameplateColors.enabled then
						health:SetStatusBarColor(self:GetColor(statusBarColor))
					end

					if threatProfile.threatDifferentialText.enabled then
						local threatDiff = 0
						if highestThreat == playerThreat then
							threatDiff = playerThreat - secondHighestThreat
						else
							threatDiff = highestThreat - playerThreat
						end

						health.threatDifferentialText:SetTextColor(self:GetColor(threatDiffColor))
						if threatDiff < 1000 then
							health.threatDifferentialText:SetText(string.format("%.0f", threatDiff))
						else
							threatDiff = threatDiff / 1000
							health.threatDifferentialText:SetText(string.format("%.1f", threatDiff) .. "k")
						end
					else
						health.threatDifferentialText:SetText("")
					end
				end

				if threatProfile.threatNumberText.enabled then
					local colorsConfig = threatProfile.threatNumberText
					local threatNumberColor = nil
					if threatProfile.mode == "hdps" then
						if playerThreatNumber == 1 then
							threatNumberColor = colorsConfig.dpsHealerFirstOnThreat
						elseif playerThreatNumber / (table.getn(group) - 1) < 0.2 then
							threatNumberColor = colorsConfig.dpsHealerUpperTwentyPercentOnThreat
						else
							threatNumberColor = colorsConfig.dpsHealerLowerEightyPercentOnThreat
						end
					else -- "tank"
						if playerThreatNumber == 1 then
							threatNumberColor = colorsConfig.tankFirstOnThreat
						elseif playerThreatNumber / (table.getn(group) - 1) < 0.2 then
							threatNumberColor = colorsConfig.tankUpperTwentyPercentOnThreat
						else
							threatNumberColor = colorsConfig.tankLowerEightyPercentOnThreat
						end
					end
					health.threatNumberText:SetTextColor(self:GetColor(threatNumberColor))
					health.threatNumberText:SetText(tostring(playerThreatNumber))
				else
					health.threatNumberText:SetText("")
				end

				lastThreat[unit] = playerThreat
			end
		else
			health.threatNumberText:SetText("")
			health.threatDifferentialText:SetText("")
			health.lastUnitMatch = nil
		end
	else -- Not in party
		if UnitAffectingCombat("player") then
			if threatProfile.nameplateColors.enabled then
				local nameplateColorsConfig = threatProfile.nameplateColors
				if name == UnitName("target") and level == tostring(UnitLevel("target")) and healthValue == UnitHealth("target") then
					if threatProfile.mode == "hdps" then
						health:SetStatusBarColor(nameplateColorsConfig.dpsHealerDefaultNoAggro.r, nameplateColorsConfig.dpsHealerDefaultNoAggro.g, nameplateColorsConfig.dpsHealerDefaultNoAggro.b, nameplateColorsConfig.dpsHealerDefaultNoAggro.a)
					else
						health:SetStatusBarColor(nameplateColorsConfig.tankAggroOnYou.r, nameplateColorsConfig.tankAggroOnYou.g, nameplateColorsConfig.tankAggroOnYou.b, nameplateColorsConfig.tankAggroOnYou.a)
					end
				end
			end
		end
	end
end

function NotPlater:IsTarget(frame)
    local targetExists = UnitExists('target')
    if (not targetExists) then
        return false
    end

	local nameText  = select(5,frame:GetRegions())
    local targetName = UnitName('target')
    if (targetName == nameText:GetText() and frame:GetAlpha() >= 0.99) then
        return true
    else
        return false
    end
end

function NotPlater:PrepareFrame(frame)
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetRegions()
	local health, cast = frame:GetChildren()

	-- Configs
	local healthBarConfig = self.db.profile.healthBar
	local castBarConfig = self.db.profile.castBar
	local threatConfig = self.db.profile.threat
	local nameTextConfig = self.db.profile.nameText
	local levelTextConfig = self.db.profile.levelText

	-- Hooks and creation (only once that way settings can be applied while frame is visible)
	if not frame.npHooked then
		frame.npHooked = true

		-- Create health text
		health.npHealthText = health:CreateFontString(nil, "ARTWORK")

		-- Create cast text
		cast.npCastTimeText = cast:CreateFontString(nil, "ARTWORK")
		cast.npCastNameText = cast:CreateFontString(nil, "ARTWORK")

		-- Create threat text
		health.threatDifferentialText = health:CreateFontString(nil, "ARTWORK")
		health.threatNumberText = health:CreateFontString(nil, "ARTWORK")

		-- Other addons need the texture of healthBorder to not change, therefore we have to create a new one
		health.npHealthOverlay = frame:CreateTexture(nil, 'ARTWORK')
		health.npHealthOverlay:SetAllPoints(health)
		health.npHealthOverlay:SetTexture('Interface\\AddOns\\NotPlater\\images\\textureOverlay')

		-- Background
		cast.npCastBackground = cast:CreateTexture(nil, 'ARTWORK')
		health.npHealthBackground = health:CreateTexture(nil, 'ARTWORK')
		
		-- Hide highlight texture
		highlightTexture:SetTexture(0, 0, 0, 0)
		highlightTexture:Hide()
	
		-- Hide borders
		healthBorder:Hide()
		castBorder:SetTexture(0, 0, 0, 0)
		castBorder:Hide()

		self:HookScript(cast, "OnValueChanged", "CastOnValueChanged")
		self:HookScript(health, "OnValueChanged", "HealthOnValueChanged")

		self:HookScript(health, 'OnHide', function(health)
			health.npHealthOverlay:Hide()
		end)

		self:HookScript(health, "OnShow", function(health)
			-- Set point for healthbar
			health:ClearAllPoints()
			health:SetSize(healthBarConfig.position.xSize, healthBarConfig.position.ySize)
			health:SetPoint(healthBarConfig.position.anker, healthBarConfig.position.xOffset, healthBarConfig.position.yOffset)
			if(not healthBarConfig.hideBorder) then
				health.npHealthOverlay:Show()
			end
			levelText:SetAlpha(levelTextConfig.fontOpacity)
			health.threatDifferentialText:SetText("")
			health.threatNumberText:SetText("")
			self:ThreatCheck(health, health:GetValue())
		end)

		self:HookScript(cast, "OnShow", function(cast)
			-- Set points for castbar
			cast:ClearAllPoints()
			cast:SetSize(castBarConfig.position.xSize, castBarConfig.position.ySize)
			cast:SetPoint(castBarConfig.position.anker, castBarConfig.position.xOffset, castBarConfig.position.yOffset)
			cast:SetFrameLevel(frame:GetFrameLevel() + 1)
			spellIcon:ClearAllPoints()
			spellIcon:SetSize(castBarConfig.castSpellIcon.xSize, castBarConfig.castSpellIcon.ySize)
			spellIcon:SetPoint(castBarConfig.castSpellIcon.anker, cast, castBarConfig.castSpellIcon.xOffset, castBarConfig.castSpellIcon.yOffset)
			spellIcon:SetAlpha(castBarConfig.castSpellIcon.opacity)
		end)

		if(not healthBarConfig.hideTargetBorder) then
			self:HookScript(frame, 'OnUpdate', function(_, elapsed)
				targetCheckElapsed = targetCheckElapsed + elapsed
				if (targetCheckElapsed >= 0.1) then
		
				if (true) then
					if (self:IsTarget(frame)) then
						if (not frame.npTargetHighlight) then
							frame.npTargetHighlight = frame:CreateTexture(nil, 'ARTWORK')
							frame.npTargetHighlight:SetPoint("TOPRIGHT", health, 2, 2)
							frame.npTargetHighlight:SetPoint("BOTTOMLEFT", health, -2, -2)
							frame.npTargetHighlight:SetTexture('Interface\\AddOns\\NotPlater\\images\\targetTextureOverlay')
							frame.npTargetHighlight:Hide()
						end
		
						if (not frame.npTargetHighlight:IsVisible()) then
							frame.npTargetHighlight:Show()
						end
					else
						if (frame.npTargetHighlight and frame.npTargetHighlight:IsVisible()) then
							frame.npTargetHighlight:Hide()
						end
					end
				end
				targetCheckElapsed = 0
				end
			end)
		end
	end

	-- Set textures for health- and castbar
	health:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, healthBarConfig.texture))
	cast:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, castBarConfig.texture))

	-- Set health text
	health.npHealthText:ClearAllPoints()
	health.npHealthText:SetPoint(healthBarConfig.healthText.anker, health, healthBarConfig.healthText.xOffset, healthBarConfig.healthText.yOffset)

	-- Set cast text
	cast.npCastTimeText:ClearAllPoints()
	cast.npCastTimeText:SetPoint(castBarConfig.castTimeText.anker, cast, castBarConfig.castTimeText.xOffset, castBarConfig.castTimeText.yOffset)
	cast.npCastNameText:ClearAllPoints()
	cast.npCastNameText:SetPoint(castBarConfig.castNameText.anker, cast, castBarConfig.castNameText.xOffset, castBarConfig.castNameText.yOffset)

	-- Set point for the system default texts
	nameText:ClearAllPoints()
	nameText:SetPoint(nameTextConfig.anker, nameTextConfig.xOffset, nameTextConfig.yOffset)
	levelText:ClearAllPoints()
	levelText:SetPoint(levelTextConfig.anker, levelTextConfig.xOffset, levelTextConfig.yOffset)

	-- Set threat text
	health.threatDifferentialText:ClearAllPoints()
	health.threatDifferentialText:SetPoint(threatConfig.threatDifferentialText.anker, health, threatConfig.threatDifferentialText.xOffset, threatConfig.threatDifferentialText.yOffset)
	health.threatNumberText:ClearAllPoints()
	health.threatNumberText:SetPoint(threatConfig.threatNumberText.anker, health, threatConfig.threatNumberText.xOffset, threatConfig.threatNumberText.yOffset)

	-- Set point for healthbar
	health:ClearAllPoints()
	health:SetSize(healthBarConfig.position.xSize, healthBarConfig.position.ySize)
	health:SetPoint(healthBarConfig.position.anker, healthBarConfig.position.xOffset, healthBarConfig.position.yOffset)

	-- Set point for castbar
	cast:ClearAllPoints()
	cast:SetSize(castBarConfig.position.xSize, castBarConfig.position.ySize)
	cast:SetPoint(castBarConfig.position.anker, castBarConfig.position.xOffset, castBarConfig.position.yOffset)
	cast:SetFrameLevel(frame:GetFrameLevel() + 1)

	-- Set point for castbar icon
	spellIcon:ClearAllPoints()
	spellIcon:SetSize(castBarConfig.castSpellIcon.xSize, castBarConfig.castSpellIcon.ySize)
	spellIcon:SetPoint(castBarConfig.castSpellIcon.anker, cast, castBarConfig.castSpellIcon.xOffset, castBarConfig.castSpellIcon.yOffset)
	spellIcon:SetAlpha(castBarConfig.castSpellIcon.opacity)

	-- Set point for overlays / borders
	health.npHealthOverlay:SetAllPoints(health)

	-- Set point for background
	cast.npCastBackground:SetAllPoints(cast)
	cast.npCastBackground:SetDrawLayer("BORDER")
	cast.npCastBackground:SetTexture(castBarConfig.backgroundColor.r, castBarConfig.backgroundColor.g, castBarConfig.backgroundColor.b, castBarConfig.backgroundColor.a)
	health.npHealthBackground:SetAllPoints(health)
	health.npHealthBackground:SetDrawLayer("BORDER")
	health.npHealthBackground:SetTexture(healthBarConfig.backgroundColor.r, healthBarConfig.backgroundColor.g, healthBarConfig.backgroundColor.b, healthBarConfig.backgroundColor.a)

	-- Font string config
	self:SetupFontString(nameText, nameTextConfig, false)
	if(not nameTextConfig.fontEnabled) then
		nameText:Hide()
	else
		nameText:Show()
	end
	self:SetupFontString(levelText, levelTextConfig, false)
	levelText:SetAlpha(levelTextConfig.fontOpacity)
	self:SetupFontString(health.npHealthText, healthBarConfig.healthText, true)
	self:SetupFontString(cast.npCastTimeText, castBarConfig.castTimeText, true)
	self:SetupFontString(cast.npCastNameText, castBarConfig.castNameText, true)
	self:SetupFontString(health.threatDifferentialText, threatConfig.threatDifferentialText)
	self:SetupFontString(health.threatNumberText, threatConfig.threatNumberText)
	health.threatDifferentialText:SetText("")
	health.threatNumberText:SetText("")

	-- Update everything
	self:HealthOnValueChanged(health, health:GetValue())
	self:CastOnValueChanged(cast, cast:GetValue())
	self:ThreatCheck(health, health:GetValue())
end

function NotPlater:RAID_ROSTER_CHANGED()
	raid = {}
	if UnitInRaid("player") then
		local raidNum = GetNumRaidMembers()
		local i = 1
		while raidNum > 0 and i <= MAX_RAID_MEMBERS do
			if GetRaidRosterInfo(i) then
				local guid = UnitGUID("raid" .. i)
				if guid ~= UnitGUID("player") then
					raid[guid] = "raid" .. i
				end
				local pet = UnitGUID("raidpet" .. i)
				if pet then
					party[pet] = "raidpet" .. i
				end
				raidNum = raidNum - 1
			end
			i = i + 1
		end
	end
end

function NotPlater:PARTY_MEMBERS_CHANGED()
	party = {}
	if UnitInParty("party1") then
		local partyNum = GetNumPartyMembers()
		local i = 1
		while partyNum > 0 and i < MAX_PARTY_MEMBERS do
			if GetPartyMember(i) then
				party[UnitGUID("party" .. i)] = "party" .. i
				local pet = UnitGUID("partypet" .. i)
				if pet then
					party[pet] = "partypet" .. i
				end
				partyNum = partyNum - 1
			end
			i = i + 1
		end
		party[UnitGUID("player")] = "player"
		local pet = UnitGUID("pet")
		if pet then
			party[pet] = "pet"
		end
	end
end

function NotPlater:HealthOnValueChanged(health, value)
	local _, maxValue = health:GetMinMaxValues()
	local healthBarConfig = self.db.profile.healthBar

	if( healthBarConfig.healthText.type == "minmax" ) then
		if( maxValue == 100 ) then
			health.npHealthText:SetFormattedText("%d%% / %d%%", value, maxValue)	
		else
			if(maxValue > 1000) then
				if(value > 1000) then
					health.npHealthText:SetFormattedText("%.1fk / %.1fk", value / 1000, maxValue / 1000)
				else
					health.npHealthText:SetFormattedText("%d / %.1fk", value, maxValue / 1000)
				end
			else
				health.npHealthText:SetFormattedText("%d / %d", value, maxValue)
			end
		end
	elseif( healthBarConfig.healthText.type == "both" ) then
		if(value > 1000) then
			health.npHealthText:SetFormattedText("%.1fk (%d%%)", value/1000, value/maxValue * 100)
		else
			health.npHealthText:SetFormattedText("%d (%d%%)", value, value/maxValue * 100)
		end
	elseif( healthBarConfig.healthText.type == "percent" ) then
		health.npHealthText:SetFormattedText("%d%%", value / maxValue * 100)
	else
		health.npHealthText:SetText("")
	end

	self:ThreatCheck(health, value)
end

function NotPlater:CastOnValueChanged(castFrame, value)
	local minValue, maxValue = castFrame:GetMinMaxValues()
	local cast = UnitCastingInfo('target')
    local channel = UnitChannelInfo('target')
	local castBarConfig = self.db.profile.castBar
	
	if( value >= maxValue or value == 0 ) then
		castFrame.npCastTimeText:SetText("")
		castFrame.npCastNameText:SetText("")
		castFrame.npCastBackground:Hide()
		return
	else
		castFrame.npCastBackground:Show()
	end
	
	-- Quick hack stolen from old NP, I need to fix this up
	maxValue = maxValue - value + ( value - minValue )
	value = math.floor(((value - minValue) * 100) + 0.5) / 100
	
	if( castBarConfig.castTimeText.type == "crtmax" ) then
		castFrame.npCastTimeText:SetFormattedText("%.1f / %.1f", value, maxValue)
	elseif( castBarConfig.castTimeText.type == "crt" ) then
		castFrame.npCastTimeText:SetFormattedText("%.1f", value)
	elseif( castBarConfig.castTimeText.type == "percent" ) then
		castFrame.npCastTimeText:SetFormattedText("%d%%", value / maxValue)
	elseif( castBarConfig.castTimeText.type == "timeleft" ) then
		castFrame.npCastTimeText:SetFormattedText("%.1f", maxValue - value)
	else
		castFrame.npCastTimeText:SetText("")
	end

	castFrame.npCastNameText:SetText(cast or channel)
end

local function hookFrames(...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		local region = frame:GetRegions()
		if( not frames[frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			frames[frame] = true
			NotPlater:PrepareFrame(frame)
		end
	end
end

local numChildren = -1
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
	if( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren()
		hookFrames(WorldFrame:GetChildren())
	end
end)

function NotPlater:Reload()
	for frame in pairs(frames) do
		NotPlater:PrepareFrame(frame)
	end
end

function NotPlater:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99NotPlater|r: " .. msg)
end