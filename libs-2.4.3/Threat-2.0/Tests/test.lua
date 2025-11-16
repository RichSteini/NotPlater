-- path where the required libraries (AceFoo-3.0/ etc.) reside
-- edit this path to whatever you need
-- "../../" should work if you run Threat-2.0 embedded inside an Omen addon directory
-- "../../Libs/" should work if you run Threat-2.0 as a standalone addon
LIB_PATH = "../../Libs/"
--LIB_PATH = "../../"

-- path where Threat-2.0.lua etc. reside
ROOT_PATH = "../"
_ACECOMMS = {}

TIME = 0
function GetTime()
   return TIME
end

function make_threatlib(id, class)
   function loader()
      -- note: must be declared inside this function to access the localized namespace
      -- also note: can't just use dofile, for some reason it "forgets" the local namespace for the duration of dofile()
      function do_locally(name, nopath)
		 --print("loading", name)
		 chunk = assert(loadfile((nopath and "" or ROOT_PATH) .. name))
		 setfenv(chunk, _G)
		 chunk()
      end
      function load_lib(name)
		 do_locally(LIB_PATH .. name, true)
      end

      -- load a pseudo-Ace3 environment
      load_lib("LibStub/LibStub.lua")
      load_lib("CallbackHandler-1.0/CallbackHandler-1.0.lua")
      do_locally("test_stubs.lua", true) -- includes stubs for AceComm-3.0, AceTimer-3.0
      load_lib("AceBucket-3.0/AceBucket-3.0.lua")
      load_lib("AceSerializer-3.0/AceSerializer-3.0.lua")
      load_lib("AceAddon-3.0/AceAddon-3.0.lua")

      -- this list mirrors lib.xml: load Threat-2.0 normally
      do_locally("ThreatUtils.lua")
      do_locally("Threat-2.0.lua")
      do_locally("ThreatTPS.lua")

      do_locally("ThreatClassModuleCore.lua")
      do_locally("ClassModules/Rogue.lua")
      do_locally("ClassModules/Warrior.lua")
      do_locally("ClassModules/Warlock.lua")
      do_locally("ClassModules/Priest.lua")
      do_locally("ClassModules/Paladin.lua")
      do_locally("ClassModules/Druid.lua")
      do_locally("ClassModules/Hunter.lua")
      do_locally("ClassModules/Shaman.lua")
      do_locally("ClassModules/Mage.lua")
      do_locally("ClassModules/Pet.lua")

      do_locally("ThreatNPCModuleCore.lua")

      do_locally("NPCModules/Auchindoun/ShadowLabyrinth/Blackheart.lua")
      do_locally("NPCModules/Azeroth/Azuregos.lua")
      do_locally("NPCModules/BlackTemple/Bloodboil.lua")
      do_locally("NPCModules/BlackTemple/Illidan.lua")
      do_locally("NPCModules/BlackTemple/Supremus.lua")
      do_locally("NPCModules/BlackwingLair/Nefarian.lua")
      do_locally("NPCModules/CavernsOfTime/BlackMorass/Temporus.lua")
      do_locally("NPCModules/CoilfangReservoir/SerpentshrineCavern/Hydross.lua")
      do_locally("NPCModules/CoilfangReservoir/SerpentshrineCavern/Leotheras.lua")
      do_locally("NPCModules/CoilfangReservoir/SerpentshrineCavern/Vashj.lua")
      do_locally("NPCModules/Naxxramas/Noth.lua")
      do_locally("NPCModules/Outland/Doomwalker.lua")
      do_locally("NPCModules/TempestKeep/Arcatraz/Soccothrates.lua")
      do_locally("NPCModules/TempestKeep/TheEye/VoidReaver.lua")
      do_locally("NPCModules/ZulAman/Zuljin.lua")

      do_locally("ThreatBoot.lua")

      ThreatLib = LibStub("Threat-2.0")

      -- enable Threat-2.0 debugging if you wish. need to override its :Debug() though
      --ThreatLib.DebugEnabled = true
      function ThreatLib:Debug(msg, ...)
	 if not ThreatLib.DebugEnabled then return end
	 local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p = ...
	 print(("ThreatLib-%d: " .. msg):format(_PLAYER_ID,
						tostring(a),
						tostring(b),
						tostring(c),
						tostring(d),
						tostring(e),
						tostring(f),
						tostring(g),
						tostring(h),
						tostring(i),
						tostring(j),
						tostring(k),
						tostring(l),
						tostring(m),
						tostring(n),
						tostring(o),
						tostring(p)))
      end

      function _FakeEvent(...)
	 local aaf = LibStub("AceAddon-3.0").frame
	 aaf:_FireEvent(...)
	 local aef = LibStub("AceEvent-3.0").frame
	 aef:_FireEvent(...)
      end

      -- initialize addons
      _FakeEvent("ADDON_LOADED")
      _FakeEvent("PLAYER_LOGIN")
      _FakeEvent("PLAYER_ENTERING_WORLD")
      ThreatLib:_RunTimers()
   end
   
   -- set up a new "global" namespace for this instance
   local new_G = {_PLAYER_ID = id, _PLAYER_CLASS = class}
   for k,v in pairs(_G) do
      new_G[k] = v
   end
   new_G._G = new_G
   setfenv(loader, new_G)
   loader()
   return new_G
end

function equal(x, y, _memo)
   _memo = _memo or {}
   --[[
   print(format('equal(%s,%s) <<<', tostring(x), tostring(y)))
   for a,m in pairs(_memo) do
      for b,f in pairs(m) do
	 print (a,b,f)
      end
   end
   print '>>>'
   --]]
   if type(x) ~= type(y) then return false end
   if x == y then return true end
   if type(x) ~= "table" then return false end
   local count = 0
   for k,v in pairs(x) do
      count = count + 1
      if _memo[v] and _memo[v][y[k]] ~= nil then
	 if not _memo[v][y[k]] then return false end
      elseif _memo[y[k]] and _memo[y[k]][v] ~= nil then
	 if not _memo[y[k]][v] then return false end
      elseif type(v) == "table" and type(y[k]) == "table" then
	 local m = _memo[v] or {}
	 m[y[k]] = true
	 _memo[v] = m
	 _memo[v][y[k]] = equal(v, y[k], _memo)
	 if not _memo[v][y[k]] then return false end
      elseif not equal(v, y[k], _memo) then
	 return false
      end
   end
   for k,v in pairs(y) do
      count = count - 1
   end
   if count ~= 0 then
      return false
   end
   return true
end

function assert_equal(x, y)
   print(format("assert(%s == %s)", tostring(x), tostring(y)))
   assert(equal(x, y))
end

function assert_not_equal(x, y)
   print(format("assert(%s ~= %s)", tostring(x), tostring(y)))
   assert(not equal(x, y))
end


-- might break this too!
assert_equal({["foo"] = "bar", ["baz"] = {1,2}},
	     {["foo"] = "bar", ["baz"] = {1,2}})
do
   local t, u, v
   t = {foo="bar"}
   t.t = t
   u = {foo="bar", t=t}
   assert_equal(t, u)
   v = {t=t}
   assert_not_equal(t, v)
end


function deepcopy(x, _memo)
   _memo = _memo or {}
   if _memo[x] then
      return _memo[x]
   end
   if type(x) ~= "table" then
      return x
   end
   local t = {}
   _memo[x] = t
   for k,v in pairs(x) do
      t[k] = deepcopy(v, _memo)
   end
   return t
end

do
   local t = {foo="bar", blah={1,2}}
   t.rec = t
   assert_equal(t, deepcopy(t))
end

function assert_nearly(x, y)
   -- used to compare threat, since current semantics floor the values on sync
   print(format("assert_nearly(%s, %s)", tostring(x), tostring(y)))
   assert(math.abs(x-y) < 1)
end

-- just an example
ns1 = make_threatlib(1, "Druid")
ns2 = make_threatlib(2, "Rogue")

function communicate()
   local more
   repeat
      more = false
      more = more or ns1.ThreatLib:_RunComms()
      more = more or ns2.ThreatLib:_RunComms()
   until not more
end

communicate()

-- both instances should now know each other's version
assert_equal(ns1.ThreatLib.partyMemberAgents["Name2"], ns2.ThreatLib.userAgent)
assert_equal(ns2.ThreatLib.partyMemberAgents["Name1"], ns1.ThreatLib.userAgent)
-- fixme: dig up the MINOR_VERSION somewhere
assert_equal(ns1.ThreatLib.partyMemberRevisions["Name2"], ns2.ThreatLib.partyMemberRevisions["Name1"])

function cl_ev_uf(ns, ...)
   ns._FakeEvent("COMBAT_LOG_EVENT_UNFILTERED", "blah", ...)
   communicate()
end

guid1 = ns1.UnitGUID("player")
guid2 = ns2.UnitGUID("player")

guid_mob1 = "0xF1300059B40000EE"
guid_mob2 = "0xF1300059DEADBEEF"

-- some random event
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
-- seen on the attacker?
assert(ns1.ThreatLib:GetThreat(guid1, guid_mob1) > 0)
-- verify that we do not track events happening to others
cl_ev_uf(ns2, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x40512",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
assert(ns2.ThreatLib:GetThreat(guid1, guid_mob1) == 0)
-- note that current semantics will not send threat at this point
-- (immediately after startup), but we don't want to rely on this
-- instead, check that consecutive events are not synced:
local prev = ns2.ThreatLib:GetThreat(guid1, guid_mob1)
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
-- throttling should prevent an update
assert_nearly(prev, ns2.ThreatLib:GetThreat(guid1, guid_mob1))
-- now step the time to force sync
TIME = TIME + 2
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
-- threat should be synced again
assert_nearly(ns1.ThreatLib:GetThreat(guid1, guid_mob1), ns2.ThreatLib:GetThreat(guid1, guid_mob1))

guid_other = "0x0000000000001234"
name_other = "Otherguy"

-- spam a few events
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid_other, name_other, tonumber("0x40512",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob2, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid2, "Name2", tonumber("0x40512",16),
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
TIME = TIME + 2
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob2, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
cl_ev_uf(ns2, "SWING_DAMAGE",
	 guid2, "Name2", tonumber("0x511",16),
	 guid_mob2, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
assert(ns1.ThreatLib:GetThreat(guid1, guid_mob1) > 0)
assert(ns1.ThreatLib:GetThreat(guid1, guid_mob2) > 0)
assert(ns2.ThreatLib:GetThreat(guid2, guid_mob1) == 0)
assert(ns2.ThreatLib:GetThreat(guid2, guid_mob2) > 0)
-- did the comms work?
assert_nearly(ns1.ThreatLib:GetThreat(guid1, guid_mob1), ns2.ThreatLib:GetThreat(guid1, guid_mob1))
assert_nearly(ns1.ThreatLib:GetThreat(guid1, guid_mob2), ns2.ThreatLib:GetThreat(guid1, guid_mob2))
assert_nearly(ns1.ThreatLib:GetThreat(guid2, guid_mob1), ns2.ThreatLib:GetThreat(guid2, guid_mob1))
assert_nearly(ns1.ThreatLib:GetThreat(guid2, guid_mob2), ns2.ThreatLib:GetThreat(guid2, guid_mob2))

-- now kill a mob
cl_ev_uf(ns1, "UNIT_DIED",
	 "0x0000000000000000", nil, 0x80000000,
	 guid_mob1, "Sister of Pleasure", tonumber("0x2010a48",16))
assert(ns1.ThreatLib:GetThreat(guid1, guid_mob1) == 0)

-- watch what happens if you try this part in r67174
TIME = TIME + 2
cl_ev_uf(ns1, "SWING_DAMAGE",
	 guid1, "Name1", tonumber("0x511",16),
	 guid_mob2, "Sister of Pleasure", tonumber("0x2010a48",16),
	 102, 1, 0, 0, 102)
assert_nearly(ns1.ThreatLib:GetThreat(guid1, guid_mob2), ns2.ThreatLib:GetThreat(guid1, guid_mob2))
assert_nearly(ns1.ThreatLib:GetThreat(guid2, guid_mob2), ns2.ThreatLib:GetThreat(guid2, guid_mob2))


-- check that restarting threat does not affect its state
-- fails before r68008 because of a class module bug
do
   CLASSES = {"warlock", "warrior", "druid", "shaman", "mage", "paladin", "priest", "rogue", "hunter"}
   assert(#CLASSES == 9)
   for i,cls in ipairs(CLASSES) do
      local t1 = make_threatlib(3, cls)
      local t2 = deepcopy(t1)
      -- pretend we left the party
      function t1.GetNumPartyMembers() return 0 end
      t1._FakeEvent("PARTY_MEMBERS_CHANGED")
      t1.ThreatLib:_RunTimers()
      -- and join again to restart threat
      function t1.GetNumPartyMembers() return 1 end
      t1._FakeEvent("PARTY_MEMBERS_CHANGED")
      t1.ThreatLib:_RunTimers()
      -- did that work?
      assert_equal(t1.ThreatLib, t2.ThreatLib)
   end
end

dofile("class/druid.lua")

print("++ all tests passed ++")
