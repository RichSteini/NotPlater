if not NotPlater then
	return
end

local Tracker = NotPlater:CreateAuraTrackerBase()
Tracker.nonDiminishingCategories = {snare = true}
NotPlater.AuraTracker = Tracker

local DEFAULT_ICON = Tracker.defaultIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
local HUGE = math.huge

local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local UnitGUID = UnitGUID
local select = select

local auraApplyEvents = {	SPELL_AURA_APPLIED = "APPLIED",
	SPELL_AURA_REFRESH = "REFRESH",
	SPELL_AURA_APPLIED_DOSE = "APPLIED_DOSE",
}

local auraRemoveEvents = {	SPELL_AURA_REMOVED = "REMOVED",
	SPELL_AURA_REMOVED_DOSE = "REMOVED_DOSE",
	SPELL_AURA_DISPELLED = "DISPELLED",
	SPELL_AURA_STOLEN = "STOLEN",
	SPELL_AURA_BROKEN = "BROKEN",
	SPELL_AURA_BROKEN_SPELL = "BROKEN_SPELL",
}

local diminishingReturnsData = NotPlater.DiminishingReturnsSpells or {}

local function BuildAuraKey(spellID, casterGUID, isDebuff)
	return (spellID or 0) .. ":" .. (casterGUID or "0") .. ":" .. (isDebuff and "D" or "B")
end

local function CopyTable(source, seen)
	if not source then
		return nil
	end
	-- guard against self-referential tables causing recursive overflows
	if seen and seen[source] then
		return seen[source]
	end
	seen = seen or {}
	local target = {}
	seen[source] = target
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = CopyTable(value, seen)
		else
			target[key] = value
		end
	end
	return target
end

function Tracker:GetNameKey(name, isDebuff)
	local label = (name and name:lower()) or "unknown"
	return label .. ":" .. (isDebuff and "D" or "B")
end

function Tracker:GetKnownSpellID(name)
	if not name then
		return nil
	end
	self.spellNameToId = self.spellNameToId or {}
	return self.spellNameToId[name:lower()]
end

function Tracker:GetTemporarySpellID(name)
	if not name or name == "" then
		return 0
	end
	self.temporarySpellIds = self.temporarySpellIds or {}
	self.nextTemporarySpellId = self.nextTemporarySpellId or -1
	local key = name:lower()
	if not self.temporarySpellIds[key] then
		self.temporarySpellIds[key] = self.nextTemporarySpellId
		self.nextTemporarySpellId = self.nextTemporarySpellId - 1
	end
	return self.temporarySpellIds[key]
end

function Tracker:StoreAuraLogInfo(destGUID, spellID, spellName, isDebuff, casterGUID)
	if not destGUID or not spellID or not spellName then
		return
	end
	self.auraLogCache = self.auraLogCache or {}
	self.activeLogSpells = self.activeLogSpells or {}
	self.spellNameToId = self.spellNameToId or {}
	local key = self:GetNameKey(spellName, isDebuff)
	self.auraLogCache[destGUID] = self.auraLogCache[destGUID] or {}
	self.auraLogCache[destGUID][key] = {
		spellID = spellID,
		casterGUID = casterGUID,
	}
	self.activeLogSpells[destGUID] = self.activeLogSpells[destGUID] or {}
	self.activeLogSpells[destGUID][spellID] = key
	self.spellNameToId[spellName:lower()] = spellID
end

function Tracker:GetAuraLogInfo(destGUID, name, isDebuff)
	if not destGUID or not name or not self.auraLogCache then
		return nil
	end
	local cache = self.auraLogCache[destGUID]
	if not cache then
		return nil
	end
	return cache[self:GetNameKey(name, isDebuff)]
end

function Tracker:ClearAuraLogInfo(destGUID, spellID)
	if not destGUID or not spellID or not self.activeLogSpells then
		return
	end
	local active = self.activeLogSpells[destGUID]
	if not active then
		return
	end
	local nameKey = active[spellID]
	if nameKey then
		active[spellID] = nil
		local cache = self.auraLogCache and self.auraLogCache[destGUID]
		if cache then
			cache[nameKey] = nil
			if not next(cache) then
				self.auraLogCache[destGUID] = nil
			end
		end
	end
	if not next(active) then
		self.activeLogSpells[destGUID] = nil
	end
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
	local auraSources = {
		{func = UnitBuff, isDebuff = false},
		{func = UnitDebuff, isDebuff = true},
	}
	for _, source in ipairs(auraSources) do
		local index = 1
		while true do
			local name, rank, icon, count, dispelType, duration, timeLeft = source.func(unit, index)
			if not name then
				break
			end
			local isDebuff = source.isDebuff
			dispelType = isDebuff and dispelType or nil
			local logInfo = self:GetAuraLogInfo(guid, name, isDebuff)
			local spellID = logInfo and logInfo.spellID or self:GetKnownSpellID(name) or self:GetTemporarySpellID(name)
			local casterGUID = logInfo and logInfo.casterGUID or nil
			local key = BuildAuraKey(spellID, casterGUID, isDebuff)
			seen[key] = true
			local aura = entries[key] or {}
			aura.spellID = spellID
			aura.name = name
			aura.rank = rank
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
			local expirationTime
			if duration and duration > 0 then
				expirationTime = (timeLeft and timeLeft > 0) and (GetTime() + timeLeft) or (GetTime() + duration)
				aura.duration = duration
				aura.expirationTime = expirationTime
				aura.appliedAt = expirationTime - duration
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
	local allowSimulated = guid and self:IsSimulatedGUID(guid)
	if not self.enableCombatLogTracking and not unit and not allowSimulated then
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
	self:StoreAuraLogInfo(destGUID, spellID, spellName or name, isDebuff, srcGUID)
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
	self:ClearAuraLogInfo(destGUID, spellID)
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
