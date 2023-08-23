if( not NotPlater ) then return end

local Threat = LibStub("Threat-2.0")

local tgetn = table.getn
local tostring = tostring
local UnitGUID = UnitGUID
local UnitAffectingCombat = UnitAffectingCombat
local UnitInRaid = UnitInRaid
local GetRaidRosterInfo = GetRaidRosterInfo
local UnitInParty = UnitInParty
local GetPartyMember = GetPartyMember
local UnitCanAttack = UnitCanAttack
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local lastThreat = {}

function NotPlater:RAID_ROSTER_UPDATE()
	self.raid = nil
	if UnitInRaid("player") then
		self.raid = {}
		local raidNum = GetNumRaidMembers()
		local i = 1
		while raidNum > 0 and i <= MAX_RAID_MEMBERS do
			if GetRaidRosterInfo(i) then
				local guid = UnitGUID("raid" .. i)
				self.raid[guid] = "raid" .. i

				local pet = UnitGUID("raidpet" .. i)
				if pet then
					self.raid[pet] = "raidpet" .. i
				end
				raidNum = raidNum - 1
			end
			i = i + 1
		end
	end
end

function NotPlater:PARTY_MEMBERS_CHANGED()
	self.party = nil
	if UnitInParty("party1") then
		local partyNum = GetNumPartyMembers()
		local i = 1
		self.party = {}
		while partyNum > 0 and i < MAX_PARTY_MEMBERS do
			if GetPartyMember(i) then
				self.party[UnitGUID("party" .. i)] = "party" .. i
				local pet = UnitGUID("partypet" .. i)
				if pet then
					self.party[pet] = "partypet" .. i
				end
				partyNum = partyNum - 1
			end
			i = i + 1
		end
		self.party[UnitGUID("player")] = "player"
		local pet = UnitGUID("pet")
		if pet then
			self.party[pet] = "pet"
		end
	end
end

function NotPlater:OnNameplateMatch(healthFrame, group, ThreatLib)
	if not ThreatLib then ThreatLib = Threat end
	local threatConfig = self.db.profile.threat
	local unit = healthFrame.lastUnitMatch
	local player = UnitGUID("player")
	local playerThreat = ThreatLib:GetThreat(player, unit)
	local playerThreatNumber = 1
	local highestThreat, highestThreatMember = ThreatLib:GetMaxThreatOnTarget(unit)
	local secondHighestThreat = 0
	if highestThreat and highestThreat > 0 then
		for gMember,_ in pairs(group) do
			local gMemberThreat = ThreatLib:GetThreat(gMember, unit)
			if gMemberThreat then
				if gMemberThreat ~= highestThreat and gMemberThreat > secondHighestThreat then
					secondHighestThreat = gMemberThreat
				end

				if gMemberThreat > playerThreat then
					playerThreatNumber = playerThreatNumber + 1
				end
			end
		end

		local mode = threatConfig.general.mode
		if threatConfig.nameplateColors.general.enable or threatConfig.differentialText.general.enable then
			local barColorConfig, textColorConfig = threatConfig.nameplateColors.colors, threatConfig.differentialText.colors
			local barColor, textColor
			if mode == "hdps" then
				if highestThreat == playerThreat then
					barColor = barColorConfig[mode].c1
					textColor = textColorConfig[mode].c1
				elseif lastThreat[unit] and highestThreat - (playerThreat + 3*(playerThreat - lastThreat[unit])) < 0 then
					barColor = barColorConfig[mode].c2
					textColor = textColorConfig[mode].c2
				else
					barColor = barColorConfig[mode].c3
					textColor = textColorConfig[mode].c3
				end
			else -- "tank"
				if highestThreat == playerThreat then
					if lastThreat[unit] and (playerThreat - 3*(playerThreat - lastThreat[unit]) - secondHighestThreat) < 0 then
						barColor = barColorConfig[mode].c2
						textColor = textColorConfig[mode].c2
					else
						barColor = barColorConfig[mode].c1
						textColor = textColorConfig[mode].c1
					end
				else
					barColor = barColorConfig[mode].c3
					textColor = textColorConfig[mode].c3
				end
			end

			local frame = healthFrame:GetParent()
			if self.db.profile.threat.nameplateColors.general.useClassColors and frame.unitClass then
				healthFrame:SetStatusBarColor(frame.unitClass.r, frame.unitClass.g, frame.unitClass.b, 1)
			elseif threatConfig.nameplateColors.general.enable then
				healthFrame:SetStatusBarColor(self:GetColor(barColor))
			end

			if threatConfig.differentialText.general.enable then
				local threatDiff = 0
				if highestThreat == playerThreat then
					threatDiff = playerThreat - secondHighestThreat
				else
					threatDiff = highestThreat - playerThreat
				end

				healthFrame.threatDifferentialText:SetTextColor(self:GetColor(textColor))
				if threatDiff < 1000 then
					healthFrame.threatDifferentialText:SetFormattedText("%.0f", threatDiff)
				else
					threatDiff = threatDiff / 1000
					healthFrame.threatDifferentialText:SetFormattedText("%.1fk", threatDiff)
				end
				healthFrame.threatDifferentialText:Show()
			else
				healthFrame.threatDifferentialText:Hide()
			end
		end

		-- Number text
		local numberTextConfig = threatConfig.numberText
		if numberTextConfig.general.enable then
			local numberColor = nil
			if playerThreatNumber == 1 then
				numberColor = numberTextConfig.colors[mode].c1
			elseif playerThreatNumber / (tgetn(group) - 1) < 0.2 then
				numberColor = numberTextConfig.colors[mode].c2
			else
				numberColor = numberTextConfig.colors[mode].c3
			end
			healthFrame.threatNumberText:SetTextColor(self:GetColor(numberColor))
			healthFrame.threatNumberText:SetText(tostring(playerThreatNumber))
			healthFrame.threatNumberText:Show()
		else
			healthFrame.threatNumberText:Hide()
		end

		-- Percent bar
		local percentConfig = threatConfig.percent
		if percentConfig.statusBar.general.enable then
			local threatPercent, barColor = playerThreat/highestThreat * 100, nil
			if threatPercent >= 100 then
				barColor = percentConfig.statusBar.colors[mode].c1
			elseif threatPercent >= 90 then
				barColor = percentConfig.statusBar.colors[mode].c2
			else
				barColor = percentConfig.statusBar.colors[mode].c3
			end
			healthFrame.threatPercentBar:SetValue(threatPercent)
			barColor = percentConfig.statusBar.general.useThreatColors and barColor or percentConfig.statusBar.general.color
			healthFrame.threatPercentBar:SetStatusBarColor(self:GetColor(barColor))
			healthFrame.threatPercentBar:Show()
		else
			healthFrame.threatPercentBar:Hide()
		end

		-- Percent text
		if percentConfig.text.general.enable then
			local threatPercent, textColor = playerThreat/highestThreat * 100, nil
			if threatPercent >= 100 then
				textColor = percentConfig.text.colors[mode].c1
			elseif threatPercent >= 90 then
				textColor = percentConfig.text.colors[mode].c2
			else
				textColor = percentConfig.text.colors[mode].c3
			end
			healthFrame.threatPercentText:SetFormattedText("%d%%", threatPercent)
			textColor = percentConfig.text.general.useThreatColors and textColor or percentConfig.text.general.color
			healthFrame.threatPercentText:SetTextColor(self:GetColor(textColor))
			healthFrame.threatPercentText:Show()
		else
			healthFrame.threatPercentText:Hide()
		end

		lastThreat[unit] = playerThreat
	end
end

function NotPlater:MouseoverThreatCheck(healthFrame, guid)
	if UnitInParty("party1") or UnitInRaid("player") then
		healthFrame.lastUnitMatch = guid
		local group = self.raid or self.party
		self:OnNameplateMatch(healthFrame, group)
	else
		local frame = healthFrame:GetParent().unitClass
		if self.db.profile.threat.nameplateColors.general.useClassColors and frame.unitClass then
			healthFrame:SetStatusBarColor(frame.unitClass.r, frame.unitClass.g, frame.unitClass.b, 1)
		else
			if self.db.profile.healthBar.statusBar.general.enable then
				healthFrame:SetStatusBarColor(self:GetColor(self.db.profile.healthBar.statusBar.general.color))
			end
		end
	end
end

function NotPlater:ThreatCheck(frame)
	local _, _, _, _, nameText, levelText = frame:GetRegions()
	if not nameText or not levelText then return end
	local healthFrame = frame.healthBar
	local name = nameText:GetText()
	local level = levelText:GetText()
	local _, healthMaxValue = healthFrame:GetMinMaxValues()
    local healthValue = healthFrame:GetValue()
	if UnitInParty("party1") or UnitInRaid("player") then
		local group = self.raid or self.party
		if healthValue ~= healthMaxValue then
			for gMember,unitID in pairs(group) do
				local targetString = unitID .. "-target"
				local unit = UnitGUID(targetString)
				if UnitCanAttack("player", targetString) and not UnitIsDeadOrGhost(targetString) and UnitAffectingCombat(targetString) then
					if name == UnitName(targetString) and level == tostring(UnitLevel(targetString)) and healthValue == UnitHealth(targetString) then
						healthFrame.lastUnitMatch = unit
						break
					end
				end
			end
			if UnitCanAttack("player", "mouseover") and not UnitIsDeadOrGhost("mouseover") and UnitAffectingCombat("mouseover") then
				if name == UnitName("mouseover") and level == tostring(UnitLevel("mouseover")) and healthValue == UnitHealth("mouseover") then
					healthFrame.lastUnitMatch = UnitGUID("mouseover")
				end
			end
			if UnitCanAttack("player", "focus") and not UnitIsDeadOrGhost("focus") and UnitAffectingCombat("focus") then
				if name == UnitName("focus") and level == tostring(UnitLevel("focus")) and healthValue == UnitHealth("focus") then
					healthFrame.lastUnitMatch = UnitGUID("focus")
				end
			end
		end
		if healthFrame.lastUnitMatch then
			self:OnNameplateMatch(healthFrame, group)
		end
	else -- Not in party
		if UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and UnitAffectingCombat("target") then
			if name == UnitName("target") and level == tostring(UnitLevel("target")) and healthValue == UnitHealth("target") and healthValue ~= healthMaxValue then
				if self.db.profile.threat.nameplateColors.general.useClassColors and frame.unitClass then
					healthFrame:SetStatusBarColor(frame.unitClass.r, frame.unitClass.g, frame.unitClass.b, 1)
				else
					if self.db.profile.healthBar.statusBar.general.enable then
						healthFrame:SetStatusBarColor(self:GetColor(self.db.profile.healthBar.statusBar.general.color))
					end
				end
			end
		end
	end
end

function NotPlater:ScaleThreatComponents(healthFrame, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.threat then
		local threatConfig = self.db.profile.threat
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleGeneralisedStatusBar(healthFrame.threatPercentBar, scalingFactor, threatConfig.percent.statusBar)
		self:ScaleGeneralisedText(healthFrame.threatPercentText, scalingFactor, threatConfig.percent.text)
		self:ScaleGeneralisedText(healthFrame.threatDifferentialText, scalingFactor, threatConfig.differentialText)
		self:ScaleGeneralisedText(healthFrame.threatNumberText, scalingFactor, threatConfig.numberText)
	end
end

function NotPlater:ThreatComponentsOnShow(frame)
	local healthFrame = frame.healthBar
	healthFrame.threatDifferentialText:SetText("")
	healthFrame.threatNumberText:SetText("")
	healthFrame.threatPercentText:SetText("")
	healthFrame.threatPercentBar:Hide()
	healthFrame.lastUnitMatch = nil
	self:ThreatCheck(frame)
end

function NotPlater:ConfigureThreatComponents(frame)
	local healthFrame = frame.healthBar
	local threatConfig = self.db.profile.threat
	-- Set differential text
	self:ConfigureGeneralisedText(healthFrame.threatDifferentialText, healthFrame, threatConfig.differentialText)

	-- Set number text
	self:ConfigureGeneralisedText(healthFrame.threatNumberText, healthFrame, threatConfig.numberText)

	-- Set percent text
	self:ConfigureGeneralisedText(healthFrame.threatPercentText, healthFrame.threatPercentBar, threatConfig.percent.text)

	-- Set percent bar
	self:ConfigureGeneralisedPositionedStatusBar(healthFrame.threatPercentBar, healthFrame, threatConfig.percent.statusBar)

	self:ThreatCheck(frame)
end

function NotPlater:ConstructThreatComponents(healthFrame)
	healthFrame:SetFrameLevel(healthFrame:GetParent():GetFrameLevel() + 1)

    -- Create threat text
    healthFrame.threatDifferentialText = healthFrame:CreateFontString(nil, "ARTWORK")
    healthFrame.threatNumberText = healthFrame:CreateFontString(nil, "ARTWORK")

	-- Percent text
    healthFrame.threatPercentText = healthFrame:CreateFontString(nil, "OVERLAY")

	-- Percent bar
    healthFrame.threatPercentBar = CreateFrame("StatusBar", nil, healthFrame)
	self:ConstructGeneralisedStatusBar(healthFrame.threatPercentBar)
    healthFrame.threatPercentBar:SetMinMaxValues(0, 100)
    healthFrame.threatPercentBar:SetFrameLevel(healthFrame:GetFrameLevel() - 1)
    healthFrame.threatPercentBar:Hide()
end