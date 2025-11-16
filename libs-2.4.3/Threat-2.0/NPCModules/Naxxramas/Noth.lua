local MAJOR_VERSION = "Threat-2.0"
local MINOR_VERSION = tonumber(("$Revision: 68146 $"):match("%d+"))

if MINOR_VERSION > _G.ThreatLib_MINOR_VERSION then
	_G.ThreatLib_MINOR_VERSION = MINOR_VERSION
end

ThreatLib_funcs[#ThreatLib_funcs+1] = function()
	local ThreatLib = _G.ThreatLib
	local NOTH_ID = 15954
	local BLINK_ID = 29211

	ThreatLib:GetModule("NPCCore"):RegisterModule(NOTH_ID, function(Noth)
		function Noth:Init()
			self:RegisterCombatant(NOTH_ID, true)
			self.buffGains[BLINK_ID] = self.Wipe
		end

		function Noth:Wipe()
			self:WipeRaidThreatOnMob(NOTH_ID)
		end
	end)
end
