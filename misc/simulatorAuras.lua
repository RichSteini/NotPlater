if not NotPlater then return end

local SimulatorAuras = {}
NotPlater.SimulatorAuras = SimulatorAuras

local random = math.random
local floor = math.floor
local max = math.max
local min = math.min
local GetTime = GetTime
local UnitGUID = UnitGUID
local CopyTable = CopyTable
local select = select
local wipe = wipe or function(tbl)
	for key in pairs(tbl) do
		tbl[key] = nil
	end
end

local UPDATE_INTERVAL = 0.25
local DEFAULT_DURATION_RANGE = {8, 16}
local NO_DURATION_FALLBACK = 20
local MAX_PER_FRAME = 10
local MAX_TOTAL = 10

local GUID_PREFIX = "Creature-0-0-0-0-90000-"
local SOURCE_PLAYER_GUID = "Player-0-0-0-0-90000-1"
local SOURCE_NPC_GUID = "Creature-0-0-0-0-90000-2"
local SOURCE_PET_GUID = "Pet-0-0-0-0-90000-3"

local auraPool = {
	buff = {
		{
			spellID = 900001,
			name = "Sim: Enrage",
			icon = "Interface\\Icons\\Ability_Druid_ChallangingRoar",
			duration = {8, 12},
			source = "self",
			enrage = true,
		},
		{
			spellID = 900002,
			name = "Sim: Arcane Shielding",
			icon = "Interface\\Icons\\Spell_Arcane_ArcaneResilience",
			duration = {12, 18},
			dispelType = "Magic",
			source = "npc",
		},
		{
			spellID = 900003,
			name = "Sim: Shadow Barrier",
			icon = "Interface\\Icons\\Spell_Shadow_AntiShadow",
			duration = {10, 14},
			dispelType = "Magic",
			source = "npc",
		},
		{
			spellID = 900004,
			name = "Sim: Blood Frenzy",
			icon = "Interface\\Icons\\Ability_Racial_BloodRage",
			duration = {6, 9},
			source = "player",
		},
		{
			spellID = 900005,
			name = "Sim: Stone Bark",
			icon = "Interface\\Icons\\Spell_Nature_SkinofEarth",
			fallbackDuration = 18,
			source = "self",
		},
	},
	debuff = {
		{
			spellID = 910001,
			name = "Sim: Sundering Strike",
			icon = "Interface\\Icons\\Ability_Warrior_Sunder",
			duration = {15, 18},
			source = "player",
		},
		{
			spellID = 910002,
			name = "Sim: Shadow Word: Pain",
			icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
			duration = {10, 16},
			dispelType = "Magic",
			source = "player",
		},
		{
			spellID = 910003,
			name = "Sim: Poisoned Spear",
			icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath",
			duration = {12, 15},
			dispelType = "Poison",
			source = "npc",
		},
		{
			spellID = 910004,
			name = "Sim: Curse of Exhaustion",
			icon = "Interface\\Icons\\Spell_Shadow_GrimWard",
			duration = {18, 22},
			dispelType = "Curse",
			source = "npc",
		},
		{
			spellID = 910005,
			name = "Sim: Frozen Prison",
			icon = "Interface\\Icons\\Spell_Frost_FrostNova",
			duration = {5, 7},
			dispelType = "Magic",
			source = "player",
			crowdControl = true,
		},
		{
			spellID = 910006,
			name = "Sim: Mortal Wound",
			icon = "Interface\\Icons\\Ability_CriticalStrike",
			fallbackDuration = 20,
			source = "player",
		},
	},
}

local function copyTable(tbl)
	if CopyTable then
		return CopyTable(tbl)
	end
	local newTbl = {}
	for key, value in pairs(tbl) do
		if type(value) == "table" then
			newTbl[key] = copyTable(value)
		else
			newTbl[key] = value
		end
	end
	return newTbl
end

local guidCounter = 0
local function GenerateGuid()
	guidCounter = guidCounter + 1
	return GUID_PREFIX .. tostring(90000 + guidCounter)
end

local function GetConfig()
	if not NotPlater or not NotPlater.db or not NotPlater.db.profile then
		return nil
	end
	return NotPlater.db.profile.buffs
end

local function clampCount(value)
	value = value or 6
	value = max(1, value)
	return min(MAX_PER_FRAME, value)
end

local function applyTotalLimit(buffCount, debuffCount)
	local total = (buffCount or 0) + (debuffCount or 0)
	if total <= MAX_TOTAL then
		return buffCount, debuffCount
	end
	if total == 0 then
		return 0, 0
	end
	if not buffCount or buffCount <= 0 then
		return 0, min(MAX_TOTAL, debuffCount or 0)
	end
	if not debuffCount or debuffCount <= 0 then
		return min(MAX_TOTAL, buffCount), 0
	end
	local ratio = buffCount / total
	local newBuffs = max(1, min(MAX_TOTAL - 1, floor(MAX_TOTAL * ratio + 0.5)))
	local newDebuffs = MAX_TOTAL - newBuffs
	return newBuffs, newDebuffs
end

function SimulatorAuras:GenerateWaveTargets(desiredBuffs, desiredDebuffs)
	local function pickTarget(desired)
		if desired <= 0 then
			return 0
		end
		local minValue = math.max(0, desired - 3)
		if minValue > desired then
			minValue = desired
		end
		return random(minValue, desired)
	end
	local buffTarget = pickTarget(desiredBuffs)
	local debuffTarget = pickTarget(desiredDebuffs)
	buffTarget = math.min(buffTarget, desiredBuffs)
	debuffTarget = math.min(debuffTarget, desiredDebuffs)
	buffTarget, debuffTarget = applyTotalLimit(buffTarget, debuffTarget)
	if buffTarget + debuffTarget == 0 and (desiredBuffs + desiredDebuffs) > 0 then
		if desiredBuffs >= desiredDebuffs and desiredBuffs > 0 then
			buffTarget = 1
		elseif desiredDebuffs > 0 then
			debuffTarget = 1
		end
	end
	return buffTarget, debuffTarget
end

function SimulatorAuras:AttachFrame(frame)
	if not frame then
		return
	end
	self.frame = frame
	self.guid = self.guid or GenerateGuid()
	frame.npSimulatedAuras = true
	local auraModule = NotPlater.GetAuraModule and NotPlater:GetAuraModule()
	if auraModule and auraModule.SetFrameGUID then
		auraModule:SetFrameGUID(frame, self.guid)
	else
		frame.npGUID = self.guid
	end
end

function SimulatorAuras:UpdateTrackerRegistration(active)
	if not self.guid then
		return
	end
	local tracker = NotPlater and NotPlater.AuraTracker
	if not tracker then
		return
	end
	if active then
		if tracker.RegisterSimulatorGUID then
			tracker:RegisterSimulatorGUID(self.guid)
		end
	else
		if tracker.UnregisterSimulatorGUID then
			tracker:UnregisterSimulatorGUID(self.guid)
		end
	end
end

function SimulatorAuras:IsEnabled()
	local config = GetConfig()
	if not config or not config.general or config.general.enable == false then
		return false
	end
	local tracker = NotPlater and NotPlater.AuraTracker
	if not tracker or not tracker.NotifyListeners then
		return false
	end
	local auraModule = NotPlater.GetAuraModule and NotPlater:GetAuraModule()
	return auraModule ~= nil
end

function SimulatorAuras:GetDesiredCounts()
	local config = GetConfig()
	if not config then
		return 0, 0, MAX_TOTAL
	end
	local frame1 = clampCount(config.auraFrame1 and config.auraFrame1.rowCount)
	local hasSecondFrame = config.auraFrame2 and config.auraFrame2.enable
	local frame2 = frame1
	if hasSecondFrame then
		frame2 = clampCount(config.auraFrame2.rowCount)
	end
	local desiredBuffs
	local desiredDebuffs
	if hasSecondFrame then
		desiredDebuffs = frame1
		desiredBuffs = frame2
	else
		desiredBuffs = frame1
		desiredDebuffs = frame1
	end
	desiredBuffs, desiredDebuffs = applyTotalLimit(desiredBuffs, desiredDebuffs)
	return desiredBuffs, desiredDebuffs, MAX_TOTAL
end

function SimulatorAuras:OnShow()
	if not self.frame then
		return
	end
	self.playerGUID = UnitGUID and UnitGUID("player") or self.playerGUID
	self:UpdateTrackerRegistration(true)
	self:ClearAuras()
	self.active = self.active or {}
	wipe(self.active)
	self.forceRefresh = true
end

function SimulatorAuras:OnHide()
	self:ClearAuras()
	self:UpdateTrackerRegistration(false)
end

function SimulatorAuras:ClearAuras()
	if self.active then
		wipe(self.active)
	end
	self.waveTargets = nil
	local tracker = NotPlater and NotPlater.AuraTracker
	if tracker and self.guid then
		if tracker.guidAuras then
			tracker.guidAuras[self.guid] = nil
		end
		if tracker.pendingDurations then
			tracker.pendingDurations[self.guid] = nil
		end
		if tracker.NotifyListeners then
			tracker:NotifyListeners(self.guid)
		end
	end
	self.hasActive = false
end

function SimulatorAuras:GetSourceGUID(source)
	if source == "player" then
		return self.playerGUID or SOURCE_PLAYER_GUID
	elseif source == "pet" then
		return SOURCE_PET_GUID
	elseif source == "self" then
		return self.guid
	end
	return SOURCE_NPC_GUID
end

function SimulatorAuras:GetSourceType(source)
	if source == "player" then
		return "player"
	elseif source == "pet" then
		return "pet"
	end
	return "npc"
end

function SimulatorAuras:GetRandomDuration(def)
	local range = def and def.duration or DEFAULT_DURATION_RANGE
	local minValue = range[1] or DEFAULT_DURATION_RANGE[1]
	local maxValue = range[2] or minValue
	if minValue == maxValue then
		return minValue
	end
	return random(minValue * 10, maxValue * 10) / 10
end

function SimulatorAuras:GetStackCount(def)
	local range = def and def.stack
	if not range then
		return random(0, 3)
	end
	local minValue = range[1] or 0
	local maxValue = range[2] or minValue
	return random(minValue, maxValue)
end

function SimulatorAuras:NextKey(kind, spellID)
	self.keyCounter = (self.keyCounter or 0) + 1
	return string.format("%s:%d:%d", kind == "buff" and "B" or "D", spellID, self.keyCounter)
end

function SimulatorAuras:SpawnAura(kind, now)
	local pool = auraPool[kind]
	if not pool or #pool == 0 then
		return nil
	end
	local definition = pool[random(1, #pool)]
	local duration = definition.fallbackDuration or self:GetRandomDuration(definition)
	if not duration or duration <= 0 then
		duration = NO_DURATION_FALLBACK
	end
	local key = self:NextKey(kind, definition.spellID)
	local aura = {
		spellID = definition.spellID,
		name = definition.name,
		icon = definition.icon,
		count = self:GetStackCount(definition),
		dispelType = definition.dispelType,
		isDebuff = kind == "debuff",
		isBuff = kind == "buff",
		casterGUID = self:GetSourceGUID(definition.source),
		targetGUID = self.guid,
		duration = duration,
		expirationTime = now + duration,
		appliedAt = now,
		source = "SIMULATOR",
		sourceType = self:GetSourceType(definition.source),
		targetType = "npc",
		sourceIsPlayer = definition.source == "player",
		isCrowdControl = definition.crowdControl or false,
		isEnrage = definition.enrage or false,
	}
	self.active = self.active or {}
	self.active[key] = aura
	return aura
end

function SimulatorAuras:PushToTracker(skipNotify)
	local tracker = NotPlater and NotPlater.AuraTracker
	if not tracker or not self.guid then
		return
	end
	tracker.guidAuras = tracker.guidAuras or {}
	local entries = tracker.guidAuras and tracker.guidAuras[self.guid]
	if not entries then
		if tracker.guidAuras then
			tracker.guidAuras[self.guid] = {}
			entries = tracker.guidAuras[self.guid]
		else
			return
		end
	end
	local seen = {}
	if self.active then
		for key, aura in pairs(self.active) do
			entries[key] = copyTable(aura)
			seen[key] = true
		end
	end
	for key in pairs(entries) do
		if not seen[key] then
			entries[key] = nil
		end
	end
	if not next(entries) then
		tracker.guidAuras[self.guid] = nil
	end
	self.hasActive = self.active and next(self.active) ~= nil
	if tracker.NotifyListeners and not skipNotify then
		tracker:NotifyListeners(self.guid)
	end
end

function SimulatorAuras:OnUpdate(elapsed)
	if not self.frame or not self.guid then
		return
	end
	if not self:IsEnabled() then
		if self.hasActive then
			self:ClearAuras()
		end
		return
	end
	self.updateElapsed = (self.updateElapsed or 0) + elapsed
	if self.updateElapsed < UPDATE_INTERVAL then
		return
	end
	self.updateElapsed = 0
	local now = GetTime()
	local changed = false
	local respawnQueue = {}
	if self.active then
		for key, aura in pairs(self.active) do
			if aura.expirationTime and aura.expirationTime <= now then
				respawnQueue[#respawnQueue + 1] = aura.isBuff and "buff" or "debuff"
				self.active[key] = nil
				changed = true
			end
		end
	end
	local desiredBuffs, desiredDebuffs, totalLimit = self:GetDesiredCounts()
	totalLimit = totalLimit or MAX_TOTAL
	local buffCount, debuffCount = 0, 0
	if self.active then
		for _, aura in pairs(self.active) do
			if aura.isBuff then
				buffCount = buffCount + 1
			else
				debuffCount = debuffCount + 1
			end
		end
	end
	local function spawnKind(kind)
		if (buffCount + debuffCount) >= totalLimit then
			return false
		end
		local aura = self:SpawnAura(kind, now)
		if aura then
			if aura.isBuff then
				buffCount = buffCount + 1
			else
				debuffCount = debuffCount + 1
			end
			changed = true
			return true
		end
		return false
	end
	for _, kind in ipairs(respawnQueue) do
		if (buffCount + debuffCount) < totalLimit and random() < 0.5 then
			spawnKind(kind)
		end
	end
	if (buffCount + debuffCount) == 0 then
		local buffTarget, debuffTarget = self:GenerateWaveTargets(desiredBuffs, desiredDebuffs)
		self.waveTargets = {buff = buffTarget, debuff = debuffTarget}
		while buffCount < buffTarget and (buffCount + debuffCount) < totalLimit do
			if not spawnKind("buff") then
				break
			end
		end
		while debuffCount < debuffTarget and (buffCount + debuffCount) < totalLimit do
			if not spawnKind("debuff") then
				break
			end
		end
	else
		self.waveTargets = self.waveTargets or {buff = desiredBuffs, debuff = desiredDebuffs}
	end
	if changed or self.forceRefresh then
		self.forceRefresh = nil
		self:PushToTracker()
	end
end
