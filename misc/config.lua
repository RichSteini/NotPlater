if( not NotPlater ) then return end

local Config = NotPlater:NewModule("Config")
local L = NotPlaterLocals

local SML, registered, options, config, dialog

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
	
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\NotPlater\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\NotPlater\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\NotPlater\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\NotPlater\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\NotPlater\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\NotPlater\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\NotPlater\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\NotPlater\\images\\LiteStep")
	SML:Register(SML.MediaType.STATUSBAR, "NotPlater Default", "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	
	if( arg2 and arg3 ) then
		NotPlater.db.profile[arg1][arg2][arg3] = value
	elseif( arg2 ) then
		NotPlater.db.profile[arg1][arg2] = value
	else
		NotPlater.db.profile[arg1] = value
	end
	
	NotPlater:Reload()
end

local function get(info)
	local arg1, arg2, arg3 = string.split(".", info.arg)
	if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	if( arg2 and arg3 ) then
		return NotPlater.db.profile[arg1][arg2][arg3]
	elseif( arg2 ) then
		return NotPlater.db.profile[arg1][arg2]
	else
		return NotPlater.db.profile[arg1]
	end
end

local function setNumber(info, value)
	set(info, tonumber(value))
end

-- Yes this is a quick hack
local function setColor(info, r, g, b, a)
	local arg1, arg2, arg3, arg4 = string.split(".", info.arg)
	--if( tonumber(arg2) ) then arg2 = tonumber(arg2) end
	if( arg2 and arg3 and arg4 ) then
		NotPlater.db.profile[arg1][arg2][arg3][arg4].r = r
		NotPlater.db.profile[arg1][arg2][arg3][arg4].g = g
		NotPlater.db.profile[arg1][arg2][arg3][arg4].b = b
		NotPlater.db.profile[arg1][arg2][arg3][arg4].a = a
	elseif( arg2 and arg3 ) then
		NotPlater.db.profile[arg1][arg2][arg3].r = r
		NotPlater.db.profile[arg1][arg2][arg3].g = g
		NotPlater.db.profile[arg1][arg2][arg3].b = b
		NotPlater.db.profile[arg1][arg2][arg3].a = a
	elseif( arg2 ) then
		NotPlater.db.profile[arg1][arg2].r = r
		NotPlater.db.profile[arg1][arg2].g = g
		NotPlater.db.profile[arg1][arg2].b = b
		NotPlater.db.profile[arg1][arg2].a = a
	else
		NotPlater.db.profile[arg1].r = r
		NotPlater.db.profile[arg1].g = g
		NotPlater.db.profile[arg1].b = b
		NotPlater.db.profile[arg1].a = a
	end
	
	NotPlater:Reload()
end

local function getColor(info)
	local value = get(info)
	return value.r, value.g, value.b, value.a
end
-- Return all registered SML textures
local textures = {}
function Config:GetTextures()
	for k in pairs(textures) do textures[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

-- Return all registered SML fonts
local fonts = {}
function Config:GetFonts()
	for k in pairs(fonts) do fonts[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
end

local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick outline"], ["MONOCHROME"] = L["Monochrome"]}
local anchors = {["CENTER"] = L["center"], ["BOTTOM"] = L["bottom"], ["TOP"] = L["top"], ["LEFT"] = L["left"], ["RIGHT"] = L["right"], ["BOTTOMLEFT"] = L["bottomleft"], ["TOPRIGHT"] = L["topright"], ["BOTTOMRIGHT"] = L["bottomright"], ["TOPLEFT"] = L["topleft"]}
local frameStratas = {["Inherited"] = L["inherited"], ["BACKGROUND"] = L["background"], ["LOW"] = L["low"], ["MEDIUM"] = L["medium"], ["HIGH"] = L["high"], ["DIALOG"] = L["dialog"], ["FULLSCREEN"] = L["fullscreen"], ["FULLSCREEN_DIALOG"] = L["fullscreen dialog"], ["TOOLTIP"] = L["tooltip"]}
local strataSort = {"Inherited", "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"}
local drawLayers = {["BACKGROUND"] = L["background"], ["BORDER"] = L["border"], ["ARTWORK"] = L["artwork"], ["OVERLAY"] = L["overlay"], ["HIGHLIGHT"] = L["highlight"]}

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "NotPlater"
	options.args = {}
	options.args.general = {
		order = 0,
		type = "group",
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		childGroups = "tab",
		args = {
			header = {
				order = 0,
				name = L["Note: All settings here only work out of combat."],
				type = "header",
			},
			nameplateStacking = {
				order = 1,
				type = "group",
				name = L["Nameplate stacking"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enabled"],
						width = "full",
						desc = L["Only works if the nameplate is visible before you are in combat"],
						arg = "general.nameplateStacking.enabled",
					},
					overlappingCastbars = {
						order = 0,
						type = "toggle",
						name = L["Overlapping castbars"],
						arg = "general.nameplateStacking.overlappingCastbars",
					},
					xMargin = {
						order = 1,
						type = "range",
						name = L["X stacking margin"],
						min = 0, max = 10, step = 1,
						set = setNumber,
						arg = "general.nameplateStacking.xMargin",
					},
					yMargin = {
						order = 2,
						type = "range",
						name = L["Y stacking margin"],
						min = 0, max = 10, step = 1,
						set = setNumber,
						arg = "general.nameplateStacking.yMargin",
					},
				},
			},
			frameStrata = {
				order = 2,
				type = "group",
				name = L["Frame Strata"],
				args = {
					frame = {
						order = 0,
						type = "select",
						name = L["Frame"],
						values = frameStratas,
						--sorting = strataSort,
						arg = "general.frameStrata.frame",
					},
					targetFrame = {
						order = 1,
						type = "select",
						name = L["Target Frame"],
						values = frameStratas,
						--sorting = strataSort,
						arg = "general.frameStrata.targetFrame",
					},
				},
			},
		},
	}
	options.args.threat = {
		order = 0,
		type = "group",
		name = L["Threat"],
		get = get,
		set = set,
		childGroups = "tab",
		handler = Config,
		args = {
			general = {
				order = 0,
				type = "group",
				inline = false,
				name = L["General"],
				args = {
					enableMouseoverUpdate = {
						order = 0,
						type = "toggle",
						name = L["Enable mouseover nameplate threat update"],
						width = "full",
						arg = "threat.general.enableMouseoverUpdate",
					},
					mode = {
						order = 1,
						type = "select",
						name = L["Mode"],
						desc = L["Choose between healer or tank selection."],
						values = {["hdps"] = L["Healer / DPS"], ["tank"] = L["Tank"]},
						arg = "threat.general.mode",
					},
				},
			},
			namePlateColors = {
				order = 1,
				type = "group",
				name = L["Nameplate threat colors"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enable Nameplate Threat Colors"],
						width = "double",
						arg = "threat.nameplateColors.enabled",
					},
					dpsHealerColors = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Threat DPS / healer colors"],
						args = {
							aggroOnYou = {
								order = 0,
								type = "color",
								name = L["Aggro on You"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.nameplateColors.dpsHealerAggroOnYou",
							},
							highThreat = {
								order = 2,
								type = "color",
								name = L["High Threat"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.nameplateColors.dpsHealerHighThreat",
							},
							defaultNoAggro = {
								order = 4,
								type = "color",
								name = L["Default / No Aggro"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.nameplateColors.dpsHealerDefaultNoAggro",
							},
						},
					},
					tankColors = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Threat tank colors"],
						args = {
							aggroOnYou = {
								order = 0,
								type = "color",
								name = L["Aggro on You"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.nameplateColors.tankAggroOnYou",
							},
							highThreat = {
								order = 2,
								type = "color",
								name = L["Tank no aggro"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.nameplateColors.tankNoAggro",
							},
							defaultNoAggro = {
								order = 4,
								type = "color",
								name = L["Dps close"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.nameplateColors.tankDpsClose",
							},
						},
					},
				},
			},
			threatPercentBarText = {
				order = 2,
				type = "group",
				inline = false,
				name = L["Threat % statusbar/text"],
				args = {
					font = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Font"],
						args = {
							fontEnabled = {
								order = 1,
								width = "full",
								type = "toggle",
								name = L["Enable font"],
								arg = "threat.threatPercentBarText.fontEnabled",
							},
							fontName = {
								order = 2,
								type = "select",
								name = L["Font name"],
								desc = L["Font name for the health bar text."],
								values = "GetFonts",
								arg = "threat.threatPercentBarText.fontName",
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
								set = setNumber,
								arg = "threat.threatPercentBarText.fontSize",
							},
							fontBorder = {
								order = 4,
								type = "select",
								name = L["Font border"],
								values = fontBorders,
								arg = "threat.threatPercentBarText.fontBorder",
							},
							fontUseThreatColors = {
								order = 5,
								type = "toggle",
								name = L["Use threat colors"],
								arg = "threat.threatPercentBarText.fontUseThreatColors",
							},
							fontColor = {
								order = 6,
								type = "color",
								name = L["Font color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.threatPercentBarText.fontColor",
							},
							fontPosition = {
								order = 7,
								type = "group",
								inline = true,
								name = L["Position"],
								args = {
									anchor = {
										order = 1,
										type = "select",
										name = L["Anchor"],
										values = anchors,
										arg = "threat.threatPercentBarText.fontAnchor",
									},
									xOffset = {
										order = 2,
										type = "range",
										name = L["Offset X"],
										min = -100, max = 100, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.fontXOffset",
									},
									yOffset = {
										order = 3,
										type = "range",
										name = L["Offset Y"],
										min = -100, max = 100, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.fontYOffset",
									},
								},
							},
							fontShadow = {
								order = 8,
								type = "group",
								inline = true,
								name = L["Shadow"],
								args = {
									fontShadowEnabled = {
										order = 5,
										type = "toggle",
										name = L["Enable shadow"],
										width = "full",
										arg = "threat.threatPercentBarText.fontShadowEnabled",
									},
									fontShadowColor = {
										order = 6,
										type = "color",
										name = L["Shadow color"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.fontShadowColor",
									},
									fontShadowXOffset = {
										order = 7,
										type = "range",
										name = L["Shadow offset X"],
										min = -2, max = 2, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.fontShadowXOffset",
									},
									fontShadowYOffset = {
										order = 8,
										type = "range",
										name = L["Shadow offset Y"],
										min = -2, max = 2, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.fontShadowYOffset",
									},
								},
							},
						},
					},
					bar = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Statusbar"],
						args = {
							barEnabled = {
								order = 0,
								type = "toggle",
								name = L["Enable bar"],
								arg = "threat.threatPercentBarText.barEnabled",
							},
							barTexture = {
								order = 1,
								width = "double",
								type = "select",
								name = L["Bar texture"],
								values = "GetTextures",
								arg = "threat.threatPercentBarText.barTexture",
							},
							barUseThreatColors = {
								order = 2,
								type = "toggle",
								name = L["Use threat colors"],
								arg = "threat.threatPercentBarText.barUseThreatColors",
							},
							barColor = {
								order = 3,
								type = "color",
								name = L["Bar color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.threatPercentBarText.barColor",
							},
							barBackgroundColor = {
								order = 4,
								type = "color",
								name = L["Background color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.threatPercentBarText.barBackgroundColor",
							},
							barBorder = {
								order = 5,
								type = "group",
								inline = true,
								name = L["Border"],
								args = {
									barBorderEnabled = {
										order = 0,
										type = "toggle",
										name = L["Enable border"],
										arg = "threat.threatPercentBarText.barBorderEnabled",
									},
									barBorderColor = {
										order = 1,
										type = "color",
										name = L["Border color"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.barBorderColor",
									},
									barBorderThickness = {
										order = 2,
										type = "range",
										name = L["Border thickness"],
										min = 1, max = 10, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.barBorderThickness",
									},
								},
							},
							barPosition = {
								order = 6,
								type = "group",
								inline = true,
								name = L["Positioning / Scaling"],
								args = {
									anchor = {
										order = 1,
										type = "select",
										name = L["Anchor"],
										values = anchors,
										arg = "threat.threatPercentBarText.barAnchor",
									},
									xOffset = {
										order = 2,
										type = "range",
										name = L["Offset X"],
										min = -100, max = 100, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.barXOffset",
									},
									yOffset = {
										order = 3,
										type = "range",
										name = L["Offset Y"],
										min = -100, max = 100, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.barYOffset",
									},
									xSize = {
										order = 4,
										type = "range",
										name = L["Size X"],
										min = 0, max = 500, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.barXSize",
									},
									ySize = {
										order = 5,
										type = "range",
										name = L["Size Y"],
										min = 0, max = 500, step = 1,
										set = setNumber,
										arg = "threat.threatPercentBarText.barYSize",
									},
								},
							},
						},
					},
					colors = {
						order = 0,
						type = "group",
						inline = true,
						name = L["Threat colors"],
						args = {
							dpsHealerColors = {
								order = 1,
								type = "group",
								inline = true,
								name = L["Threat DPS / healer colors"],
								args = {
									aggroOnYou = {
										order = 0,
										type = "color",
										name = L["100%"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.dpsHealerOneHundredPercent",
									},
									highThreat = {
										order = 2,
										type = "color",
										name = L["Above 90%"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.dpsHealerAboveNinetyPercent",
									},
									defaultNoAggro = {
										order = 4,
										type = "color",
										name = L["Below 90%"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.dpsHealerBelowNinetyPercent",
									},
								},
							},
							tankColors = {
								order = 2,
								type = "group",
								inline = true,
								name = L["Threat tank colors"],
								args = {
									aggroOnYou = {
										order = 0,
										type = "color",
										name = L["100%"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.tankOneHundredPercent",
									},
									highThreat = {
										order = 2,
										type = "color",
										name = L["Above 90%"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.tankAboveNinetyPercent",
									},
									defaultNoAggro = {
										order = 4,
										type = "color",
										name = L["Below 90%"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatPercentBarText.tankBelowNinetyPercent",
									},
								},
							},
						},
					},
				},
			},
			threatDifferentialText = {
				order = 1,
				type = "group",
				inline = false,
				name = L["Threat differential text"],
				args = {
					general = {
						order = 1,
						type = "group",
						inline = true,
						name = L["General"],
						args = {
							fontEnabled = {
								order = 1,
								width = "full",
								type = "toggle",
								name = L["Enable font"],
								arg = "threat.threatDifferentialText.enabled",
							},
							fontName = {
								order = 2,
								type = "select",
								name = L["Font name"],
								desc = L["Font name for the health bar text."],
								values = "GetFonts",
								arg = "threat.threatDifferentialText.fontName",
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
								set = setNumber,
								arg = "threat.threatDifferentialText.fontSize",
							},
							fontBorder = {
								order = 5,
								type = "select",
								name = L["Font border"],
								values = fontBorders,
								arg = "threat.threatDifferentialText.fontBorder",
							},
						},
					},
					position = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "threat.threatDifferentialText.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "threat.threatDifferentialText.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "threat.threatDifferentialText.yOffset",
							},
						},
					},
					colors = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Threat colors"],
						args = {
							dpsHealerColors = {
								order = 1,
								type = "group",
								inline = true,
								name = L["Threat DPS / healer colors"],
								args = {
									aggroOnYou = {
										order = 0,
										type = "color",
										name = L["Aggro on You"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatDifferentialText.dpsHealerAggroOnYou",
									},
									highThreat = {
										order = 2,
										type = "color",
										name = L["High Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatDifferentialText.dpsHealerHighThreat",
									},
									defaultNoAggro = {
										order = 4,
										type = "color",
										name = L["Default / No Aggro"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatDifferentialText.dpsHealerDefaultNoAggro",
									},
								},
							},
							tankColors = {
								order = 2,
								type = "group",
								inline = true,
								name = L["Threat tank colors"],
								args = {
									aggroOnYou = {
										order = 0,
										type = "color",
										name = L["Aggro on You"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatDifferentialText.tankAggroOnYou",
									},
									highThreat = {
										order = 2,
										type = "color",
										name = L["Tank no aggro"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatDifferentialText.tankNoAggro",
									},
									defaultNoAggro = {
										order = 4,
										type = "color",
										name = L["Dps close"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatDifferentialText.tankDpsClose",
									},
								},
							},
						},
					},
					shadow = {
						order = 3,
						type = "group",
						inline = true,
						name = L["Shadow"],
						args = {
							fontShadowEnabled = {
								order = 5,
								type = "toggle",
								name = L["Enable shadow"],
								width = "full",
								arg = "threat.threatDifferentialText.fontShadowEnabled",
							},
							fontShadowColor = {
								order = 6,
								type = "color",
								name = L["Shadow color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.threatDifferentialText.fontShadowColor",
							},
							fontShadowXOffset = {
								order = 7,
								type = "range",
								name = L["Shadow offset X"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "threat.threatDifferentialText.fontShadowXOffset",
							},
							fontShadowYOffset = {
								order = 8,
								type = "range",
								name = L["Shadow offset Y"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "threat.threatDifferentialText.fontShadowYOffset",
							},
						},
					},
				},
			},
			threatNumberText = {
				order = 2,
				type = "group",
				inline = false,
				name = L["Threat number text"],
				args = {
					general = {
						order = 1,
						type = "group",
						inline = true,
						name = L["General"],
						args = {
							fontEnabled = {
								order = 1,
								width = "full",
								type = "toggle",
								name = L["Enable font"],
								arg = "threat.threatNumberText.enabled",
							},
							fontName = {
								order = 2,
								type = "select",
								name = L["Font name"],
								desc = L["Font name for the health bar text."],
								values = "GetFonts",
								arg = "threat.threatNumberText.fontName",
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
								set = setNumber,
								arg = "threat.threatNumberText.fontSize",
							},
							fontBorder = {
								order = 5,
								type = "select",
								name = L["Font border"],
								values = fontBorders,
								arg = "threat.threatNumberText.fontBorder",
							},
						},
					},
					position = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "threat.threatNumberText.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "threat.threatNumberText.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "threat.threatNumberText.yOffset",
							},
						},
					},
					colors = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Threat colors"],
						args = {
							dpsHealerColors = {
								order = 1,
								type = "group",
								inline = true,
								name = L["Threat DPS / healer colors"],
								args = {
									firstOnThreat = {
										order = 0,
										type = "color",
										name = L["First on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.dpsHealerFirstOnThreat",
									},
									upperTwentyPercentOnThreat = {
										order = 2,
										type = "color",
										name = L["Upper twenty percent on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.dpsHealerUpperTwentyPercentOnThreat",
									},
									lowerEightyPercentOnThreat = {
										order = 4,
										type = "color",
										name = L["Lower eighty percent on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.dpsHealerLowerEightyPercentOnThreat",
									},
								},
							},
							tankColors = {
								order = 2,
								type = "group",
								inline = true,
								name = L["Threat tank colors"],
								args = {
									firstOnThreat = {
										order = 0,
										type = "color",
										name = L["First on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.tankFirstOnThreat",
									},
									upperTwentyPercentOnThreat = {
										order = 2,
										type = "color",
										name = L["Upper twenty percent on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.tankUpperTwentyPercentOnThreat",
									},
									lowerEightyPercentOnThreat = {
										order = 4,
										type = "color",
										name = L["Lower eighty percent on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.tankLowerEightyPercentOnThreat",
									},
								},
							},
						},
					},
					shadow = {
						order = 3,
						type = "group",
						inline = true,
						name = L["Shadow"],
						args = {
							fontShadowEnabled = {
								order = 5,
								type = "toggle",
								name = L["Enable shadow"],
								width = "full",
								arg = "threat.threatNumberText.fontShadowEnabled",
							},
							fontShadowColor = {
								order = 6,
								type = "color",
								name = L["Shadow color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "threat.threatNumberText.fontShadowColor",
							},
							fontShadowXOffset = {
								order = 7,
								type = "range",
								name = L["Shadow offset X"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "threat.threatNumberText.fontShadowXOffset",
							},
							fontShadowYOffset = {
								order = 8,
								type = "range",
								name = L["Shadow offset Y"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "threat.threatNumberText.fontShadowYOffset",
							},
						},
					},
				},
			},
		},
	}
	options.args.healthBar = {
		type = "group",
		order = 1,
		name = L["Healthbar"],
		get = get,
		set = set,
		handler = Config,
		childGroups = "tab",
		args = {
			general = {
				order = 0,
				type = "group",
				inline = false,
				name = L["General"],
				args = {
					texture = {
						order = 0,
						type = "select",
						name = L["Bar texture"],
						values = "GetTextures",
						arg = "healthBar.texture",
					},
					hideBorder = {
						order = 1,
						type = "toggle",
						name = L["Hide border"],
						desc = L["A UI reload is required to make the border show back up again."],
						arg = "healthBar.hideBorder",
					},
					hideTargetBorder = {
						order = 2,
						type = "toggle",
						name = L["Hide target border"],
						desc = L["A UI reload is required to make the border show back up again."],
						arg = "healthBar.hideTargetBorder",
					},
					backgroundColor = {
						order = 3,
						type = "color",
						name = L["Background color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "healthBar.backgroundColor",
					},
					position = {
						order = 4,
						type = "group",
						inline = true,
						name = L["Positioning / Scaling"],
						args = {
							xSize = {
								order = 4,
								type = "range",
								name = L["Size X"],
								min = 0, max = 500, step = 1,
								set = setNumber,
								arg = "healthBar.position.xSize",
							},
							ySize = {
								order = 5,
								type = "range",
								name = L["Size Y"],
								min = 0, max = 500, step = 1,
								set = setNumber,
								arg = "healthBar.position.ySize",
							},
						},
					},
				},
			},
			healthText = {
				order = 4,
				type = "group",
				inline = false,
				name = L["Health text"],
				args = {
					general = {
						order = 1,
						type = "group",
						inline = true,
						name = L["General"],
						args = {
							type = {
								order = 1,
								type = "select",
								name = L["Health text display"],
								desc = L["Style of display for health bar text."],
								values = {["none"] = L["None"], ["minmax"] = L["Min / Max"], ["both"] = L["Both"], ["percent"] = L["Percent"]},
								arg = "healthBar.healthText.type",
							},
							fontName = {
								order = 2,
								type = "select",
								name = L["Font name"],
								desc = L["Font name for the health bar text."],
								values = "GetFonts",
								arg = "healthBar.healthText.fontName",
							},
							fontColor = {
								order = 4,
								type = "color",
								name = L["Font color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "healthBar.healthText.fontColor",
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
								set = setNumber,
								arg = "healthBar.healthText.fontSize",
							},
							fontBorder = {
								order = 5,
								type = "select",
								name = L["Font border"],
								values = fontBorders,
								arg = "healthBar.healthText.fontBorder",
							},
						},
					},
					position = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "healthBar.healthText.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "healthBar.healthText.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "healthBar.healthText.yOffset",
							},
						},
					},
					shadow = {
						order = 3,
						type = "group",
						inline = true,
						name = L["Shadow"],
						args = {
							fontShadowEnabled = {
								order = 5,
								type = "toggle",
								name = L["Enable shadow"],
								width = "full",
								arg = "healthBar.healthText.fontShadowEnabled",
							},
							fontShadowColor = {
								order = 6,
								type = "color",
								name = L["Shadow color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "healthBar.healthText.fontShadowColor",
							},
							fontShadowXOffset = {
								order = 7,
								type = "range",
								name = L["Shadow offset X"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "healthBar.healthText.fontShadowXOffset",
							},
							fontShadowYOffset = {
								order = 8,
								type = "range",
								name = L["Shadow offset Y"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "healthBar.healthText.fontShadowYOffset",
							},
						},
					},
				},
			},
		},
	}
	options.args.castBar = {
		type = "group",
		order = 2,
		name = L["Castbar"],
		get = get,
		set = set,
		childGroups = "tab",
		handler = Config,
		args = {
			general = {
				order = 0,
				type = "group",
				inline = false,
				name = L["General"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enabled"],
						width = "full",
						arg = "castBar.enabled",
					},
					texture = {
						order = 1,
						type = "select",
						name = L["Bar texture"],
						values = "GetTextures",
						arg = "castBar.texture",
					},
					barColor = {
						order = 2,
						type = "color",
						name = L["Bar color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "castBar.barColor",
					},
					backgroundColor = {
						order = 3,
						type = "color",
						name = L["Background color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "castBar.backgroundColor",
					},
					position = {
						order = 4,
						type = "group",
						inline = true,
						name = L["Positioning / Scaling"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "castBar.position.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.position.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.position.yOffset",
							},
							xSize = {
								order = 4,
								type = "range",
								name = L["Size X"],
								min = 0, max = 500, step = 1,
								set = setNumber,
								arg = "castBar.position.xSize",
							},
							ySize = {
								order = 5,
								type = "range",
								name = L["Size Y"],
								min = 0, max = 500, step = 1,
								set = setNumber,
								arg = "castBar.position.ySize",
							},
						},
					},
				},
			},
			castSpellIcon = {
				order = 4,
				type = "group",
				inline = false,
				name = L["Cast spellicon"],
				args = {
					general = {
						order = 0,
						type = "group",
						inline = true,
						name = L["General"],
						args = {
							opacity = {
								order = 0,
								type = "range",
								name = L["Opacity"],
								min = 0, max = 1, step = 0.01,
								set = setNumber,
								arg = "castBar.castSpellIcon.opacity",
							},
						},
					},
					position = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "castBar.castSpellIcon.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.castSpellIcon.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.castSpellIcon.yOffset",
							},
							xSize = {
								order = 4,
								type = "range",
								name = L["Size X"],
								min = 0, max = 500, step = 1,
								set = setNumber,
								arg = "castBar.castSpellIcon.xSize",
							},
							ySize = {
								order = 5,
								type = "range",
								name = L["Size Y"],
								min = 0, max = 500, step = 1,
								set = setNumber,
								arg = "castBar.castSpellIcon.ySize",
							},
						},
					},
				},
			},
			castTimeText = {
				order = 4,
				type = "group",
				inline = false,
				name = L["Casttime text"],
				args = {
					general = {
						order = 1,
						type = "group",
						inline = true,
						name = L["General"],
						args = {
							type = {
								order = 1,
								type = "select",
								name = L["Cast text display"],
								desc = L["Style of display for cast bar text."],
								values = {["crtmax"] = L["Current / Max"], ["none"] = L["None"], ["crt"] = L["Current"], ["percent"] = L["Percent"], ["timeleft"] = L["Time left"]},
								arg = "castBar.castTimeText.type",
							},
							fontName = {
								order = 2,
								type = "select",
								name = L["Font name"],
								desc = L["Font name for the health bar text."],
								values = "GetFonts",
								arg = "castBar.castTimeText.fontName",
							},
							fontColor = {
								order = 4,
								type = "color",
								name = L["Font color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "castBar.castTimeText.fontColor",
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
								set = setNumber,
								arg = "castBar.castTimeText.fontSize",
							},
							fontBorder = {
								order = 5,
								type = "select",
								name = L["Font border"],
								values = fontBorders,
								arg = "castBar.castTimeText.fontBorder",
							},
						},
					},
					position = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "castBar.castTimeText.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.castTimeText.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.castTimeText.yOffset",
							},
						},
					},
					shadow = {
						order = 3,
						type = "group",
						inline = true,
						name = L["Shadow"],
						args = {
							fontShadowEnabled = {
								order = 5,
								type = "toggle",
								name = L["Enable shadow"],
								width = "full",
								arg = "castBar.castTimeText.fontShadowEnabled",
							},
							fontShadowColor = {
								order = 6,
								type = "color",
								name = L["Shadow color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "castBar.castTimeText.fontShadowColor",
							},
							fontShadowXOffset = {
								order = 7,
								type = "range",
								name = L["Shadow offset X"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "castBar.castTimeText.fontShadowXOffset",
							},
							fontShadowYOffset = {
								order = 8,
								type = "range",
								name = L["Shadow offset Y"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "castBar.castTimeText.fontShadowYOffset",
							},
						},
					},
				},
			},
			castNameText = {
				order = 4,
				type = "group",
				inline = false,
				name = L["Castname text"],
				args = {
					general = {
						order = 1,
						type = "group",
						inline = true,
						name = L["General"],
						args = {
							fontName = {
								order = 2,
								type = "select",
								name = L["Font name"],
								desc = L["Font name for the health bar text."],
								values = "GetFonts",
								arg = "castBar.castNameText.fontName",
							},
							fontColor = {
								order = 4,
								type = "color",
								name = L["Font color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "castBar.castNameText.fontColor",
							},
							fontSize = {
								order = 3,
								type = "range",
								name = L["Font size"],
								min = 1, max = 20, step = 1,
								set = setNumber,
								arg = "castBar.castNameText.fontSize",
							},
							fontBorder = {
								order = 5,
								type = "select",
								name = L["Font border"],
								values = fontBorders,
								arg = "castBar.castNameText.fontBorder",
							},
						},
					},
					position = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = {
								order = 1,
								type = "select",
								name = L["Anchor"],
								values = anchors,
								arg = "castBar.castNameText.anchor",
							},
							xOffset = {
								order = 2,
								type = "range",
								name = L["Offset X"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.castNameText.xOffset",
							},
							yOffset = {
								order = 3,
								type = "range",
								name = L["Offset Y"],
								min = -100, max = 100, step = 1,
								set = setNumber,
								arg = "castBar.castNameText.yOffset",
							},
						},
					},
					shadow = {
						order = 3,
						type = "group",
						inline = true,
						name = L["Shadow"],
						args = {
							fontShadowEnabled = {
								order = 5,
								type = "toggle",
								name = L["Enable shadow"],
								width = "full",
								arg = "castBar.castNameText.fontShadowEnabled",
							},
							fontShadowColor = {
								order = 6,
								type = "color",
								name = L["Shadow color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "castBar.castNameText.fontShadowColor",
							},
							fontShadowXOffset = {
								order = 7,
								type = "range",
								name = L["Shadow offset X"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "castBar.castNameText.fontShadowXOffset",
							},
							fontShadowYOffset = {
								order = 8,
								type = "range",
								name = L["Shadow offset Y"],
								min = -2, max = 2, step = 1,
								set = setNumber,
								arg = "castBar.castNameText.fontShadowYOffset",
							},
						},
					},
				},
			},
		},
	}
	options.args.nameText = {
		order = 4,
		type = "group",
		name = L["Name text"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					fontEnabled = {
						order = 0,
						width = "full",
						type = "toggle",
						name = L["Enable font"],
						arg = "nameText.fontEnabled",
					},
					fontName = {
						order = 1,
						type = "select",
						name = L["Font name"],
						desc = L["Font name for the actual name text above name plate bars."],
						values = "GetFonts",
						arg = "nameText.fontName",
					},
					fontSize = {
						order = 2,
						type = "range",
						name = L["Font size"],
						min = 1, max = 20, step = 1,
						set = setNumber,
						arg = "nameText.fontSize",
					},
					fontBorder = {
						order = 3,
						type = "select",
						name = L["Font border"],
						values = fontBorders,
						arg = "nameText.fontBorder",
					},
				},
			},
			position = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Position"],
				args = {
					anchor = {
						order = 1,
						type = "select",
						name = L["Anchor"],
						values = anchors,
						arg = "nameText.anchor",
					},
					xOffset = {
						order = 2,
						type = "range",
						name = L["Offset X"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "nameText.xOffset",
					},
					yOffset = {
						order = 3,
						type = "range",
						name = L["Offset Y"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "nameText.yOffset",
					},
				},
			},
			shadow = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Shadow"],
				args = {
					fontShadowEnabled = {
						order = 0,
						type = "toggle",
						name = L["Enable shadow"],
						width = "full",
						arg = "nameText.fontShadowEnabled",
					},
					fontShadowColor = {
						order = 1,
						type = "color",
						name = L["Shadow color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "nameText.fontShadowColor",
					},
					fontShadowXOffset = {
						order = 2,
						type = "range",
						name = L["Shadow offset X"],
						min = -2, max = 2, step = 1,
						set = setNumber,
						arg = "nameText.fontShadowXOffset",
					},
					fontShadowYOffset = {
						order = 3,
						type = "range",
						name = L["Shadow offset Y"],
						min = -2, max = 2, step = 1,
						set = setNumber,
						arg = "nameText.fontShadowYOffset",
					},
				},
			},
		},
	}
	options.args.levelText = {
		order = 5,
		type = "group",
		name = L["Level text"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					fontName = {
						order = 1,
						type = "select",
						name = L["Font name"],
						desc = L["Font name for the actual name text above name plate bars."],
						values = "GetFonts",
						arg = "levelText.fontName",
					},
					fontSize = {
						order = 2,
						type = "range",
						name = L["Font size"],
						min = 1, max = 20, step = 1,
						set = setNumber,
						arg = "levelText.fontSize",
					},
					fontOpacity = {
						order = 2,
						type = "range",
						name = L["Font opacity"],
						min = 0, max = 1, step = 0.01,
						set = setNumber,
						arg = "levelText.fontOpacity",
					},
					fontBorder = {
						order = 3,
						type = "select",
						name = L["Font border"],
						values = fontBorders,
						arg = "levelText.fontBorder",
					},
				},
			},
			position = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Position"],
				args = {
					anchor = {
						order = 1,
						type = "select",
						name = L["Anchor"],
						values = anchors,
						arg = "levelText.anchor",
					},
					xOffset = {
						order = 2,
						type = "range",
						name = L["Offset X"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "levelText.xOffset",
					},
					yOffset = {
						order = 3,
						type = "range",
						name = L["Offset Y"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "levelText.yOffset",
					},
				},
			},
			shadow = {
				order = 3,
				type = "group",
				inline = true,
				name = L["Shadow"],
				args = {
					fontShadowEnabled = {
						order = 0,
						type = "toggle",
						name = L["Enable shadow"],
						width = "full",
						arg = "levelText.fontShadowEnabled",
					},
					fontShadowColor = {
						order = 1,
						type = "color",
						name = L["Shadow color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "levelText.fontShadowColor",
					},
					fontShadowXOffset = {
						order = 2,
						type = "range",
						name = L["Shadow offset X"],
						min = -2, max = 2, step = 1,
						set = setNumber,
						arg = "levelText.fontShadowXOffset",
					},
					fontShadowYOffset = {
						order = 3,
						type = "range",
						name = L["Shadow offset Y"],
						min = -2, max = 2, step = 1,
						set = setNumber,
						arg = "levelText.fontShadowYOffset",
					},
				},
			},
		},
	}
	options.args.raidIcon = {
		order = 6,
		type = "group",
		name = L["Raid icon"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					fontOpacity = {
						order = 2,
						type = "range",
						name = L["Opacity"],
						min = 0, max = 1, step = 0.01,
						set = setNumber,
						arg = "raidIcon.opacity",
					},
				},
			},
			position = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Positioning / Scaling"],
				args = {
					anchor = {
						order = 1,
						type = "select",
						name = L["Anchor"],
						values = anchors,
						arg = "raidIcon.anchor",
					},
					xOffset = {
						order = 2,
						type = "range",
						name = L["Offset X"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "raidIcon.xOffset",
					},
					yOffset = {
						order = 3,
						type = "range",
						name = L["Offset Y"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "raidIcon.yOffset",
					},
					xSize = {
						order = 4,
						type = "range",
						name = L["Size X"],
						min = 0, max = 500, step = 1,
						set = setNumber,
						arg = "raidIcon.xSize",
					},
					ySize = {
						order = 5,
						type = "range",
						name = L["Size Y"],
						min = 0, max = 500, step = 1,
						set = setNumber,
						arg = "raidIcon.ySize",
					},
				},
			},
		},
	}
	options.args.bossIcon = {
		order = 7,
		type = "group",
		name = L["Boss icon"],
		get = get,
		set = set,
		handler = Config,
		args = {
			general = {
				order = 1,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					fontOpacity = {
						order = 2,
						type = "range",
						name = L["Opacity"],
						min = 0, max = 1, step = 0.01,
						set = setNumber,
						arg = "bossIcon.opacity",
					},
				},
			},
			position = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Positioning / Scaling"],
				args = {
					anchor = {
						order = 1,
						type = "select",
						name = L["Anchor"],
						values = anchors,
						arg = "bossIcon.anchor",
					},
					xOffset = {
						order = 2,
						type = "range",
						name = L["Offset X"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "bossIcon.xOffset",
					},
					yOffset = {
						order = 3,
						type = "range",
						name = L["Offset Y"],
						min = -100, max = 100, step = 1,
						set = setNumber,
						arg = "bossIcon.yOffset",
					},
					xSize = {
						order = 4,
						type = "range",
						name = L["Size X"],
						min = 0, max = 500, step = 1,
						set = setNumber,
						arg = "bossIcon.xSize",
					},
					ySize = {
						order = 5,
						type = "range",
						name = L["Size Y"],
						min = 0, max = 500, step = 1,
						set = setNumber,
						arg = "bossIcon.ySize",
					},
				},
			},
		},
	}

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(NotPlater.db)
	options.args.profile.order = 8
end

-- Slash commands
SLASH_NOTPLATER1 = "/notplater"
SLASH_NOTPLATER2 = "/np"
SlashCmdList["NOTPLATER"] = function(msg)
	if( not registered ) then
		if( not options ) then
			loadOptions()
		end

		config:RegisterOptionsTable("NotPlater", options)
		dialog:SetDefaultSize("NotPlater", 830, 600)
		registered = true
	end

	dialog:Open("NotPlater")
end

-- Add the general options + profile, we don't add spells/anchors because it doesn't support sub cats
local register = CreateFrame("Frame", nil, InterfaceOptionsFrame)
register:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	loadOptions()

	config:RegisterOptionsTable("NotPlater-Bliz", {
		name = "NotPlater",
		type = "group",
		args = {
			help = {
				type = "description",
				name = string.format("NotPlater r%d is a feature rich nameplate addon based on Nameplates Modifier (Design inspired by Plater).", NotPlater.revision or 0),
			},
		},
	})
	
	dialog:SetDefaultSize("NotPlater-Bliz", 830, 600)
	dialog:AddToBlizOptions("NotPlater-Bliz", "NotPlater")

	config:RegisterOptionsTable("NotPlater-General", options.args.general)
	dialog:AddToBlizOptions("NotPlater-General", options.args.general.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Threat", options.args.threat)
	dialog:AddToBlizOptions("NotPlater-Threat", options.args.threat.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-HealthBar", options.args.healthBar)
	dialog:AddToBlizOptions("NotPlater-HealthBar", options.args.healthBar.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-CastBar", options.args.castBar)
	dialog:AddToBlizOptions("NotPlater-CastBar", options.args.castBar.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-NameText", options.args.nameText)
	dialog:AddToBlizOptions("NotPlater-NameText", options.args.nameText.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-LevelText", options.args.levelText)
	dialog:AddToBlizOptions("NotPlater-LevelText", options.args.levelText.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-RaidIcon", options.args.raidIcon)
	dialog:AddToBlizOptions("NotPlater-RaidIcon", options.args.raidIcon.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-BossIcon", options.args.bossIcon)
	dialog:AddToBlizOptions("NotPlater-BossIcon", options.args.bossIcon.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Profile", options.args.profile)
	dialog:AddToBlizOptions("NotPlater-Profile", options.args.profile.name, "NotPlater")
end)