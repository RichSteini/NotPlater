function _echo(fun, ...)
   local args = {...}
   for i = 1,#args do args[i] = tostring(args[i]) end
   print("stubs-".._PLAYER_ID..": "..fun .. '(' .. table.concat(args, ", ") .. ')')
end

function UnitClass(unit)
   --_echo("UnitClass", unit)
   if unit == "player" then
      return _PLAYER_CLASS, string.upper(_PLAYER_CLASS)
   end
end
function UnitName(unit)
   --_echo("UnitName", unit)
   if unit == "player" then
      return "Name" .. _PLAYER_ID
   end
end
function UnitGUID(unit)
   --_echo("UnitGUID", unit)
   if unit == "player" then
      return format("0x%016x", _PLAYER_ID)
   end
end
function UnitExists(unit)
   return (unit == "player" or unit == "party1")
end
function GetNumTalents(tab, inspect)
   return 1
end

function _talent_override() return 0 end
function GetTalentInfo(tab, talent)
   return nil, nil, nil, nil, _talent_override(tab, talent)
end

_shapeshift_form = 0  -- overwrite this when shifting
function GetShapeshiftForm()
   return _shapeshift_form
end

function CreateFrame(frametype, name, ...)
   frame = { events = {} }
   print("CreateFrame(" .. name .. ") = " .. tostring(frame))
   function frame:UnregisterAllEvents()
      self.events = {}
   end
   function frame:UnregisterEvent(event)
      _echo("frame:UnregisterEvent", self, event)
      self.events[event] = nil
   end
   function frame:RegisterEvent(event, func)
      _echo("frame:RegisterEvent", self, event)
      self.events[event] = true
   end
   function frame:SetScript(event, func)
      _echo("frame:SetScript", self, event, func)
      assert(event == "OnEvent")
      self.on_event = func
   end
   function frame:_FireEvent(event, ...)
      if self.events[event] then
	 _echo("frame:_FireEvent", self, event, ...)
	 self:on_event(event, ...)
      else
	 print(format("frame:_FireEvent(%s, %s, ...) unhandled", tostring(self), tostring(event), ...))
      end
   end
   return frame
end

function GetLocale() return "enUS" end
function GetBuildInfo() return "2.4.1" end
function IsInInstance() return true, "raid" end
function IsResting() return false end
function IsLoggedIn() return true end
function InCombatLockdown() return true end
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return 1 end
function IsInGuild() return true end
function GetInventoryItemLink() return nil end
function GetItemGem() return nil end
function UnitBuff() return nil end
function UnitDebuff() return nil end
function UnitIsDead(unit) return false end
function UnitLevel(unit) return 70 end
function IsPartyLeader() return true end
function IsEquippedItem() return false end
function UnitAffectingCombat() return true end

-- stubbing it this way means no overhealing/overgaining
function UnitHealth() return 1 end
function UnitHealthMax() return 10000 end
function UnitMana() return 1 end
function UnitManaMax() return 10000 end

do
   local _spellinfo = {
      [7386] = "Sunder Armor",
   }
   function GetSpellInfo(spell)
      return _spellinfo[spell]
   end
end

local AceComm = LibStub:NewLibrary("AceComm-3.0", 4)
AceComm.embeds = {}
function AceComm:RegisterComm(prefix, method)
   _echo("AceComm:RegisterComm", prefix, method)
   _ACECOMMS[UnitName("player")] = self
   if method == nil then
      method = "OnCommReceived"
   end
   if not self._comms then self._comms = {} end
   self._comms[prefix] = method
end
function AceComm:SendCommMessage(prefix, text, distribution, target, prio)
   _echo("AceComm:SendCommMessage", prefix, text, distribution, target, prio)
   for player,comm in pairs(_ACECOMMS) do
      if distribution ~= "WHISPER" or target == player then
	 if not comm._comms_pending then comm._comms_pending = {} end
	 table.insert(comm._comms_pending, {UnitName("player"), prefix, text, distribution})
      end
   end
end
function AceComm:UnregisterAllComm()
   self._comms = {}
end
function AceComm:UnregisterComm(prefix)
   if self._comms then
      self._comms[prefix] = nil
   end
end
function AceComm:_RunComms()
   if not self._comms_pending then self._comms_pending = {} end
   print(format("AceComm:_RunComms(): %d comms pending", #self._comms_pending))
   local ran_something = false
   for _,args in ipairs(self._comms_pending) do
      sender, prefix, text, distribution, target, prio = unpack(args)
      if self._comms[prefix] then
	 local method = self._comms[prefix]
	 if type(method) == "string" then
	    method = self[method]
	 end
	 method(self, prefix, text, distribution, sender)
	 ran_something = true
      end
   end
   self._comms_pending = {}
   return ran_something
end

local mixins = {
   "RegisterComm",
   "UnregisterComm",
   "UnregisterAllComm",
   "SendCommMessage",
   "_RunComms",
}
function AceComm:Embed(target)
   for k, v in pairs(mixins) do
      target[v] = self[v]
   end
   self.embeds[target] = true
   return target
end
function AceComm:OnEmbedDisable(target)
end
for target, v in pairs(AceComm.embeds) do
   AceComm:Embed(target)
end

load_lib("AceConsole-3.0/AceConsole-3.0.lua")
local AceConsole = LibStub("AceConsole-3.0")
function AceConsole:Print(...)
   print("Print " .. tostring(...))
end

load_lib("AceEvent-3.0/AceEvent-3.0.lua")

local AceTimer = LibStub:NewLibrary("AceTimer-3.0", 3)
AceTimer.embeds = {}
function AceTimer:ScheduleTimer(func, time)
   _echo("AceTimer:ScheduleTimer", func, time)
   if not self._timers_pending then self._timers_pending = {} end
   table.insert(self._timers_pending, func)
end
function AceTimer:ScheduleRepeatingTimer(...)
   _echo("AceTimer:ScheduleRepeatingTimer", ...)
end
function AceTimer:CancelTimer(...)
   _echo("AceTimer:CancelTimer", ...)
end
function AceTimer:CancelAllTimers(...)
   _echo("AceTimer:CancelAllTimers", ...)
end
function AceTimer:_RunTimers()
   _echo("AceTimer:_RunTimers")
   if not self._timers_pending then return end
   for i,func in ipairs(self._timers_pending) do
      if type(func) == "string" then
	 print(format("running timer: %s", tostring(func)))
	 func = self[func]
      end
      func(self)
   end
   self._timers_pending = {}
end
AceTimer.embeds = AceTimer.embeds or {}
local mixins = {
   "ScheduleTimer", "ScheduleRepeatingTimer", 
   "CancelTimer", "CancelAllTimers", "_RunTimers"
}
function AceTimer:Embed(target)
   AceTimer.embeds[target] = true
   for _,v in pairs(mixins) do
      target[v] = AceTimer[v]
   end
   return target
end
--AceTimer:OnEmbedDisable( target )
-- target (object) - target object that AceTimer is embedded in.
--
-- cancel all timers registered for the object
function AceTimer:OnEmbedDisable( target )
   target:CancelAllTimers()
end
for addon in pairs(AceTimer.embeds) do
   AceTimer:Embed(addon)
end
