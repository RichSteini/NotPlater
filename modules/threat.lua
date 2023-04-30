if( not NotPlater ) then return end

local Threat = LibStub("Threat-2.0")

local tgetn = table.getn
local UnitInRaid = UnitInRaid
local GetRaidRosterInfo = GetRaidRosterInfo
local UnitInParty = UnitInParty
local GetPartyMember = GetPartyMember
local UnitCanAttack = UnitCanAttack
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
local MAX_RAID_MEMBERS = MAX_RAID_MEMBERS

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

function NotPlater:OnNameplateMatch(health, group)
	local threatProfile = self.db.profile.threat
	local unit = health.lastUnitMatch
	local player = UnitGUID("player")
	local playerThreat = Threat:GetThreat(player, unit)
	local playerThreatNumber = 1
	local highestThreat, highestThreatMember = Threat:GetMaxThreatOnTarget(unit)
	local secondHighestThreat = 0
	if highestThreat and highestThreat > 0 then
		for gMember,_ in pairs(group) do
			local gMemberThreat = Threat:GetThreat(gMember, unit)
			if gMemberThreat then
				if gMemberThreat ~= highestThreat and gMemberThreat > secondHighestThreat then
					secondHighestThreat = gMemberThreat
				end

				if gMemberThreat > playerThreat then
					playerThreatNumber = playerThreatNumber + 1
				end
			end
		end

		if threatProfile.nameplateColors.enabled or threatProfile.threatDifferentialText.enabled then
			local nameplateColorsConfig = threatProfile.nameplateColors
			local threatDiffColorsConfig = threatProfile.threatDifferentialText
			local statusBarColor = nil
			local threatDiffColor = nil
			if threatProfile.general.mode == "hdps" then
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
			if threatProfile.general.mode == "hdps" then
				if playerThreatNumber == 1 then
					threatNumberColor = colorsConfig.dpsHealerFirstOnThreat
				elseif playerThreatNumber / (tgetn(group) - 1) < 0.2 then
					threatNumberColor = colorsConfig.dpsHealerUpperTwentyPercentOnThreat
				else
					threatNumberColor = colorsConfig.dpsHealerLowerEightyPercentOnThreat
				end
			else -- "tank"
				if playerThreatNumber == 1 then
					threatNumberColor = colorsConfig.tankFirstOnThreat
				elseif playerThreatNumber / (tgetn(group) - 1) < 0.2 then
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
end

function NotPlater:MouseoverThreatCheck(health, guid)
	local threatProfile = self.db.profile.threat
	if UnitInParty("party1") or UnitInRaid("player") then
		health.lastUnitMatch = guid
		local group = self.raid or self.party
		self:OnNameplateMatch(health, group)
	else
		local nameplateColorsConfig = threatProfile.nameplateColors
		if threatProfile.general.mode == "hdps" then
			health:SetStatusBarColor(self:GetColor(nameplateColorsConfig.dpsHealerDefaultNoAggro))
		else
			health:SetStatusBarColor(self:GetColor(nameplateColorsConfig.tankAggroOnYou))
		end
	end
end

function NotPlater:ThreatCheck(health)
	local frame = health:GetParent()
	local _, _, _, _, nameText, levelText = frame:GetRegions()
	local name = nameText:GetText()
	local level = levelText:GetText()
	local _, healthMaxValue = health:GetMinMaxValues()
    local healthValue = health:GetValue()
	if UnitInParty("party1") or UnitInRaid("player") then
		local group = self.raid or self.party
		for gMember,unitID in pairs(group) do
			local targetString = unitID .. "-target"
			local unit = UnitGUID(targetString)
			if UnitCanAttack("player", targetString) and not UnitIsDeadOrGhost(targetString) and UnitAffectingCombat(targetString) then
				if name == UnitName(targetString) and level == tostring(UnitLevel(targetString)) and healthValue == UnitHealth(targetString) and healthValue ~= healthMaxValue then
					health.lastUnitMatch = unit
					break
				end
			end
		end
		if health.lastUnitMatch then
			self:OnNameplateMatch(health, group)
		else
			health.threatNumberText:SetText("")
			health.threatDifferentialText:SetText("")
		end
	else -- Not in party
		local threatProfile = self.db.profile.threat
		if UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and UnitAffectingCombat("target") then
			if threatProfile.nameplateColors.enabled then
				local nameplateColorsConfig = threatProfile.nameplateColors
				if name == UnitName("target") and level == tostring(UnitLevel("target")) and healthValue == UnitHealth("target") and healthValue ~= healthMaxValue then
					if threatProfile.general.mode == "hdps" then
						health:SetStatusBarColor(self:GetColor(nameplateColorsConfig.dpsHealerDefaultNoAggro))
					else
						health:SetStatusBarColor(self:GetColor(nameplateColorsConfig.tankAggroOnYou))
					end
				end
			end
		end
	end
end

function NotPlater:ThreatComponentsOnShow(healthFrame)
	healthFrame.threatDifferentialText:SetText("")
	healthFrame.threatNumberText:SetText("")
	healthFrame.lastUnitMatch = nil
	self:ThreatCheck(healthFrame)
end

function NotPlater:ConfigureThreatComponents(healthFrame)
	local threatConfig = self.db.profile.threat
	-- Set threat text
	healthFrame.threatDifferentialText:ClearAllPoints()
	healthFrame.threatDifferentialText:SetPoint(threatConfig.threatDifferentialText.anchor, healthFrame, threatConfig.threatDifferentialText.xOffset, threatConfig.threatDifferentialText.yOffset)
	healthFrame.threatNumberText:ClearAllPoints()
	healthFrame.threatNumberText:SetPoint(threatConfig.threatNumberText.anchor, healthFrame, threatConfig.threatNumberText.xOffset, threatConfig.threatNumberText.yOffset)
	
    -- Set font
	self:SetupFontString(healthFrame.threatDifferentialText, threatConfig.threatDifferentialText)
	self:SetupFontString(healthFrame.threatNumberText, threatConfig.threatNumberText)
	healthFrame.threatDifferentialText:SetText("")
	healthFrame.threatNumberText:SetText("")

	self:ThreatCheck(healthFrame)
end

function NotPlater:ConstructThreatComponents(healthFrame)
    -- Create threat text
    healthFrame.threatDifferentialText = healthFrame:CreateFontString(nil, "ARTWORK")
    healthFrame.threatNumberText = healthFrame:CreateFontString(nil, "ARTWORK")
end