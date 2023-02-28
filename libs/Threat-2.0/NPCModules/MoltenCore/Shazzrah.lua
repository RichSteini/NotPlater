local MAJOR_VERSION = "Threat-2.0"
local MINOR_VERSION = tonumber(("$Revision: 74877 $"):match("%d+"))

if MINOR_VERSION > _G.ThreatLib_MINOR_VERSION then
	_G.ThreatLib_MINOR_VERSION = MINOR_VERSION
end

ThreatLib_funcs[#ThreatLib_funcs+1] = function()
	local ThreatLib = _G.ThreatLib
	local SHAZZRAH_ID = 12264
	local GATE_ID = 23138

	ThreatLib:GetModule("NPCCore"):RegisterModule(SHAZZRAH_ID, function(Shazzrah)
		function Shazzrah:Init()
			self:RegisterCombatant(SHAZZRAH_ID, true)			
			self:RegisterSpellHandler("SPELL_CAST_SUCCESS", self.Gate, GATE_ID)
		end
		
		function Shazzrah:Gate()
			self:WipeRaidThreatOnMob(SHAZZRAH_ID)
		end
	end)
end
