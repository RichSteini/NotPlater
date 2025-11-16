if not NotPlater then return end

-- Diminishing returns mapping for 2.4.3-only builds (derived from PlateBuffer data)
NotPlater.DiminishingReturnsSpells = {
	-- Entangling Roots
	[19975] = "ctrlroot",
	[19974] = "ctrlroot",
	[1062] = "ctrlroot",
	[19972] = "ctrlroot",
	[19973] = "ctrlroot",
	[5195] = "ctrlroot",
	[5196] = "ctrlroot",
	[9852] = "ctrlroot",
	[339] = "ctrlroot",
	[9853] = "ctrlroot",
	[19970] = "ctrlroot",
	[26989] = "ctrlroot",
	[27010] = "ctrlroot",

	-- Hibernate
	[2637] = "sleep",
	[18657] = "sleep",
	[18658] = "sleep",

	-- Freezing Trap
	[3355] = "disorient",
	[14308] = "disorient",
	[14309] = "disorient",

	-- Scare Beast
	[1513] = "fear",
	[14326] = "fear",
	[14327] = "fear",

	-- Wyvern Sting
	[19386] = "disorient",
	[24132] = "disorient",
	[24133] = "disorient",
	[49012] = "disorient",

	-- Shackle Undead
	[9484] = "disorient",
	[10955] = "disorient",

	-- Polymorph
	[61721] = "disorient",
	[118] = "disorient",
	[12824] = "disorient",
	[12825] = "disorient",
	[12826] = "disorient",
	[28272] = "disorient",
	[28271] = "disorient",
	[61305] = "disorient",

	-- Repentance / Turn Evil
	[20066] = "disorient",
	[10326] = "fear",

	-- Mind Control
	[605] = "mc",
	[10911] = "mc",
	[10912] = "mc",

	-- Sap
	[6770] = "disorient",
	[2070] = "disorient",
	[11297] = "disorient",
	[51724] = "disorient",

	-- Hamstring (tracked but does not diminish)
	[1715] = "snare",
	[7372] = "snare",
	[7373] = "snare",
	[25212] = "snare",

	-- Banish
	[710] = "banish",
	[18647] = "banish",

	-- Fear effects
	[5782] = "fear",
	[6213] = "fear",
	[6215] = "fear",
	[6358] = "fear",

	-- Earthbind (tracked but does not diminish)
	[3600] = "snare",
}
