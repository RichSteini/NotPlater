if not NotPlater then
	return
end

local Tracker = {}
NotPlater.AuraTracker = Tracker

local DEFAULT_TRACKED_UNITS = {"target", "focus", "mouseover"}
local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local HUGE = math.huge

local wipe = wipe
local tinsert = table.insert
local bit_band = bit and bit.band
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitAura = UnitAura
local UnitGUID = UnitGUID
local select = select

local COMBATLOG_OBJECT_TYPE_PLAYER = _G.COMBATLOG_OBJECT_TYPE_PLAYER or 0x00000400
local COMBATLOG_OBJECT_TYPE_PET = _G.COMBATLOG_OBJECT_TYPE_PET or 0x00001000
local COMBATLOG_OBJECT_TYPE_GUARDIAN = _G.COMBATLOG_OBJECT_TYPE_GUARDIAN or 0x00002000

local auraApplyEvents = {
	SPELL_AURA_APPLIED = "APPLIED",
	SPELL_AURA_REFRESH = "REFRESH",
	SPELL_AURA_APPLIED_DOSE = "APPLIED_DOSE",
}

local auraRemoveEvents = {
	SPELL_AURA_REMOVED = "REMOVED",
	SPELL_AURA_REMOVED_DOSE = "REMOVED_DOSE",
	SPELL_AURA_DISPELLED = "DISPELLED",
	SPELL_AURA_STOLEN = "STOLEN",
	SPELL_AURA_BROKEN = "BROKEN",
	SPELL_AURA_BROKEN_SPELL = "BROKEN_SPELL",
}

local diminishingReturnsData = NotPlater.DiminishingReturnsSpells or {}

local DR_RESET_TIME = 18 -- matches LibAuraInfo reset timer

local function BuildAuraKey(spellID, casterGUID, isDebuff)
	return (spellID or 0) .. ":" .. (casterGUID or "0") .. ":" .. (isDebuff and "D" or "B")
end
local function CopyTable(source)
	if not source then
		return nil
	end
	local target = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = CopyTable(value)
		else
			target[key] = value
		end
	end
	return target
end

function Tracker:EnsureInit()
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

function Tracker:RegisterListener(listener)
	if not listener then
		return
	end
	self.listeners[listener] = true
end

function Tracker:UnregisterListener(listener)
	if not listener then
		return
	end
	self.listeners[listener] = nil
end

function Tracker:NotifyListeners(guid)
	for listener in pairs(self.listeners) do
		if listener.OnAuraTrackerUpdate then
			listener:OnAuraTrackerUpdate(guid)
		end
	end
end

function Tracker:IsPlayerGUID(guid)
	if not guid then
		return false
	end
	return guid:find("^Player%-") ~= nil
end

function Tracker:GetUnitTypeFromGUID(guid)
	if not guid then
		return "unknown"
	end
	if guid:find("^Player%-") then
		return "player"
	end
	if guid:find("^Pet%-") or guid:find("^Vehicle%-") then
		return "pet"
	end
	return "npc"
end

function Tracker:GetUnitTypeFromFlags(flags)
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

function Tracker:SetTrackedUnits(stateTable)
	wipe(self.trackedUnitList)
	wipe(self.trackedUnitLookup)
	local hasSelection = false
	local arenaAdded = false
	local legacyArena = false
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
	if not hasSelection then
		for _, unit in ipairs(DEFAULT_TRACKED_UNITS) do
			addUnit(unit)
			if stateTable then
				stateTable[unit] = true
			end
		end
	end
	if NotPlater and NotPlater.SetTrackedMatchUnits then
		NotPlater:SetTrackedMatchUnits(CopyTable(self.trackedUnitList))
	end
end

function Tracker:IsTrackedUnit(unit)
	return self.trackedUnitLookup[unit] == true
end

function Tracker:Enable()
	self:EnsureInit()
	if self.enabled then
		self:ApplySettings()
		return
	end
	self.enabled = true
	self:ApplySettings()
end

function Tracker:Disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	self:UnregisterCombatLog()
end

function Tracker:RegisterCombatLog()
	if self.combatLogRegistered then
		return
	end
	if not self.eventFrame then
		return
	end
	self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.combatLogRegistered = true
end

function Tracker:UnregisterCombatLog()
	if not self.combatLogRegistered or not self.eventFrame then
		return
	end
	self.eventFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.combatLogRegistered = false
end

function Tracker:ApplySettings()
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

function Tracker:ClearLogOnlyAuras()
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

function Tracker:GetDurationKey(spellID, sourceType, targetType)
	return string.format("%d:%s:%s", spellID or 0, sourceType or "unknown", targetType or "unknown")
end

function Tracker:GetLearnedDuration(spellID, sourceType, targetType)
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

function Tracker:LearnDuration(spellID, sourceType, targetType, observed)
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

function Tracker:GetDiminishingReturnState(guid, drType)
	if not drType or not guid then
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

function Tracker:GetDiminishingReturnFactor(guid, drType)
	if not drType then
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

function Tracker:OnDiminishingReturnRemoved(guid, drType)
	if not guid or not drType then
		return
	end
	local guidState = self.drStates[guid]
	if not guidState then
		return
	end
	local state = guidState[drType]
	if state then
		state.resetAt = GetTime() + DR_RESET_TIME
	end
end

function Tracker:SnapshotAura(targetTable, aura)
	targetTable = targetTable or {}
	for key, value in pairs(aura) do
		targetTable[key] = value
	end
	return targetTable
end

function Tracker:UpdateGuidAurasFromUnit(unit, guid, results, lookup)
	if not unit or not guid or not self:IsTrackedUnit(unit) then
		return
	end
	local entries = self.guidAuras[guid]
	if not entries then
		entries = {}
		self.guidAuras[guid] = entries
	end
	local seen = {}
	for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
		local index = 1
		while true do
			local name, _, icon, count, dispelType, duration, expirationTime, unitCaster, _, _, spellID = UnitAura(unit, index, filter)
			if not name or not spellID then
				break
			end
			local isDebuff = filter == "HARMFUL"
			local casterGUID = unitCaster and UnitGUID(unitCaster) or nil
			local key = BuildAuraKey(spellID, casterGUID, isDebuff)
			seen[key] = true
			local aura = entries[key] or {}
			aura.spellID = spellID
			aura.name = name
			aura.icon = icon or select(3, GetSpellInfo(spellID)) or DEFAULT_ICON
			aura.count = count or 0
			aura.dispelType = dispelType
			aura.isDebuff = isDebuff
			aura.isBuff = not isDebuff
			aura.casterGUID = casterGUID
			aura.targetGUID = guid
			aura.drType = diminishingReturnsData[spellID]
			aura.isCrowdControl = aura.drType and aura.isDebuff or false
			aura.sourceType = self:GetUnitTypeFromGUID(casterGUID)
			aura.targetType = self:GetUnitTypeFromGUID(guid)
			aura.source = "UNIT"
			aura.sourceIsPlayer = self:IsPlayerGUID(casterGUID)
			if duration and duration > 0 then
				aura.duration = duration
				aura.expirationTime = expirationTime and expirationTime > 0 and expirationTime or (GetTime() + duration)
				aura.appliedAt = aura.expirationTime - duration
				local learnedUpdated = self:LearnDuration(spellID, aura.sourceType, aura.targetType, duration)
				if learnedUpdated then
					self:ApplyLearnedDurationToActive(spellID, aura.sourceType, aura.targetType)
				end
			else
				aura.duration = nil
				aura.expirationTime = HUGE
				aura.appliedAt = GetTime()
			end
			entries[key] = aura
			local copy = CopyTable(aura)
			results[#results + 1] = copy
			if lookup then
				lookup[key] = copy
			end
			index = index + 1
		end
	end
	for key, aura in pairs(entries) do
		if aura.source == "UNIT" and not seen[key] then
			if aura.drType then
				self:OnDiminishingReturnRemoved(guid, aura.drType)
			end
			entries[key] = nil
		end
	end
	if not next(entries) then
		self.guidAuras[guid] = nil
	end
end

function Tracker:CollectFromGuid(guid, results, lookup)
	if not guid then
		return
	end
	local entries = self.guidAuras[guid]
	if not entries then
		return
	end
	local now = GetTime()
	for key, aura in pairs(entries) do
		if aura.expirationTime and aura.expirationTime ~= HUGE and aura.expirationTime <= now then
			entries[key] = nil
		else
			if lookup and lookup[key] then
				-- prefer direct unit data that already populated lookup
			else
				results[#results + 1] = CopyTable(aura)
			end
		end
	end
	if not next(entries) then
		self.guidAuras[guid] = nil
	end
end

function Tracker:CollectAuras(unit, guid)
	if not self.enableCombatLogTracking and not unit then
		if guid then
			self.guidAuras[guid] = nil
			self.pendingDurations[guid] = nil
		end
		return nil
	end
	local results = {}
	local lookup = {}
	if unit and guid then
		self:UpdateGuidAurasFromUnit(unit, guid, results, lookup)
	end
	if guid then
		self:CollectFromGuid(guid, results, lookup)
	end
	if #results == 0 then
		return nil
	end
	return results
end

function Tracker:ApplyLearnedDurationToActive(spellID, sourceType, targetType)
	local learned = self:GetLearnedDuration(spellID, sourceType, targetType)
	if not learned then
		return
	end
	local updatedGuids = {}
	for guid, spells in pairs(self.guidAuras) do
		for _, aura in pairs(spells) do
			if aura.spellID == spellID and aura.sourceType == sourceType and aura.targetType == targetType and aura.appliedAt then
				if aura.drFactor then
					aura.duration = learned * aura.drFactor
				else
					aura.duration = learned
				end
				if aura.duration and aura.duration > 0 then
					aura.expirationTime = aura.appliedAt + aura.duration
				end
				updatedGuids[guid] = true
			end
		end
	end
	for guid in pairs(updatedGuids) do
		self:NotifyListeners(guid)
	end
end

function Tracker:UpdateAuraFromLog(destGUID, key, data)
	if not destGUID or not key then
		return nil
	end
	local entries = self.guidAuras[destGUID]
	if not entries then
		entries = {}
		self.guidAuras[destGUID] = entries
	end
	local aura = entries[key]
	if not aura then
		aura = {}
		entries[key] = aura
	end
	for field, value in pairs(data) do
		aura[field] = value
	end
	return aura
end

function Tracker:HandleAuraApplied(eventType, srcGUID, srcFlags, destGUID, destFlags, spellID, spellName, auraType, stackCount)
	if not destGUID or not spellID then
		return
	end
	local now = GetTime()
	local isDebuff = auraType == "DEBUFF"
	local key = BuildAuraKey(spellID, srcGUID, isDebuff)
	local drType = diminishingReturnsData[spellID]
	local drFactor = self:GetDiminishingReturnFactor(destGUID, drType)
	local sourceType = self:GetUnitTypeFromGUID(srcGUID) or self:GetUnitTypeFromFlags(srcFlags)
	local targetType = self:GetUnitTypeFromGUID(destGUID) or self:GetUnitTypeFromFlags(destFlags)
	local learnedDuration = self:GetLearnedDuration(spellID, sourceType, targetType)
	local duration = nil
	if learnedDuration and drFactor > 0 then
		duration = learnedDuration * drFactor
	end
	local expiration = duration and (now + duration) or HUGE
	local name, _, icon = GetSpellInfo(spellID)
	local auraData = {
		spellID = spellID,
		name = spellName or name,
		icon = icon or DEFAULT_ICON,
		count = stackCount or 0,
		dispelType = nil,
		isDebuff = isDebuff,
		isBuff = not isDebuff,
		casterGUID = srcGUID,
		targetGUID = destGUID,
		duration = duration,
		expirationTime = expiration,
		appliedAt = now,
		source = "LOG",
		sourceType = sourceType,
		targetType = targetType,
		sourceIsPlayer = self:IsPlayerGUID(srcGUID),
		drType = drType,
		drFactor = drFactor ~= 1 and drFactor or nil,
		isCrowdControl = drType and isDebuff or false,
	}
	local aura = self:UpdateAuraFromLog(destGUID, key, auraData)
	self.pendingDurations[destGUID] = self.pendingDurations[destGUID] or {}
	self.pendingDurations[destGUID][key] = {
		startTime = now,
		sourceType = sourceType,
		targetType = targetType,
		drFactor = drFactor,
	}
	self:NotifyListeners(destGUID)
	return aura
end

function Tracker:HandleAuraDose(destGUID, key, stackCount)
	if not destGUID or not key then
		return
	end
	local entries = self.guidAuras[destGUID]
	if not entries then
		return
	end
	local aura = entries[key]
	if not aura then
		return
	end
	aura.count = stackCount or aura.count or 0
	self:NotifyListeners(destGUID)
end

function Tracker:HandleAuraRemoved(eventType, destGUID, key, spellID, drType, stackCount, forced)
	if not destGUID or not key then
		return
	end
	local entries = self.guidAuras[destGUID]
	if not entries then
		entries = {}
	end
	if eventType == "REMOVED_DOSE" then
		self:HandleAuraDose(destGUID, key, stackCount)
		return
	end
	local pendingGuid = self.pendingDurations[destGUID]
	local pending = pendingGuid and pendingGuid[key]
	if pending then
		if not forced then
			local now = GetTime()
			local elapsed = now - (pending.startTime or now)
			local base = elapsed
			if pending.drFactor and pending.drFactor > 0 and pending.drFactor ~= 1 then
				base = elapsed / pending.drFactor
			end
			if base > 0.2 then
				local updated = self:LearnDuration(spellID, pending.sourceType, pending.targetType, base)
				if updated then
					self:ApplyLearnedDurationToActive(spellID, pending.sourceType, pending.targetType)
				end
			end
		end
		pendingGuid[key] = nil
		if not next(pendingGuid) then
			self.pendingDurations[destGUID] = nil
		end
	end
	if entries[key] then
		entries[key] = nil
		if not next(entries) then
			self.guidAuras[destGUID] = nil
		end
	end
	if drType then
		self:OnDiminishingReturnRemoved(destGUID, drType)
	end
	self:NotifyListeners(destGUID)
end

function Tracker:COMBAT_LOG_EVENT_UNFILTERED(...)
	if not self.enableCombatLogTracking then
		return
	end
	local timestamp, subEvent, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags,
		destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool,
		auraType, amount
	if CombatLogGetCurrentEventInfo then
		timestamp, subEvent, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags,
			destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool,
			auraType, amount = CombatLogGetCurrentEventInfo()
	else
		timestamp, subEvent, srcGUID, srcName, srcFlags, destGUID, destName, destFlags,
			spellID, spellName, spellSchool, auraType, amount = ...
		hideCaster = false
		srcRaidFlags = nil
		destRaidFlags = nil
	end

	if auraApplyEvents[subEvent] then
		if subEvent == "SPELL_AURA_APPLIED_DOSE" then
			local isDebuff = auraType == "DEBUFF"
			local key = BuildAuraKey(spellID, srcGUID, isDebuff)
			self:HandleAuraDose(destGUID, key, amount)
		else
			local stack = (subEvent == "SPELL_AURA_APPLIED_DOSE") and amount or 0
			self:HandleAuraApplied(subEvent, srcGUID, srcFlags, destGUID, destFlags, spellID, spellName, auraType, stack)
		end
		return
	end

	local removalType = auraRemoveEvents[subEvent]
	if removalType then
		local isDebuff = auraType == "DEBUFF"
		local key = BuildAuraKey(spellID, srcGUID, isDebuff)
		local forced = removalType ~= "REMOVED" and removalType ~= "REMOVED_DOSE"
		local drType = diminishingReturnsData[spellID]
		self:HandleAuraRemoved(removalType, destGUID, key, spellID, drType, amount, forced)
	end
end
