if not NotPlater then return end

local L = NotPlaterLocals
local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick Outline"], ["MONOCHROME"] = L["Monochrome"]}
local anchors = {["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOP"] = L["Top"], ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["BOTTOMLEFT"] = L["Bottom Left"], ["TOPRIGHT"] = L["Top Right"], ["BOTTOMRIGHT"] = L["Bottom Right"], ["TOPLEFT"] = L["Top Left"]}
local frameStratas = {["BACKGROUND"] = L["Background"], ["LOW"] = L["Low"], ["MEDIUM"] = L["Medium"], ["HIGH"] = L["High"], ["DIALOG"] = L["Dialog"], ["FULLSCREEN"] = L["Fullscreen"], ["FULLSCREEN_DIALOG"] = L["Fullscreen Dialog"], ["TOOLTIP"] = L["Tooltip"]}
local drawLayers = {["BACKGROUND"] = L["Background"], ["BORDER"] = L["Border"], ["ARTWORK"] = L["Artwork"], ["OVERLAY"] = L["Overlay"], ["HIGHLIGHT"] = L["Highlight"]}

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
                min = 0, max = 500, step = 1,
            },
            height = {
                order = 1,
                type = "range",
                name = L["Height"],
                min = 0, max = 500, step = 1,
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
    ConfigPrototypes.NameplateStacking = {
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
                    order = 0,
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
    }
    ConfigPrototypes.ThreatGeneral = {
        mode = {
            order = 0,
            type = "select",
            name = L["Mode"],
            values = {["hdps"] = L["Healer / DPS"], ["tank"] = L["Tank"]},
        },
        enableMouseoverUpdate = {
            order = 1,
            type = "toggle",
            name = L["Enable Mouseover Nameplate Threat Update"],
            width = "double",
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
                useClassColors = {
                    order = 0,
                    type = "toggle",
                    width = "double",
                    name = L["Use Class Colors when Possible"],
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
        min = 1, max = 40, step = 1,
    }
    ConfigPrototypes.HealthBar = ConfigPrototypes:GetGeneralisedStatusBarConfig()
    ConfigPrototypes.HealthText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.HealthText.general.args.displayType = {
        order = 1,
        type = "select",
        name = L["Display Type"],
        values = {["none"] = L["None"], ["minmax"] = L["Min / Max"], ["both"] = L["Both"], ["percent"] = L["Percent"]},
    }
    ConfigPrototypes.NameText = ConfigPrototypes:GetGeneralisedFontConfig()
    ConfigPrototypes.LevelText = ConfigPrototypes:GetGeneralisedFontConfig()
    ConfigPrototypes.LevelText.general.args.opacity = {
        order = 1,
        type = "range",
        name = L["Opacity"],
        min = 0, max = 1, step = 0.01,
    }
    ConfigPrototypes.Icon = ConfigPrototypes:GetGeneralisedIconConfig()
    ConfigPrototypes.CastBarIcon = ConfigPrototypes:GetGeneralisedIconConfig()
    ConfigPrototypes.CastBarIcon.border = ConfigPrototypes:GetGeneralisedBorderConfig()
    ConfigPrototypes.CastBarIcon.background = ConfigPrototypes:GetGeneralisedBackgroundConfig()
    ConfigPrototypes.Target = {
        scale = {
            order = 0,
            type = "group",
            name = L["Scale"],
            inline = true,
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
            inline = true,
            args = {
                indicator = {
                    order = 0,
                    type = "group",
                    name = L["Indicator"],
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
                    },
                },
                highlight = {
                    order = 1,
                    type = "group",
                    name = L["Highlight"],
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
            },
        },
        overlay = {
            order = 2,
            type = "group",
            name = L["Overlay"],
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
                    values = GetTextures,
                },
            },
        },
        nonTargetAlpha = {
            order = 3,
            type = "group",
            name = L["Non-Target Alpha"],
            inline = true,
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
            inline = true,
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
            inline = true,
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
    }
    ConfigPrototypes.TargetTargetText = ConfigPrototypes:GetGeneralisedColorFontConfig()
    ConfigPrototypes.TargetTargetText.general.args.maxLetters = {
        order = 5,
        type = "range",
        name = L["Max. Letters"],
        min = 1, max = 40, step = 1,
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