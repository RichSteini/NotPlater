if not NotPlater then return end

local tinsert = table.insert
local tsort = table.sort
local mrand = math.random
local mfmod = math.fmod
local tostring = tostring
local UIParent = UIParent
local GameTooltip = GameTooltip
local GetTime = GetTime
local UnitGUID = UnitGUID

local L = NotPlaterLocals
local simulatorFrameConstructed = false
local simulatorTextSet = false

local healthMin = 0
local healthMax = 30000
local baseLineDamage = healthMax * 0.01
local baseLineThreat = 1000
local critChance = 0.3 -- 30%
local healerPotential = function() return mfmod(mrand(), 0.5 - 0.3) + 0.3 end -- {max = 0.5, min = 0.3}
local dpsPotential = function() return mfmod(mrand(), 0.8 - 0.5) + 0.5 end -- {max = 0.8, min = 0.5}
local tankPotential = function() return mfmod(mrand(), 0.99 - 0.8) + 0.8 end -- {max = 0.99, min = 0.8}
local threatUpdateElapsed = 0
local castTime = 10000 -- in ms
local nameplateColorChange = {elapsed = 0, interval = 3, currentIndex = 1}
local nameplateColors = {}

local MAX_RAID_ICONS = 8
local RAID_ICON_BASE_PATH = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local BOSS_ICON_PATH = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local currentRaidIconNum = 1
local raidIconInterval = 5
local raidIconElapsed = raidIconInterval

local ThreatTypes = {TANK = 1, DPS = 2, HEALER = 3}
local ThreatSimulator = {}

function ThreatSimulator:GetThreat(sourceGUID, targetGUID)
    if sourceGUID == UnitGUID("player") then
        for k, unit in ipairs(self.group) do
            if unit.isPlayer then
                return unit.currentThreat
            end
        end
    else
        return self.group[sourceGUID].currentThreat
    end
end

function ThreatSimulator:GetMaxThreatOnTarget(targetGUID)
    local maxThreat = -1
    local maxThreatUnit = nil
    for k, unit in ipairs(self.group) do
        if unit.currentThreat > maxThreat then
            maxThreat = unit.currentThreat
            maxThreatUnit = k
        end
    end
    return maxThreat, maxThreatUnit
end

function ThreatSimulator:Reset(healthFrame)
    local threatProfile = NotPlater.db.profile.threat
    healthFrame:SetValue(healthMax)
    local playerSet = false
    for k, unit in ipairs(self.group) do
        unit.currentThreat = 0
        unit.round = 0
        if not playerSet then
            if threatProfile.general.mode == "tank" and unit.type == ThreatTypes.TANK then
                unit.isPlayer = true
                playerSet = true
            elseif threatProfile.general.mode == "hdps" and (unit.type == ThreatTypes.DPS or unit.type == ThreatTypes.HEALER) then
                unit.isPlayer = true
                playerSet = true
            end
        else
            unit.isPlayer = false
        end
    end
end

function ThreatSimulator:Step(healthFrame)
    local numHits = mrand(#self.group)
    local counter = 0
    for k, unit in ipairs(self.group) do
        local crit = math.random() > (1 - critChance) and 2 or 1
        if unit.type == ThreatTypes.TANK or unit.type == ThreatTypes.DPS then
            local newHealth = healthFrame:GetValue() - baseLineDamage * unit.potential() * crit
            if newHealth < 0 then
                self:Reset(healthFrame)
                break
            else
                healthFrame:SetValue(newHealth)
            end
        end
        unit.currentThreat = unit.currentThreat + baseLineThreat * unit.potential() * crit
        unit.round = unit.round + 1
        counter = counter + 1
        if counter > numHits then
            break
        end
    end
    tsort(self.group, function(a, b) return a.round < b.round end)
end

function ThreatSimulator:ConstructThreatScenario(numDPS, numHealers, numTanks)
    self.group = {}
    for i=0, numTanks do
        tinsert(self.group, {type = ThreatTypes.TANK, potential = tankPotential, isPlayer = false, currentThreat = 0, round = 0})
    end
    for i=0, numDPS do
        tinsert(self.group, {type = ThreatTypes.DPS, potential = dpsPotential, isPlayer = false, currentThreat = 0, round = 0})
    end
    for i=0, numHealers do
        tinsert(self.group, {type = ThreatTypes.HEALER, potential = healerPotential, isPlayer = false, currentThreat = 0, round = 0})
    end
end

function NotPlater:SimulatorFrameOnUpdate(elapsed)
	-- Configure everything
	NotPlater:ConfigureHealthBar(self.defaultFrame.defaultHealthFrame)
	NotPlater:ConfigureCastBar(self.defaultFrame)
	NotPlater:ConfigureStacking(self.defaultFrame)
	NotPlater:ConfigureIcon(self.defaultFrame.bossIcon, self.defaultFrame.defaultHealthFrame, NotPlater.db.profile.bossIcon)
	NotPlater:ConfigureIcon(self.defaultFrame.raidIcon, self.defaultFrame.defaultHealthFrame, NotPlater.db.profile.raidIcon)
	NotPlater:ConfigureLevelText(self.defaultFrame.levelText, self.defaultFrame.defaultHealthFrame)
	NotPlater:ConfigureNameText(self.defaultFrame.nameText, self.defaultFrame.defaultHealthFrame)
    if not simulatorTextSet then
        self.defaultFrame.bossIcon.texture:SetTexture(BOSS_ICON_PATH)
        self.defaultFrame.levelText:SetText(L["70"])
        self.defaultFrame.levelText:SetTextColor(1, 1, 0, 1)
        self.defaultFrame.nameText:SetText(L["Playername"])
        simulatorTextSet = true
        ThreatSimulator:Reset(self.defaultFrame.defaultHealthFrame)
    end

    if not self.defaultFrame.npCastBar.casting and NotPlater.db.profile.castBar.enabled then
        local startTime = GetTime()
        local endTime = startTime + castTime
        self.defaultFrame.npCastBar.npCastNameText:SetText(L["Spellname"])
        self.defaultFrame.npCastBar.value = 0
        self.defaultFrame.npCastBar.maxValue = (endTime - startTime) / 1000
        self.defaultFrame.npCastBar:SetMinMaxValues(0, self.defaultFrame.npCastBar.maxValue)
        self.defaultFrame.npCastBar:SetValue(self.defaultFrame.npCastBar.value)

        if self.defaultFrame.npCastBar.npCastIcon then
            self.defaultFrame.npCastBar.npCastIcon.texture:SetTexture("Interface\\Icons\\Temp")
        end
        self.defaultFrame.npCastBar.casting = true
		self.defaultFrame.npCastBar:Show()
    elseif not NotPlater.db.profile.castBar.enabled then
        self.defaultFrame.npCastBar.casting = false
    end

    if raidIconElapsed > raidIconInterval then
        self.defaultFrame.raidIcon.texture:SetTexture(RAID_ICON_BASE_PATH .. tostring(currentRaidIconNum))
        currentRaidIconNum = currentRaidIconNum + 1
        if currentRaidIconNum > MAX_RAID_ICONS then
            currentRaidIconNum = 1
        end
        raidIconElapsed = 0
    end

    raidIconElapsed = raidIconElapsed + elapsed

    if threatUpdateElapsed > 1 then
	    NotPlater:ConfigureThreatComponents(self.defaultFrame.defaultHealthFrame)
        ThreatSimulator:Step(self.defaultFrame.defaultHealthFrame)
        NotPlater:OnNameplateMatch(self.defaultFrame.defaultHealthFrame, ThreatSimulator.group, ThreatSimulator)
        threatUpdateElapsed = 0
    end
    threatUpdateElapsed = threatUpdateElapsed + elapsed
end

function NotPlater:ToggleSimulatorFrame()
    if self.simulatorFrame and self.simulatorFrame:IsShown() then
        self.simulatorFrame:Hide()
    else
        self:ShowSimulatorFrame()
    end
end

function NotPlater:ShowSimulatorFrame()
    self:ConstructSimulatorFrame()
    self.simulatorFrame:Show()
end

function NotPlater:SimulatorFrameOnShow()
    NotPlater.simulatorFrame.defaultFrame.simulatedTarget = true
    NotPlater.simulatorFrame.defaultFrame.defaultHealthFrame.ignoreThreatCheck = true
    NotPlater.oldThreatCheck = NotPlater.ThreatCheck
    NotPlater.ThreatCheck = function(name, frame, ...)
        if frame.ignoreThreatCheck then return end
        NotPlater.oldThreatCheck(name, frame, ...)
    end
    NotPlater.oldIsTarget = NotPlater.IsTarget
    NotPlater.IsTarget = function(name, frame, ...)
        if frame.simulatedTarget then return true end
        return NotPlater.oldIsTarget(name, frame, ...)
    end
end

function NotPlater:SimulatorFrameOnHide()
    if NotPlater.oldThreatCheck then NotPlater.ThreatCheck = NotPlater.oldThreatCheck end
    if NotPlater.oldIsTarget then NotPlater.IsTarget = NotPlater.oldIsTarget end
end

function NotPlater:ConstructSimulatorFrame()
    if simulatorFrameConstructed then return end
    simulatorFrameConstructed = true
    local simulatorFrame = CreateFrame("Frame", "NotPlaterSimulatorFrame", UIParent)
    local simulatorFrameCloseButton = CreateFrame("Button", "NotPlaterSimulatorFrameCloseButton", simulatorFrame, "UIPanelCloseButton")
    simulatorFrameCloseButton:SetPoint("TOPRIGHT")
    simulatorFrame:SetMovable(true)
    simulatorFrame:EnableMouse(true)
    --simulatorFrame:SetUserPlaced(true)
    simulatorFrame:RegisterForDrag("LeftButton")
    simulatorFrame:SetScript("OnUpdate", NotPlater.SimulatorFrameOnUpdate)
    simulatorFrame:SetScript("OnHide", NotPlater.SimulatorFrameOnHide)
    simulatorFrame:SetScript("OnShow", NotPlater.SimulatorFrameOnShow)
    simulatorFrame:SetScript("OnDragStart", simulatorFrame.StartMoving)
    simulatorFrame:SetScript("OnDragStop", simulatorFrame.StopMovingOrSizing)
    simulatorFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["NotPlater Simulator Frame"])
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["|cffeda55fLeft-Click and Drag|r on the outer area to move the simulator frame"], 0.2, 1, 0.2)
        GameTooltip:Show()
    end)
    simulatorFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    simulatorFrame:SetFrameStrata("TOOLTIP")
    simulatorFrame:ClearAllPoints()
    self:SetSize(simulatorFrame, 200, 100)
    simulatorFrame:SetPoint("CENTER")
    simulatorFrame:SetBackdrop({bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", tileSize=16, tile=true, edgeSize=1, insets = {left=4,right=4,top=4,bottom=4}})
	simulatorFrame:SetBackdropColor(0, 0, 0, 0)
    simulatorFrame:SetBackdropBorderColor(1, 1, 1, 0.3)
    simulatorFrame.outlineText = simulatorFrame:CreateFontString(nil, "ARTWORK")
	simulatorFrame.outlineText:SetFont(self.SML:Fetch(self.SML.MediaType.FONT, "Arial Narrow"), 16, "OUTLINE")
	simulatorFrame.outlineText:SetPoint("BOTTOM", simulatorFrame, 0, 1)
	simulatorFrame.outlineText:SetText(L["NotPlater Simulator Frame"])
	simulatorFrame.outlineText:SetAlpha(0.3)
    --simulatorFrame.dragMeText = simulatorFrame:CreateFontString(nil, "ARTWORK")
	--simulatorFrame.dragMeText:SetFont(self.SML:Fetch(self.SML.MediaType.FONT, "Arial Narrow"), 10, "OUTLINE")
	--simulatorFrame.dragMeText:SetPoint("TOPLEFT", simulatorFrame, 1, -1)
	--simulatorFrame.dragMeText:SetText(L["Drag me"])
	--simulatorFrame.dragMeText:SetAlpha(0.3)
    simulatorFrame.dragMeTexture = simulatorFrame:CreateTexture(nil, "BORDER")
    simulatorFrame.dragMeTexture:SetTexture("Interface\\AddOns\\NotPlater\\images\\drag")
    self:SetSize(simulatorFrame.dragMeTexture, 16, 16)
    simulatorFrame.dragMeTexture:SetPoint("TOPLEFT", simulatorFrame, 7, -7)
    simulatorFrame.dragMeTexture:SetAlpha(0.3)
    simulatorFrame.defaultFrame = CreateFrame("Button", "NotPlaterSimulatorDefaultFrame", simulatorFrame)
    simulatorFrame.defaultFrame:EnableMouse(true)
    simulatorFrame.defaultFrame:RegisterForClicks("AnyDown")
    simulatorFrame.defaultFrame:SetScript("OnClick", function (self, mouseButton)
        if mouseButton == "LeftButton" or mouseButton == "RightButton" then
            if self.simulatedTarget then
                self.simulatedTarget = false
            else
                self.simulatedTarget = true
            end
        else --MiddleButton

        end
    end)
    self:SetSize(simulatorFrame.defaultFrame, 156.65, 39.16)
    simulatorFrame.defaultFrame:SetPoint("CENTER")
    simulatorFrame.defaultFrame.defaultHealthFrame = CreateFrame("StatusBar", "NotPlaterSimulatorHealthFrame", simulatorFrame.defaultFrame)
    simulatorFrame.defaultFrame.defaultHealthFrame:SetMinMaxValues(healthMin, healthMax)
    simulatorFrame.defaultFrame.nameText = simulatorFrame.defaultFrame:CreateFontString(nil, "ARTWORK")
    simulatorFrame.defaultFrame.levelText = simulatorFrame.defaultFrame:CreateFontString(nil, "ARTWORK")
    simulatorFrame.defaultFrame:SetScript("OnEnter", function(self)
        self.nameText:SetTextColor(1,0,0,1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["NotPlater Simulated Frame"])
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["|cffeda55fLeft-Click or Right-Click|r target/untarget the simulated frame"], 0.2, 1, 0.2)
        GameTooltip:Show()
    end)
    simulatorFrame.defaultFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.nameText:SetTextColor(1,1,1,1)
    end)

    -- Construct all components
    self:ConstructThreatComponents(simulatorFrame.defaultFrame.defaultHealthFrame)
    self:ConstructHealthBar(simulatorFrame.defaultFrame.defaultHealthFrame)
    self:ConstructCastBar(simulatorFrame.defaultFrame)
    self:ConstructTargetBorder(simulatorFrame.defaultFrame.defaultHealthFrame, simulatorFrame.defaultFrame)
    self:ConstructStacking(simulatorFrame.defaultFrame)
    simulatorFrame.defaultFrame.raidIcon = CreateFrame("Frame", nil, simulatorFrame.defaultFrame)
	simulatorFrame.defaultFrame.raidIcon.texture = simulatorFrame.defaultFrame.raidIcon:CreateTexture(nil, "BORDER")
	simulatorFrame.defaultFrame.raidIcon.texture:SetAllPoints()
    simulatorFrame.defaultFrame.bossIcon = CreateFrame("Frame", nil, simulatorFrame.defaultFrame)
	simulatorFrame.defaultFrame.bossIcon.texture = simulatorFrame.defaultFrame.bossIcon:CreateTexture(nil, "BORDER")
	simulatorFrame.defaultFrame.bossIcon.texture:SetAllPoints()

    ThreatSimulator:ConstructThreatScenario(6, 2, 2)
    simulatorFrame.defaultFrame.defaultHealthFrame.lastUnitMatch = 1

    simulatorFrame:Hide()
    self.simulatorFrame = simulatorFrame
end

-- this is free running mode for nameplate color change
--[[ 

if self.defaultFrame.defaultHealthFrame:GetValue() == 0 then
    self.defaultFrame.defaultHealthFrame:SetValue(healthMax)
else
    self.defaultFrame.defaultHealthFrame:SetValue(self.defaultFrame.defaultHealthFrame:GetValue() - 10)
end
local threatProfile = NotPlater.db.profile.threat
if threatProfile.nameplateColors.enabled then
    local nameplateColorsConfig = threatProfile.nameplateColors
    if threatProfile.general.mode == "hdps" then
        nameplateColors[1] =  nameplateColorsConfig.dpsHealerAggroOnYou
        nameplateColors[2] = nameplateColorsConfig.dpsHealerHighThreat
        nameplateColors[3] = nameplateColorsConfig.dpsHealerDefaultNoAggro
    else
        nameplateColors[1] =  nameplateColorsConfig.dpsHealerAggroOnYou
        nameplateColors[2] = nameplateColorsConfig.dpsHealerHighThreat
        nameplateColors[3] = nameplateColorsConfig.dpsHealerDefaultNoAggro
    end
end
if nameplateColorChange.elapsed > nameplateColorChange.interval then
    if #nameplateColors > nameplateColorChange.currentIndex then
        nameplateColorChange.currentIndex = nameplateColorChange.currentIndex + 1
    else
        nameplateColorChange.currentIndex = 1
    end
    nameplateColorChange.elapsed = 0
end
self.defaultFrame.defaultHealthFrame:SetStatusBarColor(NotPlater:GetColor(nameplateColors[nameplateColorChange.currentIndex]))
nameplateColorChange.elapsed = nameplateColorChange.elapsed + elapsed
]]