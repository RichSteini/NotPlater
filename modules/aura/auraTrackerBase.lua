if not NotPlater then
	return
end

if NotPlater.CreateAuraTrackerBase then
	return
end

local DEFAULT_FALLBACK_UNITS = {"target", "focus", "mouseover"}
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local HUGE = math.huge
local tinsert = table.insert
local bit_band = bit and bit.band
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo

local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_TYPE_PET = _G.COMBATLOG_OBJECT_TYPE_PET or 0x00001000
local COMBATLOG_OBJECT_TYPE_GUARDIAN = _G.COMBATLOG_OBJECT_TYPE_GUARDIAN or 0x00002000

local GUID_PREFIX_UNIT_TYPE = {
	[0x0000] = "player",
	[0xF100] = "dynamicobject",
	[0xF101] = "corpse",
	[0xF110] = "gameobject",
	[0xF130] = "creature",
	[0xF140] = "pet",
	[0xF150] = "vehicle",
}

local Base = {}

local function wipe(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

function Base:EnsureInit()
	if self.initialized then
		return
	end
	self.initialized = true
	self.guidAuras = {}
	self.pendingDurations = {}
	self.drStates = {}
	self.listeners = {}
	self.trackedUnitList = {}
	self.trackedUnitLookup = {}
	self.eventFrame = CreateFrame("Frame")
	self.eventFrame:SetScript("OnEvent", function(_, event, ...)
		if self[event] then
			self[event](self, ...)
		end
	end)
end

function Base:RegisterSimulatorGUID(guid)
	if not guid then
		return
	end
	self.simulatorGuids = self.simulatorGuids or {}
	self.simulatorGuids[guid] = true
end

function Base:UnregisterSimulatorGUID(guid)
	if not guid or not self.simulatorGuids then
		return
	end
	self.simulatorGuids[guid] = nil
end

function Base:IsSimulatedGUID(guid)
	if not guid or not self.simulatorGuids then
		return false
	end
	return self.simulatorGuids[guid] and true or false
end

function Base:RegisterListener(listener)
	if not listener then
		return
	end
	self.listeners[listener] = true
end

function Base:UnregisterListener(listener)
	if not listener then
		return
	end
	self.listeners[listener] = nil
end

function Base:NotifyListeners(guid)
	self.notifyQueue = self.notifyQueue or {}
	self.notifyPending = self.notifyPending or {}
	local key = guid or "__ALL__"
	if not self.notifyPending[key] then
		self.notifyPending[key] = true
		tinsert(self.notifyQueue, guid)
	end
	if self.notifying then
		return
	end
	self.notifying = true
	while #self.notifyQueue > 0 do
		local nextGuid = table.remove(self.notifyQueue, 1)
		local nextKey = nextGuid or "__ALL__"
		self.notifyPending[nextKey] = nil
		for listener in pairs(self.listeners) do
			if listener.OnAuraTrackerUpdate then
				listener:OnAuraTrackerUpdate(nextGuid)
			end
		end
	end
	self.notifying = false
end

function Base:IsPlayerGUID(guid)
	if not guid then
		return false
	end
	return self:GetUnitTypeFromGUID(guid) == "player"
end

function Base:GetUnitTypeFromGUID(guid)
	if not guid then
		return "unknown"
	end
	local prefix = guid:match("^0[xX](%x%x%x%x)") or guid:match("^(%x%x%x%x)")
	if prefix then
		local unitType = GUID_PREFIX_UNIT_TYPE[tonumber(prefix, 16)]
		if unitType then
			if unitType == "pet" or unitType == "vehicle" then
				return "pet"
			end
			if unitType == "player" then
				return "player"
			end
			return "npc"
		end
	end
	return "unknown"
end

function Base:GetUnitTypeFromFlags(flags)
	if not flags or not bit_band then
		return "unknown"
	end
	if bit_band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then
		return "player"
	end
	if bit_band(flags, COMBATLOG_OBJECT_TYPE_PET + COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
		return "pet"
	end
	return "npc"
end

function Base:SetTrackedUnits(stateTable)
	wipe(self.trackedUnitList)
	wipe(self.trackedUnitLookup)
	local hasSelection = false
	local arenaAdded = false
	local legacyArena = false
	local fallbackUnits = self.defaultTrackedUnits or DEFAULT_FALLBACK_UNITS
	local function addUnit(unit)
		if not unit or unit == "" then
			return
		end
		if not self.trackedUnitLookup[unit] then
			self.trackedUnitLookup[unit] = true
			tinsert(self.trackedUnitList, unit)
		end
		hasSelection = true
	end
	local function addArenaUnits()
		if arenaAdded then
			return
		end
		arenaAdded = true
		for i = 1, 5 do
			addUnit("arena" .. i)
		end
	end
	if type(stateTable) == "table" then
		for unit, enabled in pairs(stateTable) do
			if enabled then
				if unit == "arena" then
					addArenaUnits()
				elseif unit and unit:match("^arena%d$") then
					addArenaUnits()
					legacyArena = true
				else
					addUnit(unit)
				end
			end
		end
	end
	if legacyArena and stateTable then
		stateTable.arena = true
		for i = 1, 5 do
			stateTable["arena" .. i] = nil
		end
	end
	if hasSelection then
		return
	end
	for _, unit in ipairs(fallbackUnits) do
		addUnit(unit)
	end
end

function Base:IsTrackedUnit(unit)
	return self.trackedUnitLookup[unit] == true
end

function Base:Enable()
	self:EnsureInit()
	if self.enabled then
		self:ApplySettings()
		return
	end
	self.enabled = true
	self:ApplySettings()
end

function Base:Disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	self:UnregisterCombatLog()
end

function Base:RegisterCombatLog()
	if self.combatLogRegistered or not self.eventFrame then
		return
	end
	self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.combatLogRegistered = true
end

function Base:UnregisterCombatLog()
	if not self.combatLogRegistered or not self.eventFrame then
		return
	end
	self.eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.combatLogRegistered = false
end

function Base:ApplySettings()
	if not NotPlater or not NotPlater.db or not NotPlater.db.profile then
		return
	end
	local profile = NotPlater.db.profile
	local buffs = profile.buffs or {}
	self.buffsConfig = buffs
	self.generalConfig = buffs.general or {}
	self.trackingConfig = buffs.tracking or {}
	self.trackingConfig.units = self.trackingConfig.units or {}
	self.trackingConfig.learnedDurations = self.trackingConfig.learnedDurations or {}
	self.learnedDurations = self.trackingConfig.learnedDurations
	self.enableCombatLogTracking = self.generalConfig.enableCombatLogTracking ~= false
	self:SetTrackedUnits(self.trackingConfig.units)
	if self.enableCombatLogTracking then
		self:RegisterCombatLog()
	else
		self:UnregisterCombatLog()
		self:ClearLogOnlyAuras()
	end
end

function Base:ClearLogOnlyAuras()
	for guid, spells in pairs(self.guidAuras) do
		for key, aura in pairs(spells) do
			if aura.source == "LOG" then
				spells[key] = nil
			end
		end
		if not next(spells) then
			self.guidAuras[guid] = nil
		end
	end
	self.pendingDurations = {}
end

function Base:GetDurationKey(spellID, sourceType, targetType)
	return string.format("%s:%s:%s", spellID or 0, sourceType or "unknown", targetType or "unknown")
end

function Base:GetLearnedDuration(spellID, sourceType, targetType)
	if not self.learnedDurations then
		return nil
	end
	local key = self:GetDurationKey(spellID, sourceType, targetType)
	local entry = self.learnedDurations[key]
	if entry and entry.duration and entry.samples and entry.samples > 0 then
		return entry.duration, entry.samples
	end
	return nil
end

function Base:LearnDuration(spellID, sourceType, targetType, observed)
	if not spellID or not observed or observed <= 0 then
		return false
	end
	if not self.learnedDurations then
		self.learnedDurations = {}
	end
	local key = self:GetDurationKey(spellID, sourceType, targetType)
	local entry = self.learnedDurations[key]
	if not entry then
		self.learnedDurations[key] = {
			duration = observed,
			samples = 1,
		}
		return true
	end
	local previous = entry.duration or observed
	local delta = math.abs(previous - observed)
	entry.duration = previous + (observed - previous) * 0.35
	entry.samples = math.min((entry.samples or 1) + 1, 50)
	return delta > 0.15
end

function Base:GetDiminishingReturnState(guid, drType)
	if not drType or (self.nonDiminishingCategories and self.nonDiminishingCategories[drType]) then
		return nil
	end
	local guidState = self.drStates[guid]
	if not guidState then
		guidState = {}
		self.drStates[guid] = guidState
	end
	local now = GetTime()
	local state = guidState[drType]
	if not state or (state.resetAt and state.resetAt <= now) then
		state = {count = 0}
		guidState[drType] = state
	end
	return state
end

function Base:GetDiminishingReturnFactor(guid, drType)
	if not drType or (self.nonDiminishingCategories and self.nonDiminishingCategories[drType]) then
		return 1
	end
	local state = self:GetDiminishingReturnState(guid, drType)
	if not state then
		return 1
	end
	state.count = (state.count or 0) + 1
	if state.count == 1 then
		state.diminished = 1
	elseif state.count == 2 then
		state.diminished = 0.5
	elseif state.count == 3 then
		state.diminished = 0.25
	else
		state.diminished = 0
	end
	return state.diminished
end

function Base:OnDiminishingReturnRemoved(guid, drType)
	if not guid or not drType or (self.nonDiminishingCategories and self.nonDiminishingCategories[drType]) then
		return
	end
	local guidState = self.drStates[guid]
	if not guidState then
		return
	end
	local state = guidState[drType]
	if state then
		state.resetAt = GetTime() + (self.drResetTime or 18)
	end
end

function Base:SnapshotAura(targetTable, aura)
	targetTable = targetTable or {}
	for key, value in pairs(aura) do
		targetTable[key] = value
	end
	return targetTable
end

function NotPlater:CreateAuraTrackerBase()
	local tracker = {}
	for key, func in pairs(Base) do
		tracker[key] = func
	end
	tracker.defaultTrackedUnits = DEFAULT_FALLBACK_UNITS
	tracker.defaultIcon = DEFAULT_ICON
	tracker.huge = HUGE
	tracker.GetTime = GetTime
	tracker.GetSpellInfo = GetSpellInfo
	tracker.drResetTime = 18
	return tracker
end
