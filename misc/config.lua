if( not NotPlater ) then return end

local Config = NotPlater:NewModule("Config")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local L = NotPlaterLocals

local ssplit = string.split
local sgmatch = string.gmatch
local sformat = string.format
local tinsert = table.insert
local tonumber = tonumber
local GameTooltip = GameTooltip
local SlashCmdList = SlashCmdList
local InterfaceOptionsFrame = InterfaceOptionsFrame
local UIParent = UIParent

local SML, registered, options, config, dialog


local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick outline"], ["MONOCHROME"] = L["Monochrome"]}
local anchors = {["CENTER"] = L["center"], ["BOTTOM"] = L["bottom"], ["TOP"] = L["top"], ["LEFT"] = L["left"], ["RIGHT"] = L["right"], ["BOTTOMLEFT"] = L["bottomleft"], ["TOPRIGHT"] = L["topright"], ["BOTTOMRIGHT"] = L["bottomright"], ["TOPLEFT"] = L["topleft"]}
local frameStratas = {["BACKGROUND"] = L["background"], ["LOW"] = L["low"], ["MEDIUM"] = L["medium"], ["HIGH"] = L["high"], ["DIALOG"] = L["dialog"], ["FULLSCREEN"] = L["fullscreen"], ["FULLSCREEN_DIALOG"] = L["fullscreen dialog"], ["TOOLTIP"] = L["tooltip"]}
local strataSort = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"}
local drawLayers = {["BACKGROUND"] = L["background"], ["BORDER"] = L["border"], ["ARTWORK"] = L["artwork"], ["OVERLAY"] = L["overlay"], ["HIGHLIGHT"] = L["highlight"]}

local TEXTURE_BASE_PATH = [[Interface\Addons\NotPlater\images\statusbarTextures\]]
local textures = {"NotPlater Default", "BarFill", "Banto", "Smooth", "Perl", "Glaze", "Charcoal", "Otravi", "Striped", "LiteStep"}

NotPlater.targetIndicators = {
	["NONE"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\UI-Achievement-WoodBorder-Corner]],
		coords = {{.9, 1, .9, 1}, {.9, 1, .9, 1}, {.9, 1, .9, 1}, {.9, 1, .9, 1}}, --texcoords, support 4 or 8 coords method
		desaturated = false,
		width = 10,
		height = 10,
		x = 1,
		y = 1,
	},
	
	["Magneto"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\RelicIconFrame]],
		coords = {{0, .5, 0, .5}, {0, .5, .5, 1}, {.5, 1, .5, 1}, {.5, 1, 0, .5}},
		desaturated = false,
		width = 8,
		height = 10,
		autoScale = true,
		x = 2,
		y = 2,
	},
	
	["Gray Bold"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\UI-Icon-QuestBorder]],
		coords = {{0, .5, 0, .5}, {0, .5, .5, 1}, {.5, 1, .5, 1}, {.5, 1, 0, .5}},
		desaturated = true,
		width = 10,
		height = 10,
		autoScale = true,
		x = 2,
		y = 2,
	},
	
	["Pins"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\UI-ItemSockets]],
		coords = {{145/256, 161/256, 3/256, 19/256}, {145/256, 161/256, 19/256, 3/256}, {161/256, 145/256, 19/256, 3/256}, {161/256, 145/256, 3/256, 19/256}},
		desaturated = 1,
		width = 4,
		height = 4,
		autoScale = false,
		x = 2,
		y = 2,
	},

	["Silver"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\PETBATTLEHUD]],
		coords = {
			{336/512, 356/512, 454/512, 474/512}, 
			{336/512, 356/512, 474/512, 495/512}, 
			{356/512, 377/512, 474/512, 495/512}, 
			{356/512, 377/512, 454/512, 474/512}
		}, --848 889 454 495
		desaturated = false,
		width = 6,
		height = 6,
		autoScale = true,
		x = 1,
		y = 1,
	},
	
	["Ornament"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\PETJOURNAL]],
		coords = {
			{124/512, 161/512, 71/512, 99/512}, 
			{119/512, 156/512, 29/512, 57/512}
		},
		desaturated = false,
		width = 18,
		height = 12,
		wscale = 1,
		hscale = 1.2,
		autoScale = true,
		x = 14,
		y = 0,
	},
	
	--[[
	["Golden"] = {
		path = Interface\AddOns\NotPlater\images\targetBorders\Artifacts
		coords = {
			{137/512, (137+29)/512, 408/512, 466/512},
			{(137+30)/512, 195/512, 408/512, 466/512},
		},
		desaturated = false,
		width = 8,
		height = 12,
		wscale = 1,
		hscale = 1.2,
		autoScale = true,
		x = 0,
		y = 0,
	},
	]]
	
	["Ornament Gray"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\challenges-besttime-bg]],
		coords = {
			{89/512, 123/512, 0, 1},
			{123/512, 89/512, 0, 1},
		},
		desaturated = false,
		width = 8,
		height = 12,
		alpha = 0.7,
		wscale = 1,
		hscale = 1.2,
		autoScale = true,
		x = 0,
		y = 0,
		color = {r = 1, g = 0, b = 0},
	},

	["Epic"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\WowUI_Horizontal_Frame]],
		coords = {
			{30/256, 40/256, 15/64, 49/64},
			{40/256, 30/256, 15/64, 49/64}, 
		},
		desaturated = false,
		width = 6,
		height = 12,
		wscale = 1,
		hscale = 1.2,
		autoScale = true,
		x = 3,
		y = 0,
		blend = "ADD",
	},
	
	["Arrow"] = {
        path = [[Interface\AddOns\NotPlater\images\targetBorders\arrow_single_right_64]],
        coords = {
            {0, 1, 0, 1}, 
            {1, 0, 0, 1}
        },
        desaturated = false,
        width = 20,
        height = 20,
        x = 28,
        y = 0,
		wscale = 1.5,
		hscale = 2,
		autoScale = true,
        blend = "ADD",
        color = {r = 1, g = 1, b = 1},
    },
	
	["Arrow Thin"] = {
        path = [[Interface\AddOns\NotPlater\images\targetBorders\arrow_thin_right_64]],
        coords = {
            {0, 1, 0, 1}, 
            {1, 0, 0, 1}
        },
        desaturated = false,
        width = 20,
        height = 20,
        x = 28,
        y = 0,
		wscale = 1.5,
		hscale = 2,
		autoScale = true,
        blend = "ADD",
        color = {r = 1, g = 1, b = 1},
    },
	
	["Double Arrows"] = {
        path = [[Interface\AddOns\NotPlater\images\targetBorders\arrow_double_right_64]],
        coords = {
            {0, 1, 0, 1}, 
            {1, 0, 0, 1}
        },
        desaturated = false,
        width = 20,
        height = 20,
        x = 28,
        y = 0,
		wscale = 1.5,
		hscale = 2,
		autoScale = true,
        blend = "ADD",
        color = {r = 1, g = 1, b = 1},
    },
}

local HIGHLIGHT_BASE_PATH = [[Interface\AddOns\NotPlater\images\targetBorders\]]
NotPlater.targetHighlights = {
	[HIGHLIGHT_BASE_PATH .. "selection_indicator1"] =  "Indicator 1",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator2"] =  "Indicator 2",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator3"] =  "Indicator 3",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator4"] =  "Indicator 4",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator5"] =  "Indicator 5",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator6"] =  "Indicator 6",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator7"] =  "Indicator 7",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator8"] =  "Indicator 8"
}

local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hHalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vHalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vHalf..hHalf, frame, (vHalf == "TOP" and "BOTTOM" or "TOP")..hHalf
end

local function drawMinimapTooltip()
    local tooltip = GameTooltip
    tooltip:ClearLines()
    tooltip:AddDoubleLine("NotPlater", NotPlater.revision or "1.0.0")
    tooltip:AddLine(" ")
    tooltip:AddLine(L["|cffeda55fLeft-Click|r to toggle the config window"], 0.2, 1, 0.2)
    tooltip:AddLine(L["|cffeda55fRight-Click|r to toggle the simulator frame"], 0.2, 1, 0.2)
    tooltip:AddLine(L["|cffeda55fMiddle-Click|r to toggle the minimap icon"], 0.2, 1, 0.2);
    tooltip:Show()
end

local function ToggleMinimap()
    NotPlaterDB.minimap.hide = not NotPlaterDB.minimap.hide
    if NotPlaterDB.minimap.hide then
        LDBIcon:Hide("NotPlater");
        NotPlater:Print(L["Use /np minimap to show the minimap icon again"])
    else
        LDBIcon:Show("NotPlater");
    end
end

local tooltipUpdateFrame = CreateFrame("Frame")
local Broker_NotPlater = LDB:NewDataObject("NotPlater", {
    type = "launcher",
    text = "NotPlater",
    icon = "Interface\\AddOns\\NotPlater\\images\\logo",
    OnClick = function(self, button)
		if(button == "LeftButton") then
			Config:ToggleConfig()
        elseif(button == "RightButton") then
			NotPlater:ToggleSimulatorFrame()
        else -- "MiddleButton"
            ToggleMinimap()
        end
        drawMinimapTooltip()
    end,
    OnEnter = function(self)
        local elapsed = 0
        local delay = 1
        tooltipUpdateFrame:SetScript("OnUpdate", function(self, elap)
            elapsed = elapsed + elap
            if(elapsed > delay) then
                elapsed = 0
                drawMinimapTooltip()
            end
        end);
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(getAnchors(self))
        drawMinimapTooltip()
    end,
    OnLeave = function(self)
        tooltipUpdateFrame:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
    end,
})

function Config:OnInitialize()
	config = LibStub("AceConfig-3.0")
	dialog = LibStub("AceConfigDialog-3.0")
	
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	for _, statusBarTexture in ipairs(textures) do
		SML:Register(SML.MediaType.STATUSBAR, statusBarTexture, TEXTURE_BASE_PATH .. statusBarTexture)
	end

	NotPlaterDB.minimap = NotPlaterDB.minimap or {hide = false}
	LDBIcon:Register("NotPlater", Broker_NotPlater, NotPlaterDB.minimap)
end

-- GUI
local function set(info, value)
	local arg1, arg2, arg3 = ssplit(".", info.arg)
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
	local arg1, arg2, arg3 = ssplit(".", info.arg)
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

local function setColor(info, r, g, b, a)
	local arg1, arg2, arg3, arg4 = ssplit(".", info.arg)

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
function Config:GetFonts()
	local fonts = {}
	for _, name in pairs(SML:List(SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
end

function Config:GetIndicators()
	local indicators = {}
	for name, _ in pairs(NotPlater.targetIndicators) do
		indicators[name] = name
	end
	
	return indicators
end

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
										name = L["Upper 20% on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.dpsHealerUpperTwentyPercentOnThreat",
									},
									lowerEightyPercentOnThreat = {
										order = 4,
										type = "color",
										name = L["Lower 80% on Threat"],
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
										name = L["Upper 20% on Threat"],
										hasAlpha = true,
										set = setColor,
										get = getColor,
										arg = "threat.threatNumberText.tankUpperTwentyPercentOnThreat",
									},
									lowerEightyPercentOnThreat = {
										order = 4,
										type = "color",
										name = L["Lower 80% on Threat"],
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
					backgroundColor = {
						order = 2,
						type = "color",
						name = L["Background color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "healthBar.backgroundColor",
					},
					position = {
						order = 3,
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
					border = {
						order = 4,
						type = "group",
						inline = true,
						name = L["Border"],
						args = {
							enabled = {
								order = 0,
								type = "toggle",
								name = L["Enable border"],
								arg = "healthBar.border.enabled",
							},
							color = {
								order = 1,
								type = "color",
								name = L["Border color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "healthBar.border.color",
							},
							thickness = {
								order = 2,
								type = "range",
								name = L["Border thickness"],
								min = 1, max = 10, step = 1,
								set = setNumber,
								arg = "healthBar.border.thickness",
							},
						},
					},
				},
			},
			healthText = {
				order = 1,
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
					border = {
						order = 5,
						type = "group",
						inline = true,
						name = L["Border"],
						args = {
							enabled = {
								order = 0,
								type = "toggle",
								name = L["Enable border"],
								arg = "castBar.border.enabled",
							},
							color = {
								order = 1,
								type = "color",
								name = L["Border color"],
								hasAlpha = true,
								set = setColor,
								get = getColor,
								arg = "castBar.border.color",
							},
							thickness = {
								order = 2,
								type = "range",
								name = L["Border thickness"],
								min = 1, max = 10, step = 1,
								set = setNumber,
								arg = "castBar.border.thickness",
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
	options.args.targetBorder = {
		order = 8,
		type = "group",
		name = L["Target border"],
		get = get,
		set = set,
		handler = Config,
		args = {
			indicator = {
				order = 0,
				type = "group",
				inline = true,
				name = L["Indicator"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enabled"],
						arg = "targetBorder.indicator.enabled",
					},
					selection = {
						order = 1,
						type = "select",
						name = L["Indicator selection"],
						values = "GetIndicators",
						arg = "targetBorder.indicator.selection",
					},
				},
			},
			highlight = {
				order = 1,
				type = "group",
				inline = true,
				name = L["Highlight"],
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enabled"],
						width = "full",
						arg = "targetBorder.highlight.enabled",
					},
					color = {
						order = 1,
						type = "color",
						name = L["Highlight color"],
						hasAlpha = true,
						set = setColor,
						get = getColor,
						arg = "targetBorder.highlight.color",
					},
					texture = {
						order = 2,
						type = "select",
						name = L["Highlight texture"],
						values = NotPlater.targetHighlights,
						arg = "targetBorder.highlight.texture",
					},
					thickness = {
						order = 3,
						type = "range",
						name = L["Highlight thickness"],
						min = 1, max = 30, step = 1,
						set = setNumber,
						arg = "targetBorder.highlight.thickness",
					},
				},
			},
		},
	}
	options.args.simulator = {
		order = 9,
		type = "group",
		name = L["Simulator"],
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
					showOnConfig = {
						order = 0,
						type = "toggle",
						width = "double",
						name = L["Show simulator when showing config"],
						arg = "simulator.showOnConfig",
					},
					execSim = {
						order = 1,
						type = "execute",
						name = L["Toggle simulator frame"],
						func = function () NotPlater:ToggleSimulatorFrame() end,
					},
				},
			},
		},
	}

	-- DB Profiles
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(NotPlater.db)
	options.args.profile.order = 10
end

function Config:ToggleConfig()
	if dialog.OpenFrames["NotPlater"] then
		if NotPlater.db.profile.simulator.showOnConfig then
			NotPlater:HideSimulatorFrame()
		end
		dialog:Close("NotPlater")
	else
		self:OpenConfig()
	end
end

function Config:OpenConfig()
	if( not registered ) then
		if( not options ) then
			loadOptions()
		end

		config:RegisterOptionsTable("NotPlater", options)
		dialog:SetDefaultSize("NotPlater", 830, 600)
		registered = true
	end
	if NotPlater.db.profile.simulator.showOnConfig then
		NotPlater:ShowSimulatorFrame()
	end
	dialog:Open("NotPlater")
end

-- Slash commands
SLASH_NOTPLATER1 = "/notplater"
SLASH_NOTPLATER2 = "/np"
SlashCmdList["NOTPLATER"] = function(input)
	local args, msg = {}, nil

    for v in sgmatch(input, "%S+") do
        if not msg then
			msg = v
        else
			tinsert(args, v)
        end
    end

    if msg == "minimap" then
        ToggleMinimap()
    elseif msg == "simulator" then
		NotPlater:ToggleSimulatorFrame()
	elseif msg == "help" then
        NotPlater:PrintHelp()
	else
		Config:ToggleConfig()
    end
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
				name = sformat("NotPlater %s is a feature rich nameplate addon based on Nameplates Modifier (Design inspired by Plater).", NotPlater.revision or "2.0.0"),
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

	config:RegisterOptionsTable("NotPlater-TargetBorder", options.args.targetBorder)
	dialog:AddToBlizOptions("NotPlater-TargetBorder", options.args.targetBorder.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Simulator", options.args.simulator)
	dialog:AddToBlizOptions("NotPlater-Simulator", options.args.simulator.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Profile", options.args.profile)
	dialog:AddToBlizOptions("NotPlater-Profile", options.args.profile.name, "NotPlater")
end)