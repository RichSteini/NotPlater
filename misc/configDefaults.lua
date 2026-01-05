if not NotPlater then return end

local DEFAULT_STACKING_COMPONENTS = NotPlater.defaultStackingComponents or {
	"healthBar",
	"healthText",
	"nameText",
	"npcIcons",
	"castBar",
	"castSpellIcon",
	"castSpellNameText",
	"castSpellTimeText",
	"levelText",
	"targetOverlay",
	"targetIndicator",
	"targetHighlight",
	"targetBorder",
	"mouseoverHighlight",
	"bossIcon",
	"raidIcon",
	"eliteIcon",
	"classIcon",
	"factionIcon",
	"threatPercentBar",
	"threatPercentText",
	"threatDifferentialText",
	"threatNumberText",
	"targetTargetText",
	"aurasDebuffs",
	"aurasBuffs",
	"rangeStatusBar",
	"rangeText",
}

NotPlater.defaultStackingComponents = DEFAULT_STACKING_COMPONENTS

function NotPlater:LoadDefaultConfig()
	self.defaults = {
		global = {
			whatsNew = {
				lastSeenId = "",
				lastSeenRevision = "",
				suppressed = false,
			},
		},
		profile = {
            threat = {
                general = {
                    mode = "tank"
                },
                nameplateColors = {
                    general = {
                        enable = true,
                    },
                    colors = {
                        tank = {
                            c1 = {0.5, 0.5, 1, 1},
                            c2 = {1, 0.8, 0, 1},
                            c3 = {1, 0.109, 0, 1},
							c4 = {0.7, 0.7, 0.7, 1},
                        },
                        hdps = {
                            c1 = {1, 0.109, 0, 1},
                            c2 = { 1, 0.8, 0, 1},
                            c3 = {0.5, 0.5, 1, 1},
                        }
                    }
                },
                percent = {
                    statusBar = {
                        general = {
                            enable = false,
                            texture = "NotPlater Default",
                            color = {1, 0, 0, 1},
                            useThreatColors = true,
                        },
                        background = {
                            enable = true,
                            texture = "NotPlater Background",
                            color = {0, 0, 0, 0.3},
                        },
                        border = {
                            enable = true,
                            color = {0, 0, 0, 1},
                            thickness = 1,
                        },
                        size = {
                            width = 28,
                            height = 8,
                        },
                        position = {
							anchorTarget = "healthBar",
                            anchor = "TOPLEFT",
                            xOffset = 31,
                            yOffset = 4,
                        },
                        colors = {
                            tank = {
                                c1 = {0, 1, 0, 1},
                                c2 = {1, 0.65, 0, 1},
                                c3 = { 1, 0, 0, 1}
                            },
                            hdps = {
                                c1 = {1, 0, 0, 1},
                                c2 = {1, 0.65, 0, 1},
                                c3 = {0, 1, 0, 1},
                            }
                        },
                    },
                    text = {
                        general = {
                            enable = false,
                            name = "Arial Narrow",
                            size = 7,
                            border = "",
                            color = {0, 0, 0, 1},
                            useThreatColors = false,
                        },
                        position = {
							anchorTarget = "threatPercentBar",
                            anchor = "CENTER",
                            xOffset = 0,
                            yOffset = 0,
                        },
                        shadow = {
                            enable = false,
                            color = { r = 0, g = 0, b = 0, a = 1 },
                            xOffset = 0,
                            yOffset = 0,
                        },
                        colors = {
                            tank = {
                                c1 = {0, 1, 0, 1},
                                c2 = {1, 0.65, 0, 1},
                                c3 = { 1, 0, 0, 1}
                            },
                            hdps = {
                                c1 = {1, 0, 0, 1},
                                c2 = {1, 0.65, 0, 1},
                                c3 = {0, 1, 0, 1},
                            }
                        },
                    },
                },
                differentialText = {
                    general = {
                        enable = false,
                        name = "Arial Narrow",
                        size = 11,
                        border = "OUTLINE",
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "LEFT",
                        xOffset = -25,
                        yOffset = 0,
                    },
                    shadow = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        xOffset = 0,
                        yOffset = 0,
                    },
                    colors = {
                        tank = {
                            c1 = {0, 1, 0, 1},
                            c2 = {1, 0.65, 0, 1},
                            c3 = {1, 0, 0, 1}
                        },
                        hdps = {
                            c1 = {1, 0, 0, 1},
                            c2 = {1, 0.65, 0, 1},
                            c3 = {0, 1, 0, 1},
                        }
                    },
                },
                numberText = {
                    general = {
                        enable = false,
                        name = "Arial Narrow",
                        size = 20,
                        border = "",
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "RIGHT",
                        xOffset = 25,
                        yOffset = 0,
                    },
                    shadow = {
                        enable = false,
                        color = { r = 0, g = 0, b = 0, a = 1 },
                        xOffset = 0,
                        yOffset = 0,
                    },
                    colors = {
                        tank = {
                            c1 = {0, 1, 0, 1},
                            c2 = {1, 0.65, 0, 1},
                            c3 = { 1, 0, 0, 1}
                        },
                        hdps = {
                            c1 = {1, 0, 0, 1},
                            c2 = {1, 0.65, 0, 1},
                            c3 = {0, 1, 0, 1},
                        }
                    },
                },
            },
            range = {
                statusBar = {
                    general = {
                        enable = false,
                        color = {0.3, 0.6, 1, 1},
                        texture = "NotPlater Default",
                        showProgress = true,
                    },
                    background = {
                        enable = true,
                        color = {0, 0, 0, 0.4},
                        texture = "NotPlater Background",
                    },
                    size = {
                        width = 40,
                        height = 10,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "RIGHT",
                        xOffset = 5,
                        yOffset = 0,
                    },
                    border = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        thickness = 1,
                    },
                },
				text = {
					general = {
						enable = false,
						color = {1, 1, 1, 1},
						name = "Arial Narrow",
						size = 10,
						border = "OUTLINE",
						format = "{range} Yards",
					},
					position = {
						anchorTarget = "healthBar",
						anchor = "RIGHT",
						xOffset = 45,
						yOffset = 0,
                    },
                    shadow = {
                        enable = false,
                        color = {0, 0, 0, 1 },
                        xOffset = 0,
                        yOffset = 0
                    }
				},
				buckets = {
					enable = true,
					range10 = {
						max = 10,
						statusBarColor = {0.3, 0.9, 0.3, 1},
						textColor = {1, 1, 1, 1}
                    },
                    range20 = {
                        max = 20,
                        statusBarColor = {1, 0.9, 0.2, 1},
                        textColor = {1, 1, 1, 1}
                    },
                    range30 = {
                        max = 30,
                        statusBarColor = {1, 0.6, 0, 1},
                        textColor = {1, 1, 1, 1}
                    },
                    range40 = {
                        max = 40,
                        statusBarColor = {1, 0.2, 0.2, 1},
                        textColor = {1, 1, 1, 1}
                    },
                },
            },
            healthBar = {
                statusBar = {
                    general = {
                        enable = true,
                        color = {0.5, 0.5, 1, 1},
                        texture = "NotPlater HealthBar",
                        useClassColors = false,
                    },
                    background = {
                        enable = true,
                        color = {0.1, 0.1, 0.1, 0.8},
                        texture = "NotPlater Background",
                    },
                    size = {
                        width = 112,
                        height = 14,
                    },
                    border = {
                        enable = true,
                        color = {0, 0, 0, 0.8},
                        thickness = 1
                    },
                },
                healthText = {
                    general = {
                        enable = true,
                        displayType = "both",
                        showDecimalNumbers = true,
                        showDecimalPercent = false,
                        color = {1, 1, 1, 1},
                        name = "Arial Narrow",
                        size = 10,
                        border = "OUTLINE",
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "CENTER",
                        xOffset = 0,
                        yOffset = 0,
                    },
                    shadow = {
                        enable = false,
                        color = {0, 0, 0, 1 },
                        xOffset = 0,
                        yOffset = 0
                    }
                },
            },
            castBar = {
                statusBar = {
                    general = {
                        enable = true,
                        texture = "NotPlater Default",
                        color = {0.765, 0.525, 0, 1},
                    },
                    background = {
                        enable = true,
                        texture = "NotPlater Background",
                        color = {0.1, 0.1, 0.1, 0.8},
                    },
                    size = {
                        width = 112,
                        height = 14,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "BOTTOM",
                        xOffset = 0,
                        yOffset = -1,
                    },
                    border = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        thickness = 1
                    },
				},
				spellIcon = {
					general = {
						enable = true,
						opacity = 1
					},
                    size = {
                        width = 14,
                        height = 14
                    },
                    position = {
						anchorTarget = "castBar",
                        anchor = "LEFT",
                        xOffset = 0,
                        yOffset = 0,
                    },
                    border = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        thickness = 1,
						style = "",
						iconZoom = 65,
                    },
                    background = {
                        enable = false,
                        texture = "NotPlater Background",
                        color = {0.5, 0.5, 0.5, 0.8},
                    }
                },
                spellTimeText = {
                    general = {
                        enable = true,
                        displayType = "timeleft",
                        color = {1, 1, 1, 1},
                        size = 10,
                        border = "OUTLINE",
                        name = "Arial Narrow"
                    },
                    position = {
						anchorTarget = "castBar",
                        anchor = "RIGHT",
                        xOffset = 0,
                        yOffset = 0
                    },
                    shadow = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        xOffset = 0,
                        yOffset = 0
                    }
                },
                spellNameText = {
                    general = {
                        enable = true,
                        color = {1, 1, 1, 1},
                        name = "Arial Narrow",
                        size = 10,
                        border = "OUTLINE",
                        maxLetters = 10,
                    },
                    position = {
						anchorTarget = "castBar",
                        anchor = "CENTER",
                        xOffset = 0,
                        yOffset = 0,
                    },
                    shadow = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        xOffset = 0,
                        yOffset = 0
                    }
                },
			},
			nameText = {
				general = {
					enable = true,
					useClassColor = false,
					color = {1, 1, 1, 1},
					name = "Arial Narrow",
					size = 11,
					border = "",
					maxLetters = 80,
				},
                position = {
					anchorTarget = "healthBar",
                    anchor = "BOTTOM",
                    xOffset = 0,
                    yOffset = -12
                },
                shadow = {
                    enable = true,
                    color = {0, 0, 0, 1},
                    xOffset = 0,
                    yOffset = 0
                }
            },
			levelText = {
				general = {
					enable = true,
					useCustomColor = false,
					color = {1, 1, 1, 1},
					name = "Arial Narrow",
					opacity = 0.7,
					size = 8,
					border = ""
				},
                position = {
					anchorTarget = "healthBar",
                    anchor = "TOPRIGHT",
                    xOffset = -2,
                    yOffset = 10 
                },
                shadow = {
                    enable = true,
                    color = {0, 0, 0, 1},
                    xOffset = 0,
                    yOffset = 0
                }
            },
            icons = {
                raidIcon = {
                    general = {
						enable = true,
                        opacity = 1,
                    },
                    size = {
                        width = 20,
                        height = 20,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "RIGHT",
                        xOffset = 5,
                        yOffset = 0,
                    }
                },
                bossIcon = {
                    general = {
						enable = true,
                        opacity = 1,
                    },
                    size = {
                        width = 16,
                        height = 16,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "LEFT",
                        xOffset = -20,
                        yOffset = 0,
                    }
                },
                eliteIcon = {
                    general = {
						enable = true,
                        opacity = 1,
                    },
                    size = {
                        width = 12,
                        height = 12,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "LEFT",
                        xOffset = -5,
                        yOffset = 0,
                    }
                },
                classIcon = {
                    general = {
						enable = false,
                        opacity = 1,
                    },
                    size = {
                        width = 16,
                        height = 16,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "LEFT",
                        xOffset = 16,
                        yOffset = 0,
                    }
                },
                factionIcon = {
                    general = {
						enable = true,
                        opacity = 1,
                    },
                    size = {
                        width = 12,
                        height = 12,
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "TOPLEFT",
                        xOffset = 6,
                        yOffset = -6,
                    }
                },
                npcIcons = {
                    general = {
                        enable = true,
                        opacity = 1,
                        iconSpacing = 1,
                        rowSpacing = 1,
                    },
                    layout = {
                        growDirection = "RIGHT",
						anchorTarget = "nameText",
                        anchor = "RIGHT",
                        xOffset = 4,
                        yOffset = -1,
                        iconsPerRow = 7,
                        width = 10,
                        height = 10,
                    },
				icons = {
					vendor = true,
					banker = true,
					repair = true,
					innkeeper = true,
					flightMaster = true,
					auctioneer = true,
					classTrainer = true,
                    },
                },
            },
            filters = {
                list = {},
            },
            target = {
                scale = {
                    scalingFactor = 1.11,
                    threat = false,
                    healthBar = true,
                    castBar = true,
                    nameText = true,
                    levelText = false,
                    raidIcon = false,
                    bossIcon = false,
                    eliteIcon = false,
                    classIcon = false,
                    factionIcon = false,
                    npcIcons = false,
                    targetTargetText = false
                },
				border = {
					indicator = {
						enable = true,
						selection = "Silver",
						scale = 1,
						useCustomColor = false,
						color = {1, 1, 1, 1},
					},
					targetBorder = {
						enable = false,
						color = {1, 0.8, 0, 1},
						thickness = 2
                    },
                    highlight = {
                        enable = true,
                        texture = NotPlater.defaultHighlightTexture,
                        color = {0, 0.521568, 1, 0.75},
                        thickness = 14
                    },
                },
                overlay = {
                    enable = true,
                    texture = "Flat",
                    color = {1, 1, 1, 0.05}
                },
                nonTargetAlpha = {
                    enable = true,
                    opacity = 0.95
                },
                nonTargetShading = {
                    enable = true,
                    opacity = 0.4
                },
                mouseoverHighlight = {
                    enable = true,
                    opacity = 0.5,
                    border = {
                        enable = false,
                        color = {1, 1, 1, 1},
                        thickness = 2
                    },
                },
                targetTargetText = {
                    general = {
                        enable = false,
                        color = {1, 1, 1, 1},
                        name = "Arial Narrow",
                        size = 8,
                        border = "",
                        maxLetters = 6
                    },
                    position = {
						anchorTarget = "healthBar",
                        anchor = "CENTER",
                        xOffset = 44,
                        yOffset = -3,
                    },
                    shadow = {
                        enable = false,
                        color = {0, 0, 0, 1},
                        xOffset = 0,
                        yOffset = 0
                    }
                },
            },
			buffs = {
				general = {
					enable = true,
					showTooltip = false,
					alpha = 0.85,
                    iconSpacing = 1,
                    rowSpacing = 12,
					stackSimilarAuras = false,
					showShortestStackTime = true,
					sortAuras = false,
					showAnimations = true,
					enableCombatLogTracking = true,
				},
                auraFrame1 = {
                    growDirection = "CENTER",
					anchorTarget = "healthBar",
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 20,
                    rowCount = 10,
                    width = 26,
                    height = 16,
                    borderThickness = 1,
					iconZoom = 100,
                },
                auraFrame2 = {
                    enable = false,
                    growDirection = "CENTER",
					anchorTarget = "aurasDebuffs",
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 10,
                    rowCount = 10,
                    width = 26,
                    height = 16,
                    borderThickness = 1,
					iconZoom = 100,
                },
				border = {
					style = "SQUARE",
				},
                stackCounter = {
                    general = {
                        enable = true,
                        name = "Arial Narrow",
                        size = 10,
                        border = "OUTLINE",
                        color = {1, 1, 1, 1},
                    },
                    position = {
						anchorTarget = "auraIcon",
                        anchor = "TOP",
                        xOffset = 0,
                        yOffset = 0,
                    },
                    shadow = {
                        enable = true,
                        color = {0, 0, 0, 1},
                        xOffset = 0,
                        yOffset = 0,
                    },
                },
                auraTimer = {
                    general = {
                        enable = true,
                        showDecimals = false,
                        hideExternalTimer = true,
                        name = "Arial Narrow",
                        size = 15,
                        border = "OUTLINE",
                        color = {1, 1, 1, 1},
                    },
                    position = {
						anchorTarget = "auraIcon",
                        anchor = "CENTER",
                        xOffset = 0,
                        yOffset = 0,
                    },
                    shadow = {
                        enable = true,
                        color = {0, 0, 0, 1},
                        xOffset = 0,
                        yOffset = 0,
                    },
                },
                swipeAnimation = {
                    style = "vertical",
                    texture = "Texture 2",
                    showSwipe = true,
                    invertSwipe = true,
                },
				borderColors = {
					useTypeColors = false,
					dispellable = {0, 0.5, 0.98, 1},
					enrage = {0.85, 0.2, 0.1, 1},
					buff = {0, 0.65, 0.1, 1},
					crowdControl = {0.3, 0.2, 0.2, 1},
					offensiveCD = {0.0, 0.65, 0.1, 1},
                    defensiveCD = {0.85, 0.45, 0.1, 1},
                    default = {0, 0, 0, 1},
                },
					tracking = {
						mode = "AUTOMATIC",
						automatic = {
						showPlayerAuras = true,
						showOtherPlayerAuras = false,
						showDispellableBuffs = true,
						onlyShortDispellableOnPlayers = false,
						showEnrageBuffs = true,
						showMagicBuffs = true,
						showCrowdControl = true,
						showNpcBuffs = true,
						showNpcDebuffs = true,
						showOtherNPCAuras = true,
					},
					units = {
						target = true,
						focus = true,
						mouseover = true,
						arena = false,
					},
				},
                blacklistDebuffs = {},
                blacklistBuffs = {},
                extraDebuffs = {},
                extraBuffs = {},
            },
			stacking = {
				componentOrdering = {
					components = CopyTable and CopyTable(DEFAULT_STACKING_COMPONENTS) or {unpack(DEFAULT_STACKING_COMPONENTS)},
				},
				stackingSettings = {
					general = {
						enable = false,
						overlappingCastbars = true,
					},
					margin = {
						xStacking = 0,
						yStacking = 0,
					},
					frameStrata = {
						normalFrame = "LOW",
						targetFrame = "MEDIUM"
					},
				},
			},
            simulator = {
                general = {
                    showOnConfig = true
                },
                size = {
                    width = 240,
                    height = 140
                },
            },
        },
    }
end
