ns = make_threatlib(20, "DRUID")
function fe(...)
   ns._FakeEvent(...)
   ns.ThreatLib:_RunTimers()
end

guid = ns.UnitGUID("player")
name = "FeralDurid"
flags = tonumber("0x511", 16)

mobguid = "0xF1300059B40000EE"
mobname = "Somemob"
mobflags = tonumber("0x2010a48",16)

function assert_threat_generated(amount, ...)
   prev_threat = ns.ThreatLib:GetThreat(guid, mobguid)
   fe("COMBAT_LOG_EVENT_UNFILTERED", "-", ...)
   new_threat = ns.ThreatLib:GetThreat(guid, mobguid)
   assert_nearly(new_threat - prev_threat, amount)
end

function assert_threat_generated_enemy(amount, event, ...)
   assert_threat_generated(amount, event, guid,name,flags,mobguid,mobname,mobflags, ...)
end
function assert_threat_generated_self(amount, event, ...)
   assert_threat_generated(amount, event, guid,name,flags,guid,name,flags, ...)
end

-- spec into Feral Instinct
function ns._talent_override(tree, talent)
   if tree == 2 and talent == 3 then
      return 3
   end
   return 0
end
fe("CHARACTER_POINTS_CHANGED")

-- Caster has no innate reduction
assert_threat_generated_enemy(927, "SWING_DAMAGE",927,1,0,0,0,1,nil,nil)

-- shift to Cat Form
ns._shapeshift_form = 3
fe("UPDATE_SHAPESHIFT_FORM")

-- Cat has innate reduction
assert_threat_generated_enemy(658, "SWING_DAMAGE",927,1,0,0,0,1,nil,nil)
-- S_C_S for mangle must not generate threat as it triggers in all cases
assert_threat_generated_enemy(0, "SPELL_CAST_SUCCESS",33983,"Mangle (Cat)",0x1)
-- S_C_D generates threat
assert_threat_generated_enemy(1236, "SPELL_DAMAGE",33983,"Mangle (Cat)",0x1,1741,1,0,0,0,1,nil,nil)
-- S_M generates no threat
assert_threat_generated_enemy(0, "SPELL_MISSED",33983,"Mangle (Cat)",0x1,"MISS")
-- S_C_S for FFF generates some threat
assert_threat_generated_enemy(90, "SPELL_CAST_SUCCESS",27011,"Faerie Fire (Feral)",0x8)

-- shift to Bear Form. While we're at it, check that doing so generates no threat
prev_threat = ns.ThreatLib:GetThreat(guid, mobguid)
ns._shapeshift_form = 1
fe("UPDATE_SHAPESHIFT_FORM")
assert(ns.ThreatLib:GetThreat(guid, mobguid)-prev_threat == 0)

-- Bear has extra threat from Feral Instinct
assert_threat_generated_enemy(1344, "SWING_DAMAGE",927,1,0,0,0,1,nil,nil)
-- Lacerate threat is greatly reduced
assert_threat_generated_enemy(120, "SPELL_PERIODIC_DAMAGE",33745,"Lacerate",0x1,415,1,0,0,0,nil,nil,nil)
-- Mangle (Bear) has 30% threat added on top of everything
assert_threat_generated_enemy(1310, "SPELL_DAMAGE",33987,"Mangle (Bear)",0x1,695,1,0,0,0,nil,nil,nil)
-- ILotP healing has no threat
assert_threat_generated_self(0, "SPELL_PERIODIC_HEAL",34299,"Improved Leader of the Pack",0x1,754,nil)

-- shift back to caster
ns._shapeshift_form = 0
fe("UPDATE_SHAPESHIFT_FORM")

-- Ferals have no threat reduction on healing
assert_threat_generated_self(1464, "SPELL_HEAL",26979,"Healing Touch",0x8,2928,nil)
assert_threat_generated_self(19.5, "SPELL_PERIODIC_HEAL",33763,"Lifebloom",0x8,39,nil)

-- Test some other kinds of events
assert_threat_generated_self(200, "SPELL_ENERGIZE",17099,"Furor",0x1,40,3)
assert_threat_generated_self(10, "SPELL_PERIODIC_ENERGIZE",5229,"Enrage",0x1,2,1)


-- TODO: check other specs
