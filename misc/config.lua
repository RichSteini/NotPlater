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
local ipairs = ipairs
local unpack = unpack
local GameTooltip = GameTooltip
local SlashCmdList = SlashCmdList
local InterfaceOptionsFrame = InterfaceOptionsFrame
local UIParent = UIParent

local SML, registered, options, config, dialog

NotPlater.oppositeAnchors = {
	["LEFT"] = "RIGHT",
	["RIGHT"] = "LEFT",
	["CENTER"] = "CENTER",
	["BOTTOM"] = "TOP",
	["TOP"] = "BOTTOM",
	["TOPRIGHT"] = "BOTTOMLEFT",
	["BOTTOMLEFT"] = "TOPRIGHT",
	["TOPLEFT"] = "BOTTOMRIGHT",
	["BOTTOMRIGHT"] = "TOPLEFT",
}

local TEXTURE_BASE_PATH = [[Interface\Addons\NotPlater\images\statusbarTextures\]]
local textures = {"NotPlater Default", "NotPlater Background", "NotPlater HealthBar", "Flat", "BarFill", "Banto", "Smooth", "Perl", "Glaze", "Charcoal", "Otravi", "Striped", "LiteStep"}

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
	
	["Golden"] = {
		path = [[Interface\AddOns\NotPlater\images\targetBorders\Artifacts]],
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
	[HIGHLIGHT_BASE_PATH .. "selection_indicator1"] =  "Highlight 1",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator2"] =  "Highlight 2",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator3"] =  "Highlight 3",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator4"] =  "Highlight 4",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator5"] =  "Highlight 5",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator6"] =  "Highlight 6",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator7"] =  "Highlight 7",
	[HIGHLIGHT_BASE_PATH .. "selection_indicator8"] =  "Highlight 8"
}


local function GetAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hHalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vHalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vHalf..hHalf, frame, (vHalf == "TOP" and "BOTTOM" or "TOP")..hHalf
end

local function DrawMinimapTooltip()
    local tooltip = GameTooltip
    tooltip:ClearLines()
    tooltip:AddDoubleLine("NotPlater", NotPlater.revision or "2.0.0")
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
        DrawMinimapTooltip()
    end,
    OnEnter = function(self)
        local elapsed = 0
        local delay = 1
        tooltipUpdateFrame:SetScript("OnUpdate", function(self, elap)
            elapsed = elapsed + elap
            if(elapsed > delay) then
                elapsed = 0
                DrawMinimapTooltip()
            end
        end);
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(GetAnchors(self))
        DrawMinimapTooltip()
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

local function SetValue(...)
	local args = {}
	local numArgs = #...
	tinsert(args, NotPlater.db.profile)
	for k, v in ipairs(...) do
		tinsert(args, args[k][v])
	end
	local lastArgName = select(1, ...)[numArgs]
	local values = {select(2, ...)}
	if #values > 1 then
		args[numArgs][lastArgName] = values
	else
		args[numArgs][lastArgName] = select(2, ...)
	end
	NotPlater:Reload()
end

local function GetValue(...)
	local args = {}
	local numArgs = #...
	tinsert(args, NotPlater.db.profile)
	for k, v in ipairs(...) do
		tinsert(args, args[k][v])
	end
	if type(args[numArgs + 1]) == "table" then
		return unpack(args[numArgs + 1])
	else
		return args[numArgs + 1]
	end
end

local function LoadOptions()
	options = {}
	options.type = "group"
	options.name = "NotPlater"
	options.args = {}
	options.args.threat = {
		order = 0,
		type = "group",
		name = L["Threat"],
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
		handler = Config,
		args = {
			general = {
				order = 0,
				type = "group",
				name = L["General"],
				args = NotPlater.ConfigPrototypes.ThreatGeneral,
			},
			nameplateColors = {
				order = 1,
				type = "group",
				name = L["Nameplate Colors"],
				args = 	NotPlater.ConfigPrototypes.ThreatNameplateColors
			},
			percent = {
				order = 2,
				type = "group",
				name = L["Percent Status Bar/Text"],
				childGroups = "tab",
				args = {
					statusBar = {
						order = 0,
						type = "group",
						name = L["Status Bar"],
						args = 	NotPlater.ConfigPrototypes.ThreatPercentStatusBar,
					},
					text = {
						order = 1,
						type = "group",
						name = L["Text"],
						args = NotPlater.ConfigPrototypes.ThreatPercentText,
					},
				},
			},
			differentialText = {
				order = 3,
				type = "group",
				name = L["Differential Text"],
				args = NotPlater.ConfigPrototypes.ThreatDifferentialText,
			},
			numberText = {
				order = 4,
				type = "group",
				name = L["Number Text"],
				args = 	NotPlater.ConfigPrototypes.ThreatNumberText,
			}
		}
	}
	options.args.healthBar = {
		type = "group",
		order = 1,
		name = L["Health Bar"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		childGroups = "tab",
		args = {
			statusBar = {
				order = 0,
				type = "group",
				name = L["Status Bar"],
				args = NotPlater.ConfigPrototypes.HealthBar,
			},
			healthText = {
				order = 1,
				type = "group",
				name = L["Health Text"],
				args = NotPlater.ConfigPrototypes.HealthText
			},
		},
	}
	options.args.castBar = {
		type = "group",
		order = 2,
		name = L["Cast Bar"],
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
		handler = Config,
		args =  {
			statusBar = {
				order = 0,
				type = "group",
				name = L["Status Bar"],
				args = NotPlater.ConfigPrototypes.CastBar,
			},
			spellIcon = {
				order = 1,
				type = "group",
				name = L["Spell Icon"],
				args = NotPlater.ConfigPrototypes.Icon
			},
			spellTimeText = {
				order = 2,
				type = "group",
				name = L["Spell Time Text"],
				args = NotPlater.ConfigPrototypes.SpellTimeText
			},
			spellNameText = {
				order = 3,
				type = "group",
				name = L["Spell Name Text"],
				args = NotPlater.ConfigPrototypes.SpellNameText
			},
		},
	}
	options.args.nameText = {
		order = 3,
		type = "group",
		name = L["Name Text"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		args = NotPlater.ConfigPrototypes.NameText
	}
	options.args.levelText = {
		order = 4,
		type = "group",
		name = L["Level Text"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		args = NotPlater.ConfigPrototypes.LevelText
	}
	options.args.raidIcon = {
		order = 5,
		type = "group",
		name = L["Raid Icon"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		args = NotPlater.ConfigPrototypes.Icon
	}
	options.args.bossIcon = {
		order = 6,
		type = "group",
		name = L["Boss Icon"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		args = NotPlater.ConfigPrototypes.Icon
	}
	options.args.target = {
		order = 7,
		type = "group",
		name = L["Target"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		args = NotPlater.ConfigPrototypes.Target
	}
	options.args.stacking = {
		order = 8,
		type = "group",
		get = GetValue,
		set = SetValue,
		name = L["Stacking"],
		handler = Config,
		args = NotPlater.ConfigPrototypes.NameplateStacking,
	}
	options.args.simulator = {
		order = 9,
		type = "group",
		name = L["Simulator"],
		get = GetValue,
		set = SetValue,
		handler = Config,
		args = NotPlater.ConfigPrototypes.Simulator
	}

	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(NotPlater.db)
	options.args.profile.order = 10
end

function Config:ToggleConfig()
	if dialog.OpenFrames["NotPlater"] then
		if NotPlater.db.profile.simulator.general.showOnConfig then
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
			NotPlater.ConfigPrototypes:LoadConfigPrototypes()
			LoadOptions()
		end

		config:RegisterOptionsTable("NotPlater", options)
		dialog:SetDefaultSize("NotPlater", 850, 650)
		registered = true
	end
	if NotPlater.db.profile.simulator.general.showOnConfig then
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
	if not options then
		NotPlater.ConfigPrototypes:LoadConfigPrototypes()
		LoadOptions()
	end

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