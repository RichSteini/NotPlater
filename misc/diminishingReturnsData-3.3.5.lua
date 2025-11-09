if not NotPlater then return end

NotPlater.DiminishingReturnsSpells = NotPlater.DiminishingReturnsSpells or {
	--[[ TAUNT ]]--
	-- Taunt (Warrior)
	[355] = "taunt",
	-- Taunt (Pet)
	[53477] = "taunt",
	-- Mocking Blow
	[694] = "taunt",
	-- Growl (Druid)
	[6795] = "taunt",
	-- Dark Command
	[56222] = "taunt",
	-- Hand of Reckoning
	[62124] = "taunt",
	-- Righteous Defense
	[31790] = "taunt",
	-- Distracting Shot
	[20736] = "taunt",
	-- Challenging Shout
	[1161] = "taunt",
	-- Challenging Roar
	[5209] = "taunt",
	-- Death Grip
	[49560] = "taunt",
	-- Challenging Howl
	[59671] = "taunt",
	-- Angered Earth
	[36213] = "taunt",
	
	--[[ DISORIENTS ]]--
	-- Dragon's Breath
	[31661] = "disorient",
	[33041] = "disorient",
	[33042] = "disorient",
	[33043] = "disorient",
	[42949] = "disorient",
	[42950] = "disorient",
	
	-- Hungering Cold
	[49203] = "disorient",
	
	-- Sap
	[6770] = "disorient",
	[2070] = "disorient",
	[11297] = "disorient",
	[51724] = "disorient",
	
	-- Gouge
	[1776] = "disorient",
		
	-- Hex (Guessing)
	[51514] = "disorient",
	
	-- Shackle
	[9484] = "disorient",
	[9485] = "disorient",
	[10955] = "disorient",
	
	-- Polymorph
	[118] = "disorient",
	[12824] = "disorient",
	[12825] = "disorient",
	[28272] = "disorient",
	[28271] = "disorient",
	[12826] = "disorient",
	[61305] = "disorient",
	[61025] = "disorient",
	[61721] = "disorient",
	[61780] = "disorient",
	
	-- Freezing Trap
	[3355] = "disorient",
	[14308] = "disorient",
	[14309] = "disorient",
	
	-- Freezing Arrow
	[60210] = "disorient",

	-- Wyvern Sting
	[19386] = "disorient",
	[24132] = "disorient",
	[24133] = "disorient",
	[27068] = "disorient",
	[49011] = "disorient",
	[49012] = "disorient",
	
	-- Repentance
	[20066] = "disorient",
		
	--[[ SILENCES ]]--
	-- Nether Shock
	[53588] = "silence",
	[53589] = "silence",
	
	-- Garrote
	[1330] = "silence",
	
	-- Arcane Torrent (Energy version)
	[25046] = "silence",
	
	-- Arcane Torrent (Mana version)
	[28730] = "silence",
	
	-- Arcane Torrent (Runic power version)
	[50613] = "silence",
	
	-- Silence
	[15487] = "silence",

	-- Silencing Shot
	[34490] = "silence",

	-- Improved Kick
	[18425] = "silence",

	-- Improved Counterspell
	[18469] = "silence",
	
	-- Spell Lock
	[19244] = "silence",
	[19647] = "silence",
	
	-- Shield of the Templar
	[63529] = "silence",
	
	-- Strangulate
	[47476] = "silence",
	[49913] = "silence",
	[49914] = "silence",
	[49915] = "silence",
	[49916] = "silence",
	
	-- Gag Order (Warrior talent)
	[18498] = "silence",
	
	--[[ DISARMS ]]--
	-- Snatch
	[53542] = "disarm",
	[53543] = "disarm",
	
	-- Dismantle
	[51722] = "disarm",
	
	-- Disarm
	[676] = "disarm",
	
	-- Chimera Shot - Scorpid
	[53359] = "disarm",
	
	-- Psychic Horror (Disarm effect)
	[64058] = "disarm",
	
	--[[ FEARS ]]--
	-- Blind
	[2094] = "fear",

	-- Fear (Warlock)
	[5782] = "fear",
	[6213] = "fear",
	[6215] = "fear",
	
	-- Seduction (Pet)
	[6358] = "fear",
	
	-- Howl of Terror
	[5484] = "fear",
	[17928] = "fear",

	-- Psychic scream
	[8122] = "fear",
	[8124] = "fear",
	[10888] = "fear",
	[10890] = "fear",
	
	-- Scare Beast
	[1513] = "fear",
	[14326] = "fear",
	[14327] = "fear",
	
	-- Turn Evil
	[10326] = "fear",
	
	-- Intimidating Shout
	[5246] = "fear",
	

	--[[ CONTROL STUNS ]]--
	-- Intercept (Felguard)
	[30153] = "ctrlstun",
	[30195] = "ctrlstun",
	[30197] = "ctrlstun",
	[47995] = "ctrlstun",
	
	-- Ravage
	[50518] = "ctrlstun",
	[53558] = "ctrlstun",
	[53559] = "ctrlstun",
	[53560] = "ctrlstun",
	[53561] = "ctrlstun",
	[53562] = "ctrlstun",
	
	-- Sonic Blast
	[50519] = "ctrlstun",
	[53564] = "ctrlstun",
	[53565] = "ctrlstun",
	[53566] = "ctrlstun",
	[53567] = "ctrlstun",
	[53568] = "ctrlstun",
	
	-- Concussion Blow
	[12809] = "ctrlstun",
	
	-- Shockwave
	[46968] = "ctrlstun",
	
	-- Hammer of Justice
	[853] = "ctrlstun",
	[5588] = "ctrlstun",
	[5589] = "ctrlstun",
	[10308] = "ctrlstun",

	-- Bash
	[5211] = "ctrlstun",
	[6798] = "ctrlstun",
	[8983] = "ctrlstun",
	
	--***********************************************************
	-- Intimidation
	[19577] = "ctrlstun",

	-- Maim
	[22570] = "ctrlstun",
	[49802] = "ctrlstun",

	-- Kidney Shot
	[408] = "ctrlstun",
	[8643] = "ctrlstun",

	-- War Stomp
	[20549] = "ctrlstun",

	-- Intercept
	[20252] = "ctrlstun",
	
	-- Deep Freeze
	[44572] = "ctrlstun",
			
	-- Shadowfury
	[30283] = "ctrlstun", 
	[30413] = "ctrlstun",
	[30414] = "ctrlstun",
	
	-- Holy Wrath
	[2812] = "ctrlstun",
	
	-- Inferno Effect
	[22703] = "ctrlstun",
	
	-- Demon Charge
	[60995] = "ctrlstun",
	
	-- Gnaw (Ghoul)
	[47481] = "ctrlstun",
	
	--[[ RANDOM STUNS ]]--
	-- Impact
	[12355] = "rndstun",

	-- Stoneclaw Stun
	[39796] = "rndstun",
	
	-- Seal of Justice
	[20170] = "rndstun",
	
	-- Revenge Stun
	[12798] = "rndstun",
	
	--[[ CYCLONE ]]--
	-- Cyclone
	[33786] = "cyclone",
	
	--[[ ROOTS ]]--
	-- Freeze (Water Elemental)
	[33395] = "ctrlroot",
	
	-- Pin (Crab)
	[50245] = "ctrlroot",
	[53544] = "ctrlroot",
	[53545] = "ctrlroot",
	[53546] = "ctrlroot",
	[53547] = "ctrlroot",
	[53548] = "ctrlroot",	
	
	-- Frost Nova
	[122] = "ctrlroot",
	[865] = "ctrlroot",
	[6131] = "ctrlroot",
	[10230] = "ctrlroot",
	[27088] = "ctrlroot",
	[42917] = "ctrlroot",
	
	-- Entangling Roots
	[339] = "ctrlroot",
	[1062] = "ctrlroot",
	[5195] = "ctrlroot",
	[5196] = "ctrlroot",
	[9852] = "ctrlroot",
	[9853] = "ctrlroot",
	[26989] = "ctrlroot",
	[53308] = "ctrlroot",
	
	-- Nature's Grasp (Uses different spellIDs than Entangling Roots for the same spell)
	[19970] = "ctrlroot",
	[19971] = "ctrlroot",
	[19972] = "ctrlroot",
	[19973] = "ctrlroot",
	[19974] = "ctrlroot",
	[19975] = "ctrlroot",
	[27010] = "ctrlroot",
	[53313] = "ctrlroot",
	
	-- Earthgrab (Storm, Earth and Fire talent)
	[8377] = "ctrlroot",
	[31983] = "ctrlroot",

	-- Web (Spider)
	[4167] = "ctrlroot",
	
	-- Venom Web Spray (Silithid)
	[54706] = "ctrlroot",
	[55505] = "ctrlroot",
	[55506] = "ctrlroot",
	[55507] = "ctrlroot",
	[55508] = "ctrlroot",
	[55509] = "ctrlroot",
	
	
	--[[ RANDOM ROOTS ]]--
	-- Improved Hamstring
	[23694] = "rndroot",
	
	-- Frostbite
	[12494] = "rndroot",

	-- Shattered Barrier
	[55080] = "rndroot",
	
	--[[ SLEEPS ]]--
	-- Hibernate
	[2637] = "sleep",
	[18657] = "sleep",
	[18658] = "sleep",
		
	--[[ HORROR ]]--
	-- Death Coil
	[6789] = "horror",
	[17925] = "horror",
	[17926] = "horror",
	[27223] = "horror",
	[47859] = "horror",
	[47860] = "horror",
	
	-- Psychic Horror
	[64044] = "horror",
	
	--[[ MISC ]]--
	-- Scatter Shot
	[19503] = "scatters",

	-- Cheap Shot
	[1833] = "cheapshot",

	-- Pounce
	[9005] = "cheapshot",
	[9823] = "cheapshot",
	[9827] = "cheapshot",
	[27006] = "cheapshot",
	[49803] = "cheapshot",

	-- Charge
	[7922] = "charge",
	
	-- Mind Control
	[605] = "mc",

	-- Banish
	[710] = "banish",
	[18647] = "banish",
	
	-- Entrapment
	[64804] = "entrapment",
	[64804] = "entrapment",
	[19185] = "entrapment",
}
