if not NotPlater then return end

if not NotPlater then return end

function NotPlater:LoadDefaultConfig()
    self.defaults = {
        profile = {
            threat = {
                general = {
                    mode = "hdps",
                    enableMouseoverUpdate = true
                },
                nameplateColors = {
                    general = {
                        enable = true,
                        useClassColors = false,
                    },
                    colors = {
                        tank = {
                            c1 = {0.5, 0.5, 1, 1},
                            c2 = {1, 0.8, 0, 1},
                            c3 = {1, 0.109, 0, 1}
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
            healthBar = {
                statusBar = {
                    general = {
                        enable = true,
                        color = {0.5, 0.5, 1, 1},
                        texture = "NotPlater HealthBar",
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
                        color = {1, 1, 1, 1},
                        name = "Arial Narrow",
                        size = 10,
                        border = "OUTLINE",
                    },
                    position = {
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
                        opacity = 1
                    },
                    size = {
                        width = 14,
                        height = 14
                    },
                    position = {
                        anchor = "LEFT",
                        xOffset = 0,
                        yOffset = 0,
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
                    name = "Arial Narrow",
                    size = 11,
                    border = ""
                },
                position = {
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
                    name = "Arial Narrow",
                    opacity = 0.7,
                    size = 8,
                    border = ""
                },
                position = {
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
            raidIcon = {
                general = {
                    opacity = 1,
                },
                size = {
                    width = 20,
                    height = 20,
                },
                position = {
                    anchor = "LEFT",
                    xOffset = -5,
                    yOffset = 0,
                }
            },
            bossIcon = {
                general = {
                    opacity = 0,
                },
                size = {
                    width = 20,
                    height = 20,
                },
                position = {
                    anchor = "RIGHT",
                    xOffset = 5,
                    yOffset = 0,
                }
            },
            target = {
                general = {
                    scale = {
                        scalingFactor = 1.11,
                        threat = false,
                        healthBar = true,
                        castBar = true,
                        nameText = true,
                        levelText = false,
                        raidIcon = false,
                        bossIcon = false,
                        targetTargetText = false
                    },
                    border = {
                        indicator = {
                            enable = true,
                            selection = "Silver"
                        },
                        highlight = {
                            enable = true,
                            texture = [[Interface\AddOns\NotPlater\images\targetBorders\selection_indicator3]],
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
                        opacity = 0.5
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
            stacking = {
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
            simulator = {
                general = {
                    showOnConfig = true
                },
                size = {
                    width = 200,
                    height = 100
                },
            },
        },
    }
end