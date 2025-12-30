if not NotPlater then return end

local L = NotPlaterLocals
local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick Outline"], ["MONOCHROME"] = L["Monochrome"]}
local anchors = {["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOP"] = L["Top"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["BOTTOMLEFT"] = L["Bottom Left"], ["TOPRIGHT"] = L["Top Right"], ["BOTTOMRIGHT"] = L["Bottom Right"], ["TOPLEFT"] = L["Top Left"]}
local frameStratas = {["BACKGROUND"] = L["Background"], ["LOW"] = L["Low"], ["MEDIUM"] = L["Medium"], ["HIGH"] = L["High"], ["DIALOG"] = L["Dialog"], ["FULLSCREEN"] = L["Fullscreen"], ["FULLSCREEN_DIALOG"] = L["Fullscreen Dialog"], ["TOOLTIP"] = L["Tooltip"]}
local drawLayers = {["BACKGROUND"] = L["Background"], ["BORDER"] = L["Border"], ["ARTWORK"] = L["Artwork"], ["OVERLAY"] = L["Overlay"], ["HIGHLIGHT"] = L["Highlight"]}
local auraGrowthDirections = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["CENTER"] = L["Center"]}
local swipeStyleValues = {
	vertical = L["Top to Bottom"],
	swirl = L["Swirl"],
	richsteini = L["RichSteini CD"],
}

local ConfigPrototypes = {}
NotPlater.ConfigPrototypes = ConfigPrototypes

-- Return all registered SML textures
local function GetTextures()
    local textures = {}
	for _, name in pairs(NotPlater.SML:List(NotPlater.SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

-- Return all registered SML fonts
local function GetFonts()
	local fonts = {}
	for _, name in pairs(NotPlater.SML:List(NotPlater.SML.MediaType.FONT)) do
		fonts[name] = name
	end
	
	return fonts
end

local function GetIndicators()
	local indicators = {}
	for name, _ in pairs(NotPlater.targetIndicators) do
		indicators[name] = name
	end
	
	return indicators
end

function ConfigPrototypes:GetGeneralisedThreatColorsConfig(tank1, tank2, tank3, hdps1, hdps2, hdps3)
    return {
        order = 1,
        type = "group",
        inline = true,
        name = L["Colors"],
        args = {
            tank = {
                order = 0,
                type = "group",
                inline = true,
                name = L["Tank"],
                args = {
                    c1 = {
                        order = 0,
                        type = "color",
                        name = tank1,
                        hasAlpha = true,
                    },
                    c2 = {
                        order = 2,
                        type = "color",
                        name = tank2,
                        hasAlpha = true,
                    },
                    c3 = {
                        order = 4,
                        type = "color",
                        name = tank3,
                        hasAlpha = true,
                    },
                },
            },
            hdps = {
                order = 1,
                type = "group",
                inline = true,
                name = L["DPS / Healer"],
                args = {
                    c1 = {
                        order = 0,
                        type = "color",
                        name = hdps1,
                        hasAlpha = true,
                    },
                    c2 = {
                        order = 2,
                        type = "color",
                        name = hdps2,
                        hasAlpha = true,
                    },
                    c3 = {
                        order = 4,
                        type = "color",
                        name = hdps3,
                        hasAlpha = true,
                    },
                },
            },
        },
    }
end

function ConfigPrototypes:GetGeneralisedPositionConfig()
    return {
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
            },
            xOffset = {
                order = 2,
                type = "range",
                name = L["X Offset"],
                min = -100, max = 100, step = 1,
            },
            yOffset = {
                order = 3,
                type = "range",
                name = L["Y Offset"],
                min = -100, max = 100, step = 1,
            },
        },
    }
end

function ConfigPrototypes:GetGeneralisedSizeConfig()
    return {
        order = 1,
        type = "group",
        inline = true,
        name = L["Size"],
        args = {
            width = {
                order = 0,
                type = "range",
                name = L["Width"],
                min = 1, max = 500, step = 1,
            },
            height = {
                order = 1,
                type = "range",
                name = L["Height"],
                min = 1, max = 500, step = 1,
            },
        }
    }
end

function ConfigPrototypes:GetGeneralisedBackgroundConfig()
    return {
        order = 0.5,
        type = "group",
        inline = true,
        name = L["Background"],
        args = {
            enable = {
                order = 0,
                type = "toggle",
                name = L["Enable"],
            },
            color = {
                order = 1,
                type = "color",
                name = L["Color"],
                hasAlpha = true,
            },
            texture = {
                order = 2,
                type = "select",
                name = L["Texture"],
                values = GetTextures,
            },
        },
    }
end

function ConfigPrototypes:GetGeneralisedBorderConfig()
    return { 
        order = 2,
        type = "group",
        inline = true,
        name = L["Border"],
        args = {
            enable = {
                order = 0,
                type = "toggle",
                name = L["Enable"],
            },
            color = {
                order = 1,
                type = "color",
                name = L["Color"],
                hasAlpha = true,
            },
            thickness = {
                order = 2,
                type = "range",
                name = L["Thickness"],
                min = 1, max = 10, step = 1,
            },
        },
    }
end

function ConfigPrototypes:GetGeneralisedFontConfig()
    return {
        general = {
            order = 0,
            type = "group",
            inline = true,
            name = L["General"],
            args = {
                enable = {
                    order = 0,
                    width = "full",
                    type = "toggle",
                    name = L["Enable"],
                },
                name = {
                    order = 1,
                    type = "select",
                    name = L["Name"],
                    values = GetFonts,
                },
                size = {
                    order = 2,
                    type = "range",
                    name = L["Size"],
                    min = 1, max = 20, step = 1,
                },
                border = {
                    order = 3,
                    type = "select",
                    name = L["Border"],
                    values = fontBorders,
                },
            },
        },
        position = ConfigPrototypes:GetGeneralisedPositionConfig(),
        shadow = {
            order = 2,
            type = "group",
            inline = true,
            name = L["Shadow"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                    width = "full",
                },
                color = {
                    order = 1,
                    type = "color",
                    name = L["Color"],
                    hasAlpha = true,
                },
                xOffset = {
                    order = 2,
                    type = "range",
                    name = L["X Offset"],
                    min = -2, max = 2, step = 1,
                },
                yOffset = {
                    order = 3,
                    type = "range",
                    name = L["Y Offset"],
                    min = -2, max = 2, step = 1,
                },
            },
        },
    }
end

function ConfigPrototypes:GetGeneralisedColorFontConfig()
    local config = self:GetGeneralisedFontConfig()
    config.general.args.color = {
        order = 2,
        type = "color",
        name = L["Color"],
        hasAlpha = true,
    }

    return config
end

function ConfigPrototypes:GetGeneralisedThreatFontConfig(tank1, tank2, tank3, hdps1, hdps2, hdps3)
    local config = self:GetGeneralisedFontConfig()
    config.colors = self:GetGeneralisedThreatColorsConfig(tank1, tank2, tank3, hdps1, hdps2, hdps3)

    return config
end

function ConfigPrototypes:GetGeneralisedStatusBarConfig()
    return {
        general = {
            order = 0.25,
            type = "group",
            inline = true,
            name = L["General"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
                color = {
                    order = 1,
                    type = "color",
                    name = L["Color"],
                    hasAlpha = true,
                },
                texture = {
                    order = 2,
                    type = "select",
                    name = L["Texture"],
                    values = GetTextures,
                },
            },
        },
        background = ConfigPrototypes:GetGeneralisedBackgroundConfig(),
        size = ConfigPrototypes:GetGeneralisedSizeConfig(),
        border = ConfigPrototypes:GetGeneralisedBorderConfig()
    }
end

function ConfigPrototypes:GetGeneralisedIconConfig()
    return {
        general = {
            order = 0,
            type = "group",
            inline = true,
            name = L["General"],
            args = {
                opacity = {
                    order = 1,
                    type = "range",
                    name = L["Opacity"],
                    min = 0, max = 1, step = 0.01,
                },
            },
        },
        size = ConfigPrototypes:GetGeneralisedSizeConfig(),
        position = ConfigPrototypes:GetGeneralisedPositionConfig()
    }
end

function ConfigPrototypes:LoadConfigPrototypes()
    ConfigPrototypes.Stacking = {
        componentOrdering = {
            order = 1,
            type = "group",
            name = L["Component Display Order"],
            args = {
                description = {
                    order = 0,
                    type = "description",
                    name = L["Component Display Order Info Text"],
                    fontSize = NotPlater.isWrathClient and "medium" or nil,
                },
                componentList = {
                    order = 1,
                    type = "multiselect",
                    name = L["Component"],
                    values = function()
                        return NotPlater:GetStackingSelectorValues()
                    end,
                    get = function(info, key)
                        local index = tonumber(key)
                        return NotPlater:GetStackingSelectedIndex() == index
                    end,
                    set = function(info, key, state)
                        if state then
                            NotPlater:SetStackingSelectedComponentByIndex(tonumber(key))
                        else
                            NotPlater:SetStackingSelectedComponentByIndex(nil)
                        end
                    end,
                },
                moveControls = {
                    order = 2,
                    type = "group",
                    name = "",
                    inline = true,
                    args = {
						moveUp = {
							order = 0,
							type = "execute",
							name = L["Move Up"],
							image = NotPlater.isWrathClient and "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up" or nil,
							imageWidth = NotPlater.isWrathClient and 32 or nil,
							imageHeight = NotPlater.isWrathClient and 32 or nil,
							func = function()
								NotPlater:ShiftStackingComponent(-1)
							end,
							disabled = function()
								return not NotPlater:GetStackingSelectedComponent()
                            end,
                        },
						moveDown = {
							order = 1,
							type = "execute",
							name = L["Move Down"],
							image = NotPlater.isWrathClient and "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up" or nil,
							imageWidth = NotPlater.isWrathClient and 32 or nil,
							imageHeight = NotPlater.isWrathClient and 32 or nil,
							func = function()
								NotPlater:ShiftStackingComponent(1)
							end,
							disabled = function()
								return not NotPlater:GetStackingSelectedComponent()
                            end,
                        },
                        reset = {
                            order = 2,
                            type = "execute",
                            name = L["Reset Order"],
                            func = function()
                                NotPlater:ResetStackingOrder()
                            end,
                        },
                    },
                },
            },
        },
        stackingSettings = {
            order = 2,
            type = "group",
            name = L["Nameplate Stacking"],
            args = {
                header = {
                    order = 0,
                    name = L["Note: All settings here only work out of combat."],
                    type = "header",
                },
                general = {
                    order = 1,
                    type = "group",
                    inline = true,
                    name = L["General"],
                    args = {
                        enable = {
                            order = 0,
                            type = "toggle",
                            name = L["Enable"],
                            desc = L["Only works if the nameplate is visible before you are in combat"],
                        },
                        overlappingCastbars = {
                            order = 1,
                            type = "toggle",
                            name = L["Overlapping Castbars"],
                        },
                    },
                },
                margin = {
                    order = 2,
                    type = "group",
                    inline = true,
                    name = L["Margin"],
                    args = {
                        xStacking = {
                            order = 0,
                            type = "range",
                            name = L["X Stacking"],
                            min = 0, max = 10, step = 1,
                        },
                        yStacking = {
                            order = 1,
                            type = "range",
                            name = L["Y Stacking"],
                            min = 0, max = 10, step = 1,
                        },
                    },
                },
                frameStrata = {
                    order = 3,
                    type = "group",
                    inline = true,
                    name = L["Frame Strata"],
                    args = {
                        normalFrame = {
                            order = 0,
                            type = "select",
                            name = L["Normal Frame"],
                            values = frameStratas,
                        },
                        targetFrame = {
                            order = 1,
                            type = "select",
                            name = L["Target Frame"],
                            values = frameStratas,
                        },
                    },
                },
            },
        },
    }
    ConfigPrototypes.ThreatGeneral = {
        mode = {
            order = 0,
            type = "select",
            name = L["Mode"],
            values = {["hdps"] = L["Healer / DPS"], ["tank"] = L["Tank"]},
        },
    }
    ConfigPrototypes.ThreatNameplateColors = {
        general = {
            order = 0,
            type = "group",
            inline = true,
            name = L["General"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
            }
        },
        colors = ConfigPrototypes:GetGeneralisedThreatColorsConfig(L["Aggro on You"], L["Tank no Aggro"], L["DPS Close"], L["Aggro on You"], L["High Threat"], L["No Aggro"])
    }
    ConfigPrototypes.ThreatNumberText = ConfigPrototypes:GetGeneralisedThreatFontConfig(L["Number 1 in Group"], L["Above 80% in Group"], L["Below 80% in Group"], L["Number 1 in Group"], L["Above 80% in Group"], L["Below 80% in Group"])
    ConfigPrototypes.ThreatDifferentialText = ConfigPrototypes:GetGeneralisedThreatFontConfig(L["Aggro on You"], L["Tank no Aggro"], L["DPS Close"], L["Aggro on You"], L["High Threat"], L["No Aggro"])
    ConfigPrototypes.ThreatPercentStatusBar = ConfigPrototypes:GetGeneralisedStatusBarConfig()
    ConfigPrototypes.ThreatPercentStatusBar.position = ConfigPrototypes:GetGeneralisedPositionConfig()
    ConfigPrototypes.ThreatPercentStatusBar.colors = ConfigPrototypes:GetGeneralisedThreatColorsConfig(L["100%"], L["Above 90%"], L["Below 90%"], L["100%"], L["Above 90%"], L["Below 90%"])
    ConfigPrototypes.ThreatPercentStatusBar.general.args.enable.width = nil
    ConfigPrototypes.ThreatPercentStatusBar.general.args.useThreatColors = {
        order = 0.5,
        type = "toggle",
        name = L["Use Threat Colors"],
    }
    ConfigPrototypes.ThreatPercentText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.ThreatPercentText.colors = ConfigPrototypes:GetGeneralisedThreatColorsConfig(L["100%"], L["Above 90%"], L["Below 90%"], L["100%"], L["Above 90%"], L["Below 90%"])
    ConfigPrototypes.ThreatPercentText.general.args.enable.width = nil
    ConfigPrototypes.ThreatPercentText.general.args.useThreatColors = {
        order = 0.5,
        type = "toggle",
        name = L["Use Threat Colors"],
    }
    ConfigPrototypes.CastBar = ConfigPrototypes:GetGeneralisedStatusBarConfig()
    ConfigPrototypes.CastBar.general.args.color = {
        order = 1,
        type = "color",
        name = L["Color"],
        hasAlpha = true,
    }
    ConfigPrototypes.CastBar.position = ConfigPrototypes:GetGeneralisedPositionConfig()
    ConfigPrototypes.SpellTimeText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.SpellTimeText.general.args.displayType = {
        order = 1,
        type = "select",
        name = L["Display Type"],
        values = {["crtmax"] = L["Current / Max"], ["none"] = L["None"], ["crt"] = L["Current"], ["percent"] = L["Percent"], ["timeleft"] = L["Time Left"]},
    }
    ConfigPrototypes.SpellNameText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.SpellNameText.general.args.maxLetters = {
        order = 5,
        type = "range",
        name = L["Max. Letters"],
        min = 1, max = 100, step = 1,
    }
    ConfigPrototypes.HealthBar = ConfigPrototypes:GetGeneralisedStatusBarConfig()
    ConfigPrototypes.HealthBar.general.args.useClassColors = {
        order = 0.5,
        type = "toggle",
        width = "double",
        name = L["Use Class Colors when Possible"],
    }
    ConfigPrototypes.HealthText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.HealthText.general.args.displayType = {
        order = 1,
        type = "select",
        name = L["Display Type"],
        values = {["none"] = L["None"], ["minmax"] = L["Min / Max"], ["minmaxpercent"] = L["Min / Max"] .. " / " .. L["Percent"], ["both"] = L["Both"], ["percent"] = L["Percent"]},
    }
    ConfigPrototypes.HealthText.general.args.showDecimalNumbers = {
        order = 1.1,
        type = "toggle",
        name = L["Show Decimals"] .. " (" .. L["Min / Max"] .. ")",
    }
    ConfigPrototypes.HealthText.general.args.showDecimalPercent = {
        order = 1.2,
        type = "toggle",
        name = L["Show Decimals"] .. " (" .. L["Percent"] .. ")",
    }
    ConfigPrototypes.NameText = ConfigPrototypes:GetGeneralisedFontConfig()
    ConfigPrototypes.NameText.general.args.useClassColor = {
        order = 4,
        type = "toggle",
        name = L["Use Class Colors when Possible"],
    }
    ConfigPrototypes.NameText.general.args.color = {
        order = 5,
        type = "color",
        name = L["Color"],
        hasAlpha = true
    }
    ConfigPrototypes.NameText.general.args.maxLetters = {
        order = 6,
        type = "range",
        name = L["Max. Letters"],
        min = 1, max = 100, step = 1,
    }
    ConfigPrototypes.LevelText = ConfigPrototypes:GetGeneralisedFontConfig()
    ConfigPrototypes.LevelText.general.args.useCustomColor = {
        order = 4,
        type = "toggle",
        name = L["Use Custom Color"],
    }
    ConfigPrototypes.LevelText.general.args.color = {
        order = 5,
        type = "color",
        name = L["Color"],
        hasAlpha = true,
        disabled = function()
            return not (NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.levelText.general.useCustomColor)
        end,
    }
    ConfigPrototypes.LevelText.general.args.opacity = {
        order = 1,
        type = "range",
        name = L["Opacity"],
        min = 0, max = 1, step = 0.01,
    }
    ConfigPrototypes.Icon = ConfigPrototypes:GetGeneralisedIconConfig()
    ConfigPrototypes.Icon.general.args.enable = {
        order = 0,
        type = "toggle",
        name = L["Enable"],
    }
    ConfigPrototypes.BossIcon = ConfigPrototypes:GetGeneralisedIconConfig()
    ConfigPrototypes.BossIcon.general.args.enable = {
        order = 0,
        type = "toggle",
        name = L["Enable"],
    }
    ConfigPrototypes.BossIcon.general.args.usePlaterBossIcon = {
        order = 2,
        type = "toggle",
        name = L["Use Plater Boss Icon"],
    }
    ConfigPrototypes.CastBarIcon = ConfigPrototypes:GetGeneralisedIconConfig()
    ConfigPrototypes.CastBarIcon.border = ConfigPrototypes:GetGeneralisedBorderConfig()
    ConfigPrototypes.CastBarIcon.background = ConfigPrototypes:GetGeneralisedBackgroundConfig()
    ConfigPrototypes.Target = {
        scale = {
            order = 0,
            type = "group",
            name = L["Scale"],
            args = {
                scalingFactor = {
                    order = 0,
                    type = "range",
                    width = "full",
                    name = L["Scaling Factor"],
                    min = 1, max = 2, step = 0.01,
                },
                threat = {
                    order = 1,
                    type = "toggle",
                    name = L["Threat Components"],
                },
                healthBar = {
                    order = 2,
                    type = "toggle",
                    name = L["Health Bar"],
                },
                castBar = {
                    order = 3,
                    type = "toggle",
                    name = L["Cast Bar"],
                },
                nameText = {
                    order = 4,
                    type = "toggle",
                    name = L["Name Text"],
                },
                levelText = {
                    order = 5,
                    type = "toggle",
                    name = L["Level Text"],
                },
                raidIcon = {
                    order = 6,
                    type = "toggle",
                    name = L["Raid Icon"],
                },
                bossIcon = {
                    order = 7,
                    type = "toggle",
                    name = L["Boss Icon"],
                },
                targetTargetText = {
                    order = 8,
                    type = "toggle",
                    name = L["Target-Target Text"],
                },
            },
        },
        border = {
            order = 1,
            type = "group",
            name = L["Border"],
            args = {
                indicator = {
                    order = 0,
                    type = "group",
                    name = L["Indicator"],
                    inline = true,
                    args = {
                        enable = {
                            order = 0,
                            type = "toggle",
                            name = L["Enable"],
                        },
                        selection = {
                            order = 1,
                            type = "select",
                            name = L["Selection"],
                            values = GetIndicators,
                        },
                        scale = {
                            order = 2,
                            type = "range",
                            name = L["Scale"],
                            min = 0.1, max = 5, step = 0.01,
                        },
                        useCustomColor = {
                            order = 3,
                            type = "toggle",
                            name = L["Use Custom Color"],
                        },
                        color = {
                            order = 4,
                            type = "color",
                            name = L["Color"],
                            hasAlpha = true,
                            disabled = function()
                                return not NotPlater.db.profile.target.border.indicator.useCustomColor
                            end,
                        },
                    },
                },
                highlight = {
                    order = 1,
                    type = "group",
                    name = L["Highlight"],
                    inline = true,
                    args = {
                        enable = {
                            order = 0,
                            type = "toggle",
                            name = L["Enable"],
                        },
                        color = {
                            order = 1,
                            type = "color",
                            name = L["Color"],
                            hasAlpha = true,
                        },
                        texture = {
                            order = 2,
                            type = "select",
                            name = L["Texture"],
                            values = NotPlater.targetHighlights,
                        },
                        thickness = {
                            order = 3,
                            type = "range",
                            name = L["Thickness"],
                            min = 1, max = 30, step = 1,
                        },
                    },
                },
                targetBorder = ConfigPrototypes:GetGeneralisedBorderConfig(),
            },
        },
        overlay = {
            order = 2,
            type = "group",
            name = L["Overlay"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
                color = {
                    order = 1,
                    type = "color",
                    name = L["Color"],
                    hasAlpha = true,
                },
                texture = {
                    order = 2,
                    type = "select",
                    name = L["Texture"],
                    values = GetTextures,
                },
            },
        },
        nonTargetAlpha = {
            order = 3,
            type = "group",
            name = L["Non-Target Alpha"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
                opacity = {
                    order = 1,
                    type = "range",
                    name = L["Opacity"],
                    min = 0, max = 0.98, step = 0.01,
                },
            },
        },
        nonTargetShading = {
            order = 4,
            type = "group",
            name = L["Non-Target Shading"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
                opacity = {
                    order = 1,
                    type = "range",
                    name = L["Opacity"],
                    min = 0, max = 1, step = 0.01,
                },
            },
        },
        mouseoverHighlight = {
            order = 5,
            type = "group",
            name = L["Mouseover Highlight"],
            args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
                opacity = {
                    order = 1,
                    type = "range",
                    name = L["Opacity"],
                    min = 0, max = 1, step = 0.01,
                },
                border = ConfigPrototypes:GetGeneralisedBorderConfig(),
            },
        },
    }
    ConfigPrototypes.Target.border.args.targetBorder.order = 2
    ConfigPrototypes.Target.border.args.targetBorder.name = L["Target Border"]
    ConfigPrototypes.TargetTargetText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.TargetTargetText.general.args.maxLetters = {
        order = 5,
        type = "range",
        name = L["Max. Letters"],
        min = 1, max = 100, step = 1,
    }
	local rangeStatusArgs = ConfigPrototypes:GetGeneralisedStatusBarConfig()
	rangeStatusArgs.position = ConfigPrototypes:GetGeneralisedPositionConfig()
	rangeStatusArgs.general.args.showProgress = {
		order = 3,
		type = "toggle",
		name = L["Show Progress"],
	}
	local rangeTextArgs = ConfigPrototypes:GetGeneralisedColorFontConfig()
	rangeTextArgs.general.args.format = {
		order = 1.5,
		type = "input",
		width = "full",
		name = L["Text Format"],
		desc = L["Use {range} to insert the current range value."],
	}
	ConfigPrototypes.Range = {
		statusBar = {
			order = 1,
			type = "group",
			name = L["Status Bar"],
			args = rangeStatusArgs,
		},
		text = {
			order = 2,
			type = "group",
			name = L["Text"],
			args = rangeTextArgs,
		},
		buckets = {
			order = 3,
			type = "group",
			name = L["Ranges"],
			args = {
                enable = {
                    order = 0,
                    type = "toggle",
                    name = L["Enable"],
                },
				range10 = {
					order = 1,
					type = "group",
					inline = true,
					name = L["0-10 Yards"],
                    args = {
                        statusBarColor = {
                            order = 0,
                            type = "color",
                            name = L["Status Bar Color"],
                            hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
                        },
						textColor = {
							order = 1,
							type = "color",
							name = L["Text Color"],
							hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
						},
					},
				},
				range20 = {
					order = 2,
					type = "group",
                    inline = true,
                    name = L["10-20 Yards"],
                    args = {
                        statusBarColor = {
                            order = 0,
                            type = "color",
                            name = L["Status Bar Color"],
                            hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
                        },
						textColor = {
							order = 1,
							type = "color",
							name = L["Text Color"],
							hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
						},
					},
				},
				range30 = {
					order = 3,
					type = "group",
                    inline = true,
                    name = L["20-30 Yards"],
                    args = {
                        statusBarColor = {
                            order = 0,
                            type = "color",
                            name = L["Status Bar Color"],
                            hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
                        },
						textColor = {
							order = 1,
							type = "color",
							name = L["Text Color"],
							hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
						},
					},
				},
				range40 = {
					order = 4,
					type = "group",
                    inline = true,
                    name = L["30-40 Yards"],
                    args = {
                        statusBarColor = {
                            order = 0,
                            type = "color",
                            name = L["Status Bar Color"],
                            hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
                        },
						textColor = {
							order = 1,
							type = "color",
							name = L["Text Color"],
							hasAlpha = true,
                            disabled = function() return not NotPlater.db.profile.range.buckets.enable end,
						},
					},
				},
			},
		},
	}
    ConfigPrototypes.Simulator = {
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
                },
                execSim = {
                    order = 1,
                    type = "execute",
                    name = L["Toggle Simulator Frame"],
                    func = function () NotPlater:ToggleSimulatorFrame() end,
                },
            },
        },
        size = ConfigPrototypes:GetGeneralisedSizeConfig()
    }
end

local function ValidateBuffsConfigAPI(api)
	if type(api) ~= "table" then
		error("Buffs config builder requires a dependency table.", 2)
	end
	local required = {
		"trackedUnitArgs",
		"GetFontValues",
		"BuffsGetValue",
		"BuffsSetValue",
		"BuffsGetColor",
		"BuffsSetColor",
		"GetSwipeTextureValues",
		"SetSwipeStyle",
		"IsSwipeTextureDisabled",
		"IsAuraFrame2Disabled",
		"IsAuraTimerDisabled",
		"IsAutomaticTracking",
		"BuildAuraListValues",
		"RemoveAuraFromList",
		"ShowAuraPrompt",
	}
	for _, key in ipairs(required) do
		if not api[key] then
			error(("Buffs config builder missing dependency: %s"):format(key), 2)
		end
	end
	return api
end

local function BuildAuraListGroup(order, listKey, name, addNameLabel, addIDLabel, api)
	return {
		order = order,
		type = "group",
		name = name,
		args = {
			entries = {
				order = 0,
				type = "multiselect",
				name = L["Click an entry to remove it."],
				values = function()
					return api.BuildAuraListValues(listKey)
				end,
				get = function()
					return false
				end,
				set = function(_, key)
					api.RemoveAuraFromList(listKey, key)
				end,
				width = "full",
			},
			addByName = {
				order = 1,
				type = "execute",
				name = addNameLabel,
				func = function()
					api.ShowAuraPrompt(listKey, "NAME")
				end,
			},
			addByID = {
				order = 2,
				type = "execute",
				name = addIDLabel,
				func = function()
					api.ShowAuraPrompt(listKey, "ID")
				end,
			},
		},
	}
end

function ConfigPrototypes:BuildBuffsArgs(api)
	api = ValidateBuffsConfigAPI(api)

	local function FrameDimension(frameKey, field, order, label, min, max, step, default, disabled)
		return {
			order = order,
			type = "range",
			name = label,
			min = min,
			max = max,
			step = step,
			get = function()
				return api.BuffsGetValue(frameKey, field) or default
			end,
			set = function(_, value)
				api.BuffsSetValue(value, frameKey, field)
			end,
			disabled = disabled,
		}
	end

	local function CreateAuraFrameGroup(order, frameKey, label, opts)
		opts = opts or {}
		local disabled = opts.disabled
		local function fieldOrder(value)
			if opts.includeEnable then
				return value + 1
			end
			return value
		end
		local groupArgs = {
			growDirection = { order = fieldOrder(0), type = "select", name = L["Grow Direction"], values = auraGrowthDirections, disabled = disabled },
			anchor = { order = fieldOrder(1), type = "select", name = L["Anchor"], values = anchors, disabled = disabled },
			xOffset = { order = fieldOrder(2), type = "range", name = L["X Offset"], min = -100, max = 100, step = 1, disabled = disabled },
			yOffset = { order = fieldOrder(3), type = "range", name = L["Y Offset"], min = -100, max = 100, step = 1, disabled = disabled },
			rowCount = FrameDimension(frameKey, "rowCount", fieldOrder(4), L["Auras per Row"], 1, 12, 1, 10, disabled),
			width = FrameDimension(frameKey, "width", 10, L["Width"], 10, 80, 1, 26, disabled),
			height = FrameDimension(frameKey, "height", 11, L["Height"], 10, 80, 1, 16, disabled),
			borderThickness = FrameDimension(frameKey, "borderThickness", 12, L["Border Thickness"], 0, 5, 0.1, 1, disabled),
		}

		if opts.includeEnable then
			groupArgs.enable = {
				order = 0,
				type = "toggle",
				name = L["Enable"],
				desc = opts.enableDescription,
			}
		end

		return {
			order = order,
			type = "group",
			inline = true,
			name = label,
			args = groupArgs,
		}
	end

	return {
		general = {
			order = 0,
			type = "group",
			name = L["General Settings"],
			args = {
				enable = { order = 0, type = "toggle", name = L["Enable"] },
				showTooltip = { order = 1, type = "toggle", name = L["Show Tooltip"] },
				alpha = { order = 2, type = "range", name = L["Opacity"], min = 0.1, max = 1, step = 0.05 },
				iconSpacing = { order = 3, type = "range", name = L["Icon Spacing"], min = 0, max = 20, step = 1 },
				rowSpacing = { order = 4, type = "range", name = L["Row Spacing"], min = 0, max = 20, step = 1 },
				stackSimilarAuras = { order = 5, type = "toggle", name = L["Stack Similar Auras"] },
				showShortestStackTime = { order = 6, type = "toggle", name = L["Show Shortest Remaining Time"] },
				sortAuras = { order = 7, type = "toggle", name = L["Sort Auras"] },
				showAnimations = { order = 8, type = "toggle", name = L["Show Animations"] },
				trackedUnits = {
					order = 9,
					type = "group",
					inline = true,
					name = L["Tracked Units"],
					args = api.trackedUnitArgs,
				},
				enableCombatLogTracking = {
					order = 10,
					type = "toggle",
					name = L["Combat Log Tracking"],
					desc = L["Learns aura durations from the combat log so timers persist after you stop targeting a unit. Timers may be inaccurate until the addon has seen an aura at least twice."],
				},
			},
		},
		frames = {
			order = 1,
			type = "group",
			name = L["Frames"],
			args = {
				auraFrame1 = CreateAuraFrameGroup(0, "auraFrame1", L["Aura Frame 1"]),
				auraFrame2 = CreateAuraFrameGroup(1, "auraFrame2", L["Aura Frame 2 (Buffs)"], {
					includeEnable = true,
					disabled = api.IsAuraFrame2Disabled,
					enableDescription = L["When enabled, debuffs are shown in Aura Frame 1 and buffs in Aura Frame 2."],
				}),
			},
		},
		stackCounter = {
			order = 2,
			type = "group",
			name = L["Stack Counter"],
			args = {
				general = {
					order = 0,
					type = "group",
					inline = true,
					name = L["General"],
					args = {
						enable = { order = 0, type = "toggle", name = L["Enable"] },
						name = { order = 1, type = "select", name = L["Font"], values = api.GetFontValues },
						size = { order = 2, type = "range", name = L["Size"], min = 6, max = 36, step = 1 },
						border = { order = 3, type = "select", name = L["Outline"], values = fontBorders },
						color = { order = 4, type = "color", name = L["Color"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
					},
				},
				position = {
					order = 1,
					type = "group",
					inline = true,
					name = L["Position"],
					args = {
						anchor = { order = 0, type = "select", name = L["Anchor"], values = anchors },
						xOffset = { order = 1, type = "range", name = L["X Offset"], min = -50, max = 50, step = 1 },
						yOffset = { order = 2, type = "range", name = L["Y Offset"], min = -50, max = 50, step = 1 },
					},
				},
				shadow = {
					order = 2,
					type = "group",
					inline = true,
					name = L["Shadow"],
					args = {
						enable = { order = 0, type = "toggle", name = L["Enable"] },
						color = { order = 1, type = "color", name = L["Color"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
						xOffset = { order = 2, type = "range", name = L["X Offset"], min = -5, max = 5, step = 0.1 },
						yOffset = { order = 3, type = "range", name = L["Y Offset"], min = -5, max = 5, step = 0.1 },
					},
				},
			},
		},
		auraTimer = {
			order = 3,
			type = "group",
			name = L["Aura Timer"],
			args = {
				general = {
					order = 0,
					type = "group",
					inline = true,
					name = L["General"],
					args = {
						enable = { order = 0, type = "toggle", name = L["Enable"] },
						showDecimals = { order = 1, type = "toggle", name = L["Show Decimals"] },
						hideExternalTimer = { order = 2, type = "toggle", name = L["Hide External Cooldown Text"], desc = L["Hide OmniCC/TullaCC text while the built-in timer is visible."] },
						name = { order = 3, type = "select", name = L["Font"], values = api.GetFontValues },
						size = { order = 4, type = "range", name = L["Size"], min = 6, max = 36, step = 1 },
						border = { order = 5, type = "select", name = L["Outline"], values = fontBorders },
						color = { order = 6, type = "color", name = L["Color"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
					},
				},
				position = {
					order = 1,
					type = "group",
					inline = true,
					name = L["Position"],
					disabled = api.IsAuraTimerDisabled,
					args = {
						anchor = { order = 0, type = "select", name = L["Anchor"], values = anchors },
						xOffset = { order = 1, type = "range", name = L["X Offset"], min = -50, max = 50, step = 1 },
						yOffset = { order = 2, type = "range", name = L["Y Offset"], min = -50, max = 50, step = 1 },
					},
				},
				shadow = {
					order = 2,
					type = "group",
					inline = true,
					name = L["Shadow"],
					disabled = api.IsAuraTimerDisabled,
					args = {
						enable = { order = 0, type = "toggle", name = L["Enable"] },
						color = { order = 1, type = "color", name = L["Color"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
						xOffset = { order = 2, type = "range", name = L["X Offset"], min = -5, max = 5, step = 0.1 },
						yOffset = { order = 3, type = "range", name = L["Y Offset"], min = -5, max = 5, step = 0.1 },
					},
				},
			},
		},
		swipeAnimation = {
			order = 4,
			type = "group",
			name = L["Swipe Animation"],
			args = {
				style = { order = 0, type = "select", name = L["Cooldown Style"], values = swipeStyleValues, set = api.SetSwipeStyle },
				texture = { order = 1, type = "select", name = L["Texture"], values = api.GetSwipeTextureValues, disabled = api.IsSwipeTextureDisabled },
				showSwipe = { order = 2, type = "toggle", name = L["Show Swipe"] },
				invertSwipe = { order = 3, type = "toggle", name = L["Invert Swipe"] },
			},
		},
		borderColors = {
			order = 5,
			type = "group",
			name = L["Aura Border Colors"],
			args = {
				useTypeColors = { order = 0, type = "toggle", name = L["Use Type Colors"] },
				dispellable = { order = 2, type = "color", name = L["Dispellable"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
				enrage = { order = 3, type = "color", name = L["Enrage"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
				buff = { order = 4, type = "color", name = L["Buff"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
				crowdControl = { order = 5, type = "color", name = L["Crowd Control"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
				offensiveCD = { order = 6, type = "color", name = L["Offensive Cooldown"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
				defensiveCD = { order = 7, type = "color", name = L["Defensive Cooldown"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
				default = { order = 8, type = "color", name = L["Default"], hasAlpha = true, get = api.BuffsGetColor, set = api.BuffsSetColor },
			},
		},
		tracking = {
			order = 6,
			type = "group",
			name = L["Tracking"],
			childGroups = "tab",
			args = {
				mode = {
					order = 0,
					type = "group",
					inline = true,
					name = L["Aura Tracking Method"],
					args = {
						mode = { order = 0, type = "select", name = L["Mode"], values = {AUTOMATIC = L["Automatic"], MANUAL = L["Manual"]} },
					},
				},
				automatic = {
					order = 1,
					type = "group",
					inline = true,
					name = L["Automatic Aura Tracking"],
					disabled = function()
						return not api.IsAutomaticTracking()
					end,
					args = {
						showPlayerAuras = { order = 0, type = "toggle", name = L["Show Player Auras"] },
						showOtherPlayerAuras = { order = 1, type = "toggle", name = L["Show Other Player Auras"] },
						showDispellableBuffs = { order = 3, type = "toggle", name = L["Show Dispellable Buffs"] },
						showEnrageBuffs = { order = 4, type = "toggle", name = L["Show Enrage Buffs"] },
						showMagicBuffs = { order = 5, type = "toggle", name = L["Show Magic Buffs"] },
						showCrowdControl = { order = 6, type = "toggle", name = L["Show Crowd Control"] },
						showNpcBuffs = { order = 7, type = "toggle", name = L["Show NPC Buffs"] },
						showNpcDebuffs = { order = 8, type = "toggle", name = L["Show NPC Debuffs"] },
						onlyShortDispellableOnPlayers = { order = 9, type = "toggle", name = L["Only Short Dispellable Buffs on Players"] },
						showOtherNPCAuras = { order = 10, type = "toggle", name = L["Show Other NPC Auras"] },
					},
				},
				blacklistDebuffs = BuildAuraListGroup(2, "blacklistDebuffs", L["Debuff Blacklist"], L["Add Debuff by Name"], L["Add Debuff by ID"], api),
				blacklistBuffs = BuildAuraListGroup(3, "blacklistBuffs", L["Buff Blacklist"], L["Add Buff by Name"], L["Add Buff by ID"], api),
				extraDebuffs = BuildAuraListGroup(4, "extraDebuffs", L["Extra Debuffs"], L["Add Debuff by Name"], L["Add Debuff by ID"], api),
				extraBuffs = BuildAuraListGroup(5, "extraBuffs", L["Extra Buffs"], L["Add Buff by Name"], L["Add Buff by ID"], api),
			},
		},
	}
end
