if not NotPlater then return end

local ipairs = ipairs
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsPlayer = UnitIsPlayer
local UnitLevel = UnitLevel
local UnitName = UnitName

local DEFAULT_TRACKED_UNITS = {"target", "focus", "mouseover"}

local function ReleaseFrameMatch(self, frame)
	if not frame then
		return
	end
	local unit = frame.lastUnitMatch
	local guid = frame.lastGuidMatch
	if unit and self.matchUnitToFrame and self.matchUnitToFrame[unit] == frame then
		self.matchUnitToFrame[unit] = nil
	end
	if guid and self.matchGuidToFrame and self.matchGuidToFrame[guid] == frame then
		self.matchGuidToFrame[guid] = nil
	end
end

function NotPlater:SetTrackedMatchUnits(units)
	self.trackedMatchUnits = {}
	self.matchUnitToFrame = {}
	self.matchGuidToFrame = {}
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

function NotPlater:IsTrackedMatchUnit(unit)
	if not unit then
		return false
	end
	for _, tracked in ipairs(self:GetTrackedMatchUnits()) do
		if unit == tracked then
			return true
		end
	end
	return false
end

function NotPlater:PlateMatchesUnit(frame, unit)
	if not unit or not UnitExists(unit) then
		return false
	end
	if not frame or not frame.healthBar then
		return false
	end
	if UnitIsDeadOrGhost(unit) then
		return false
	end
	local nameText, levelText = frame and frame.defaultNameText or nil, nil
	if not nameText or not levelText then
		nameText, levelText = NotPlater:GetFrameTexts(frame)
	end
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
		local _, healthMaxValue = healthBar:GetMinMaxValues()
		if healthValue ~= UnitHealth(unit) then
			return false
		end

		if not UnitIsPlayer(unit) and healthValue == healthMaxValue then
			return false
		end
	end
	return true
end

function NotPlater:ClearFrameMatch(frame, keepGuid)
	if not frame then
		return
	end
	ReleaseFrameMatch(self, frame)
	frame.lastUnitMatch = nil
	if not keepGuid then
		frame.lastGuidMatch = nil
	end
end

function NotPlater:SetFrameMatch(frame, unit)
	if not frame then
		return
	end
	self.matchUnitToFrame = self.matchUnitToFrame or {}
	self.matchGuidToFrame = self.matchGuidToFrame or {}
	local guid = unit and UnitGUID(unit) or nil
	if frame.lastUnitMatch == unit and frame.lastGuidMatch == guid then
		return true
	end
	ReleaseFrameMatch(self, frame)
	if unit then
		local claimedFrame = self.matchUnitToFrame[unit]
		if claimedFrame and claimedFrame ~= frame and claimedFrame:IsShown() and self:PlateMatchesUnit(claimedFrame, unit) then
			return false
		end
		if guid then
			local claimedGuidFrame = self.matchGuidToFrame[guid]
			if claimedGuidFrame and claimedGuidFrame ~= frame and claimedGuidFrame:IsShown() and self:PlateMatchesUnit(claimedGuidFrame, unit) then
				return false
			end
		end
	end
	frame.lastUnitMatch = unit
	frame.lastGuidMatch = guid
	if unit then
		self.matchUnitToFrame[unit] = frame
	end
	if guid then
		self.matchGuidToFrame[guid] = frame
	end
	return true
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
	if match then
		if not self:SetFrameMatch(frame, match) then
			self:ClearFrameMatch(frame, true)
		end
	else
		self:ClearFrameMatch(frame, true)
	end
end

function NotPlater:GetMatchedFrameForUnit(unit)
	if not unit then
		return nil
	end
	local frames = self.frames
	if not frames then
		return nil
	end
	for frame in pairs(frames) do
		if frame:IsShown() and self:PlateMatchesUnit(frame, unit) then
			return frame
		end
	end
	return nil
end

function NotPlater:MatchTrackerOnShow(frame)
	self:ClearFrameMatch(frame)
	self:UpdateFrameMatch(frame)
end

function NotPlater:MatchTrackerOnHide(frame)
	self:ClearFrameMatch(frame)
end

function NotPlater:PLAYER_TARGET_CHANGED()
	local frames = self.frames
	if not frames then
		return
	end
	for frame in pairs(frames) do
		if frame.lastUnitMatch == "target" then
			self:ClearFrameMatch(frame)
		end
		frame.targetChanged = true
	end
end

function NotPlater:PLAYER_FOCUS_CHANGED()
	if self.lastFocusFrame and self.lastFocusFrame.lastUnitMatch == "focus" then
		self:ClearFrameMatch(self.lastFocusFrame)
		self.lastFocusFrame = nil
	end

	if not UnitExists("focus") then
		return
	end

	local frame = self:GetMatchedFrameForUnit("focus")
	if frame and frame.lastUnitMatch ~= "target" then
		self:SetFrameMatch(frame, "focus")
		self.lastFocusFrame = frame
	end
end

function NotPlater:UPDATE_MOUSEOVER_UNIT()
	if self.lastMouseoverFrame and self.lastMouseoverFrame.lastUnitMatch == "mouseover" then
		self:ClearFrameMatch(self.lastMouseoverFrame)
		self.lastMouseoverFrame = nil
	end

	local mouseoverGuid = UnitGUID("mouseover")
	if not mouseoverGuid then
		return
	end

	local frame = self:GetMatchedFrameForUnit("mouseover")
	if not frame then
		local targetGuid = UnitGUID("target")
		if targetGuid and mouseoverGuid == targetGuid then
			frame = self:GetMatchedFrameForUnit("target")
		end
	end
	if frame then
		if frame.lastUnitMatch ~= "target" and frame.lastUnitMatch ~= "focus" then
			self:SetFrameMatch(frame, "mouseover")
			self.lastMouseoverFrame = frame
		end
		self:MouseoverThreatCheck(frame.healthBar, mouseoverGuid)
	end
end
