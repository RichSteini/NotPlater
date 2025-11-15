if not NotPlater then return end

local Config = NotPlater:NewModule("Config")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local registry = LibStub("AceConfigRegistry-3.0")
local L = NotPlaterLocals

local addonName = ...
if type(addonName) ~= "string" or addonName == "" then
	addonName = (NotPlater and NotPlater.addonName) or "NotPlater"
else
	NotPlater.addonName = addonName
end

local ADDON_BASE_PATH = ("Interface\\AddOns\\%s\\"):format(addonName)

local ssplit = string.split
local sgmatch = string.gmatch
local sformat = string.format
local slower = string.lower
local tinsert = table.insert
local tconcat = table.concat
local tonumber = tonumber
local ipairs = ipairs
local unpack = unpack
local GameTooltip = GameTooltip
local SlashCmdList = SlashCmdList
local InterfaceOptionsFrame = InterfaceOptionsFrame
local UIParent = UIParent

local SML, registered, options, config, dialog

local function BuildAssetPath(...)
	local segments = {...}
	for index = 1, #segments do
		local segment = tostring(segments[index] or "")
		segment = segment:gsub("^\\+", "")
		segment = segment:gsub("/", "\\")
		segments[index] = segment
	end
	return ADDON_BASE_PATH .. tconcat(segments, "\\")
end

NotPlater.BuildAssetPath = NotPlater.BuildAssetPath or BuildAssetPath

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

local TEXTURE_BASE_PATH = BuildAssetPath("images", "statusbarTextures") .. "\\"
local textures = {"NotPlater Default", "NotPlater Background", "NotPlater HealthBar", "Flat", "BarFill", "Banto", "Smooth", "Perl", "Glaze", "Charcoal", "Otravi", "Striped", "LiteStep"}

local CATEGORY_ICON_SIZE = 18
local CATEGORY_ICONS = {
	threat = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
	healthBar = "Interface\\Icons\\Spell_Holy_FlashHeal",
	castBar = "Interface\\Icons\\Spell_Frost_Frostbolt02",
	nameText = "Interface\\Icons\\INV_Scroll_03",
	levelText = "Interface\\Icons\\INV_Misc_Note_01",
	raidIcon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
	bossIcon = "Interface\\Icons\\Achievement_Boss_Ragnaros",
	target = "Interface\\Icons\\Ability_Hunter_SniperShot",
	buffs = "Interface\\Icons\\Spell_Holy_WordFortitude",
	stacking = "Interface\\Icons\\Ability_Warrior_SavageBlow",
	simulator = "Interface\\Icons\\INV_Gizmo_01",
	profile = "Interface\\Icons\\INV_Misc_Note_06",
}

local function WithCategoryIcon(key, label)
	if not label then
		return label
	end
	local texture = CATEGORY_ICONS[key]
	if texture then
		return sformat("|T%s:%d:%d:0:0|t %s", texture, CATEGORY_ICON_SIZE, CATEGORY_ICON_SIZE, label)
	end
	return label
end

NotPlater.defaultHighlightTexture = BuildAssetPath("images", "targetBorders", "selection_indicator3")
NotPlater.targetIndicators = {
	["NONE"] = {
		path = BuildAssetPath("images", "targetBorders", "UI-Achievement-WoodBorder-Corner"),
		coords = {{.9, 1, .9, 1}, {.9, 1, .9, 1}, {.9, 1, .9, 1}, {.9, 1, .9, 1}}, --texcoords, support 4 or 8 coords method
		desaturated = false,
		width = 10,
		height = 10,
		x = 1,
		y = 1,
	},
	
	["Magneto"] = {
		path = BuildAssetPath("images", "targetBorders", "RelicIconFrame"),
		coords = {{0, .5, 0, .5}, {0, .5, .5, 1}, {.5, 1, .5, 1}, {.5, 1, 0, .5}},
		desaturated = false,
		width = 8,
		height = 10,
		autoScale = true,
		x = 2,
		y = 2,
	},
	
	["Gray Bold"] = {
		path = BuildAssetPath("images", "targetBorders", "UI-Icon-QuestBorder"),
		coords = {{0, .5, 0, .5}, {0, .5, .5, 1}, {.5, 1, .5, 1}, {.5, 1, 0, .5}},
		desaturated = true,
		width = 10,
		height = 10,
		autoScale = true,
		x = 2,
		y = 2,
	},
	
	["Pins"] = {
		path = BuildAssetPath("images", "targetBorders", "UI-ItemSockets"),
		coords = {{145/256, 161/256, 3/256, 19/256}, {145/256, 161/256, 19/256, 3/256}, {161/256, 145/256, 19/256, 3/256}, {161/256, 145/256, 3/256, 19/256}},
		desaturated = 1,
		width = 4,
		height = 4,
		autoScale = false,
		x = 2,
		y = 2,
	},

	["Silver"] = {
		path = BuildAssetPath("images", "targetBorders", "PETBATTLEHUD"),
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
		path = BuildAssetPath("images", "targetBorders", "PETJOURNAL"),
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
		path = BuildAssetPath("images", "targetBorders", "Artifacts"),
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
		path = BuildAssetPath("images", "targetBorders", "challenges-besttime-bg"),
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
		path = BuildAssetPath("images", "targetBorders", "WowUI_Horizontal_Frame"),
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
        path = BuildAssetPath("images", "targetBorders", "arrow_single_right_64"),
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
        path = BuildAssetPath("images", "targetBorders", "arrow_thin_right_64"),
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
        path = BuildAssetPath("images", "targetBorders", "arrow_double_right_64"),
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

local HIGHLIGHT_BASE_PATH = BuildAssetPath("images", "targetBorders") .. "\\"
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


local fontBorders = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick Outline"], ["MONOCHROME"] = L["Monochrome"]}
local anchorPoints = {
	["CENTER"] = L["Center"], ["BOTTOM"] = L["Bottom"], ["TOP"] = L["Top"],
	["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["BOTTOMLEFT"] = L["Bottom Left"],
	["TOPRIGHT"] = L["Top Right"], ["BOTTOMRIGHT"] = L["Bottom Right"], ["TOPLEFT"] = L["Top Left"]
}
local auraGrowthDirections = {["LEFT"] = L["Left"], ["RIGHT"] = L["Right"], ["CENTER"] = L["Center"]}

NotPlater.auraSwipeTextures = NotPlater.auraSwipeTextures or {
	["Texture 1"] = BuildAssetPath("images", "cooldownTextures", "cooldown_edge_1"),
	["Texture 2"] = BuildAssetPath("images", "cooldownTextures", "cooldown_edge_2"),
	["Texture 3"] = "Interface\\Cooldown\\edge",
	["Texture 4"] = "Interface\\Cooldown\\edge-LoC",
	["Texture 5"] = BuildAssetPath("images", "cooldownTextures", "transparent"),
}
local auraSwipeTextures = NotPlater.auraSwipeTextures

local trackedUnitOptions = {
	target = L["Target"],
	focus = L["Focus"],
	mouseover = L["Mouseover"],
	arena = L["Arena"],
}

local auraPopupContext

local function TraverseBuffDB(info)
	if not NotPlater.db or not NotPlater.db.profile then return end
	local db = NotPlater.db.profile.buffs
	if not db then return end
	for i = 2, #info - 1 do
		local key = info[i]
		if key ~= "frames" then
			db = db and db[key]
		end
	end
	if not db then return end
	return db, info[#info]
end

local function GetFontValues()
	local media = NotPlater.SML or SML or LibStub("LibSharedMedia-3.0", true)
	local fonts = {}
	if media then
		for _, name in ipairs(media:List(media.MediaType.FONT)) do
			fonts[name] = name
		end
	end
	return fonts
end

local function GetSwipeTextureValues()
	local values = {}
	for name in pairs(auraSwipeTextures) do
		values[name] = name
	end
	return values
end

local swipeStyleValues = {
	vertical = L["Top to Bottom"],
	swirl = L["Swirl"],
}

local function IsSwipeTextureDisabled(info)
	local db = TraverseBuffDB(info)
	db.swipeAnimation = db.swipeAnimation or {}
	return (db.swipeAnimation.style or "vertical") ~= "swirl"
end

local function NotifyAuraOptions()
	if registry then
		registry:NotifyChange("NotPlater")
	end
end

local function RefreshAuraModule()
	local module = NotPlater.GetAuraModule and NotPlater:GetAuraModule()
	if module and module.ApplyProfile then
		module:ApplyProfile()
	end
end

local function BuffsSet(info, ...)
	local db, key = TraverseBuffDB(info)
	if not db or not key then return end
	local valueCount = select("#", ...)
	if valueCount > 1 then
		db[key] = {...}
	else
		db[key] = select(1, ...)
	end
	RefreshAuraModule()
	NotifyAuraOptions()
end

local function BuffsGet(info)
	local db, key = TraverseBuffDB(info)
	if not db or not key then return end
	local value = db[key]
	if type(value) == "table" and type(value[1]) == "number" then
		return unpack(value)
	end
	return value
end

local function BuildBuffInfo(...)
	local info = {"buffs"}
	for i = 1, select("#", ...) do
		info[#info + 1] = select(i, ...)
	end
	return info
end

local function BuffsGetValue(...)
	return BuffsGet(BuildBuffInfo(...))
end

local function BuffsSetValue(value, ...)
	BuffsSet(BuildBuffInfo(...), value)
end

local trackedUnitOrder = {"target", "focus", "mouseover", "arena"}

local function GetTrackedUnitOption(info)
	local unit = info[#info]
	return BuffsGetValue("tracking", "units", unit) ~= false
end

local function SetTrackedUnitOption(info, value)
	local unit = info[#info]
	BuffsSetValue(value, "tracking", "units", unit)
end

local trackedUnitArgs = {
	description = {
		order = 0,
		type = "description",
		name = L["Choose which unit IDs NotPlater polls with UnitAura. Only these units provide exact aura timers when combat log tracking is disabled."],
		fontSize = "medium",
	},
}

for order, unitID in ipairs(trackedUnitOrder) do
	trackedUnitArgs[unitID] = {
		order = order,
		type = "toggle",
		name = trackedUnitOptions[unitID],
		get = GetTrackedUnitOption,
		set = SetTrackedUnitOption,
		width = "half",
	}
end

local function BuffsGetWithDefaults(info)
	local value = BuffsGet(info)
	local key = info[#info]
	if value == nil then
		if key == "growDirection" then
			return "RIGHT"
		elseif key == "anchor" then
			return "TOP"
		elseif key == "mode" then
			return "AUTOMATIC"
		elseif key == "showSwipe" then
			return true
		elseif key == "invertSwipe" then
			return false
		end
	end
	return value
end

local function BuffsGetColor(info)
	local r, g, b, a = BuffsGet(info)
	if r == nil then
		return 1, 1, 1, 1
	end
	return r or 1, g or 1, b or 1, a or 1
end

local function BuffsSetColor(info, r, g, b, a)
	BuffsSet(info, r or 1, g or 1, b or 1, a or 1)
end

local function GetAuraList(listKey)
	if not NotPlater.db or not NotPlater.db.profile then return {} end
	local profile = NotPlater.db.profile
	profile.buffs = profile.buffs or {}
	profile.buffs.tracking = profile.buffs.tracking or {}
	profile.buffs.tracking.lists = profile.buffs.tracking.lists or {}
	profile.buffs.tracking.lists[listKey] = profile.buffs.tracking.lists[listKey] or {}
	return profile.buffs.tracking.lists[listKey]
end

local function BuildAuraListValues(listKey)
	local values = {}
	local list = GetAuraList(listKey)
	for index, data in ipairs(list) do
		local icon = data.icon or "Interface\\Icons\\INV_Misc_QuestionMark"
		local spellName = data.name or L["Unknown"]
		local spellID = data.spellID or 0
		values[index] = sformat("|T%s:16:16:0:0:64:64:4:60:4:60|t %s (%d)", icon, spellName, spellID)
	end
	return values
end

local function RemoveAuraFromList(listKey, entryIndex)
	local list = GetAuraList(listKey)
	local numericIndex = tonumber(entryIndex)
	if numericIndex and list[numericIndex] then
		tremove(list, numericIndex)
		RefreshAuraModule()
		NotifyAuraOptions()
	end
end

local function ResolveSpell(token)
	if not token or token == "" then
		return
	end
	local lookup = tonumber(token) or token
	local name, _, icon, _, _, _, spellID = GetSpellInfo(lookup)
	if not name then
		return
	end
	return spellID or tonumber(token), name, icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function AuraEntriesMatch(entry, spellID, name)
	if not entry then
		return false
	end
	if spellID and spellID ~= 0 and entry.spellID and entry.spellID ~= 0 and entry.spellID == spellID then
		return true
	end
	if name and name ~= "" and entry.name and entry.name ~= "" then
		if slower(entry.name) == slower(name) then
			return true
		end
	end
	return false
end

local function AddAuraToList(listKey, token)
	local spellID, name, icon = ResolveSpell(token)
	if not spellID then
		NotPlater:Print(L["Invalid spell name or ID"])
		return
	end
	local list = GetAuraList(listKey)
	for _, entry in ipairs(list) do
		if AuraEntriesMatch(entry, spellID, name) then
			entry.spellID = spellID
			entry.name = name
			entry.icon = icon
			RefreshAuraModule()
			NotifyAuraOptions()
			return
		end
	end
	tinsert(list, { spellID = spellID, name = name, icon = icon })
	RefreshAuraModule()
	NotifyAuraOptions()
end

local function IsAuraFrame2Disabled()
	return not (NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.buffs and NotPlater.db.profile.buffs.auraFrame2.enable)
end

local function IsAuraTimerDisabled()
	return not (NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.buffs and NotPlater.db.profile.buffs.auraTimer.general.enable)
end

local function IsAutomaticTracking()
	return NotPlater.db and NotPlater.db.profile and NotPlater.db.profile.buffs and NotPlater.db.profile.buffs.tracking.mode == "AUTOMATIC"
end

local function ShowAuraPrompt(listKey, inputType)
	auraPopupContext = {
		listKey = listKey,
		inputType = inputType,
	}
	local dialog = StaticPopup_Show("NOTPLATER_AURA_PROMPT")
	if dialog then
		local text = inputType == "ID" and L["Enter a spell ID"] or L["Enter a spell name"]
		dialog.text:SetText(text)
		dialog.editBox:SetNumeric(inputType == "ID")
		dialog.editBox:SetAutoFocus(true)
		dialog.editBox:SetText("")
		dialog.editBox:SetFocus()
	end
end

StaticPopupDialogs["NOTPLATER_AURA_PROMPT"] = {
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(self)
		self:SetFrameStrata("FULLSCREEN_DIALOG")
		self:Raise()
	end,
	OnAccept = function(self)
		local text = self.editBox:GetText()
		if auraPopupContext then
			AddAuraToList(auraPopupContext.listKey, text)
		end
		self.editBox:SetText("")
	end,
	OnHide = function(self)
		self.editBox:SetText("")
		auraPopupContext = nil
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		parent.button1:Click()
	end,
	text = "",
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
    icon = BuildAssetPath("images", "logo"),
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
		name = WithCategoryIcon("threat", L["Threat"]),
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
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
		name = WithCategoryIcon("healthBar", L["Health Bar"]),
		get = GetValue,
		set = SetValue,
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
		name = WithCategoryIcon("castBar", L["Cast Bar"]),
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
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
				args = NotPlater.ConfigPrototypes.CastBarIcon
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
		name = WithCategoryIcon("nameText", L["Name Text"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.NameText
	}
	options.args.levelText = {
		order = 4,
		type = "group",
		name = WithCategoryIcon("levelText", L["Level Text"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.LevelText
	}
	options.args.raidIcon = {
		order = 5,
		type = "group",
		name = WithCategoryIcon("raidIcon", L["Raid Icon"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.Icon
	}
	options.args.bossIcon = {
		order = 6,
		type = "group",
		name = WithCategoryIcon("bossIcon", L["Boss Icon"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.Icon
	}
	options.args.target = {
		order = 7,
		type = "group",
		name = WithCategoryIcon("target", L["Target"]),
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
		args = {
			general = {
				order = 0,
				type = "group",
				name = L["General"],
				args = NotPlater.ConfigPrototypes.Target
			},
			targetTargetText = {
				order = 8,
				type = "group",
				name = L["Target-Target Text"],
				args = NotPlater.ConfigPrototypes.TargetTargetText
			}
		}
	}
	options.args.buffs = {
		order = 8,
		type = "group",
		name = WithCategoryIcon("buffs", L["Buffs"]),
		childGroups = "tab",
		get = BuffsGetWithDefaults,
		set = BuffsSet,
		args = {
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
						args = trackedUnitArgs,
					},
					enableCombatLogTracking = { order = 10, type = "toggle", name = L["Combat Log Tracking"], desc = L["Learns aura durations from the combat log so timers persist after you stop targeting a unit. Timers may be inaccurate until the addon has seen an aura at least twice."] },
				},
			},
			frames = {
				order = 1,
				type = "group",
				name = L["Frames"],
				args = {
					auraFrame1 = {
						order = 0,
						type = "group",
						inline = true,
						name = L["Aura Frame 1"],
						args = {
							growDirection = { order = 0, type = "select", name = L["Grow Direction"], values = auraGrowthDirections },
							anchor = { order = 1, type = "select", name = L["Anchor"], values = anchorPoints },
							xOffset = { order = 2, type = "range", name = L["X Offset"], min = -100, max = 100, step = 1 },
							yOffset = { order = 3, type = "range", name = L["Y Offset"], min = -100, max = 100, step = 1 },
							rowCount = { order = 4, type = "range", name = L["Auras per Row"], min = 1, max = 12, step = 1, get = function() return BuffsGetValue("auraFrame1", "rowCount") or 10 end, set = function(_, value) BuffsSetValue(value, "auraFrame1", "rowCount") end },
							width = { order = 10, type = "range", name = L["Width"], min = 10, max = 80, step = 1, get = function() return BuffsGetValue("auraFrame1", "width") or 26 end, set = function(_, value) BuffsSetValue(value, "auraFrame1", "width") end },
							height = { order = 11, type = "range", name = L["Height"], min = 10, max = 80, step = 1, get = function() return BuffsGetValue("auraFrame1", "height") or 16 end, set = function(_, value) BuffsSetValue(value, "auraFrame1", "height") end },
							borderThickness = { order = 12, type = "range", name = L["Border Thickness"], min = 0, max = 5, step = 0.1, get = function() return BuffsGetValue("auraFrame1", "borderThickness") or 1 end, set = function(_, value) BuffsSetValue(value, "auraFrame1", "borderThickness") end },
						},
					},
					auraFrame2 = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Aura Frame 2 (Buffs)"],
						args = {
							enable = { order = 0, type = "toggle", name = L["Enable"], desc = L["When enabled, debuffs are shown in Aura Frame 1 and buffs in Aura Frame 2."] },
							growDirection = { order = 1, type = "select", name = L["Grow Direction"], values = auraGrowthDirections, disabled = IsAuraFrame2Disabled },
							anchor = { order = 2, type = "select", name = L["Anchor"], values = anchorPoints, disabled = IsAuraFrame2Disabled },
							xOffset = { order = 3, type = "range", name = L["X Offset"], min = -100, max = 100, step = 1, disabled = IsAuraFrame2Disabled },
							yOffset = { order = 4, type = "range", name = L["Y Offset"], min = -100, max = 100, step = 1, disabled = IsAuraFrame2Disabled },
							rowCount = { order = 5, type = "range", name = L["Auras per Row"], min = 1, max = 12, step = 1, disabled = IsAuraFrame2Disabled, get = function() return BuffsGetValue("auraFrame2", "rowCount") or 10 end, set = function(_, value) BuffsSetValue(value, "auraFrame2", "rowCount") end },
							width = { order = 10, type = "range", name = L["Width"], min = 10, max = 80, step = 1, disabled = IsAuraFrame2Disabled, get = function() return BuffsGetValue("auraFrame2", "width") or 26 end, set = function(_, value) BuffsSetValue(value, "auraFrame2", "width") end },
							height = { order = 11, type = "range", name = L["Height"], min = 10, max = 80, step = 1, disabled = IsAuraFrame2Disabled, get = function() return BuffsGetValue("auraFrame2", "height") or 16 end, set = function(_, value) BuffsSetValue(value, "auraFrame2", "height") end },
							borderThickness = { order = 12, type = "range", name = L["Border Thickness"], min = 0, max = 5, step = 0.1, disabled = IsAuraFrame2Disabled, get = function() return BuffsGetValue("auraFrame2", "borderThickness") or 1 end, set = function(_, value) BuffsSetValue(value, "auraFrame2", "borderThickness") end },
						},
					},
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
							name = { order = 1, type = "select", name = L["Font"], values = GetFontValues },
							size = { order = 2, type = "range", name = L["Size"], min = 6, max = 36, step = 1 },
							border = { order = 3, type = "select", name = L["Outline"], values = fontBorders },
							color = { order = 4, type = "color", name = L["Color"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
						},
					},
					position = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Position"],
						args = {
							anchor = { order = 0, type = "select", name = L["Anchor"], values = anchorPoints },
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
							color = { order = 1, type = "color", name = L["Color"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
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
							name = { order = 3, type = "select", name = L["Font"], values = GetFontValues },
							size = { order = 4, type = "range", name = L["Size"], min = 6, max = 36, step = 1 },
							border = { order = 5, type = "select", name = L["Outline"], values = fontBorders },
							color = { order = 6, type = "color", name = L["Color"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
						},
					},
					position = {
						order = 1,
						type = "group",
						inline = true,
						name = L["Position"],
						disabled = IsAuraTimerDisabled,
						args = {
							anchor = { order = 0, type = "select", name = L["Anchor"], values = anchorPoints },
							xOffset = { order = 1, type = "range", name = L["X Offset"], min = -50, max = 50, step = 1 },
							yOffset = { order = 2, type = "range", name = L["Y Offset"], min = -50, max = 50, step = 1 },
						},
					},
					shadow = {
						order = 2,
						type = "group",
						inline = true,
						name = L["Shadow"],
						disabled = IsAuraTimerDisabled,
						args = {
							enable = { order = 0, type = "toggle", name = L["Enable"] },
							color = { order = 1, type = "color", name = L["Color"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
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
					style = { order = 0, type = "select", name = L["Cooldown Style"], values = swipeStyleValues },
					texture = { order = 1, type = "select", name = L["Texture"], values = GetSwipeTextureValues, disabled = IsSwipeTextureDisabled },
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
					dispellable = { order = 2, type = "color", name = L["Dispellable"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
					enrage = { order = 3, type = "color", name = L["Enrage"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
					buff = { order = 4, type = "color", name = L["Buff"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
					crowdControl = { order = 5, type = "color", name = L["Crowd Control"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
					offensiveCD = { order = 6, type = "color", name = L["Offensive Cooldown"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
					defensiveCD = { order = 7, type = "color", name = L["Defensive Cooldown"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
					default = { order = 8, type = "color", name = L["Default"], hasAlpha = true, get = BuffsGetColor, set = BuffsSetColor },
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
						disabled = function() return not IsAutomaticTracking() end,
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
					blacklistDebuffs = {
						order = 2,
						type = "group",
						name = L["Debuff Blacklist"],
						args = {
							entries = { order = 0, type = "multiselect", name = L["Click an entry to remove it."], values = function() return BuildAuraListValues("blacklistDebuffs") end, get = function() return false end, set = function(_, key) RemoveAuraFromList("blacklistDebuffs", key) end, width = "full" },
							addByName = { order = 1, type = "execute", name = L["Add Debuff by Name"], func = function() ShowAuraPrompt("blacklistDebuffs", "NAME") end },
							addByID = { order = 2, type = "execute", name = L["Add Debuff by ID"], func = function() ShowAuraPrompt("blacklistDebuffs", "ID") end },
						},
					},
					blacklistBuffs = {
						order = 3,
						type = "group",
						name = L["Buff Blacklist"],
						args = {
							entries = { order = 0, type = "multiselect", name = L["Click an entry to remove it."], values = function() return BuildAuraListValues("blacklistBuffs") end, get = function() return false end, set = function(_, key) RemoveAuraFromList("blacklistBuffs", key) end, width = "full" },
							addByName = { order = 1, type = "execute", name = L["Add Buff by Name"], func = function() ShowAuraPrompt("blacklistBuffs", "NAME") end },
							addByID = { order = 2, type = "execute", name = L["Add Buff by ID"], func = function() ShowAuraPrompt("blacklistBuffs", "ID") end },
						},
					},
					extraDebuffs = {
						order = 4,
						type = "group",
						name = L["Extra Debuffs"],
						args = {
							entries = { order = 0, type = "multiselect", name = L["Click an entry to remove it."], values = function() return BuildAuraListValues("extraDebuffs") end, get = function() return false end, set = function(_, key) RemoveAuraFromList("extraDebuffs", key) end, width = "full" },
							addByName = { order = 1, type = "execute", name = L["Add Debuff by Name"], func = function() ShowAuraPrompt("extraDebuffs", "NAME") end },
							addByID = { order = 2, type = "execute", name = L["Add Debuff by ID"], func = function() ShowAuraPrompt("extraDebuffs", "ID") end },
						},
					},
					extraBuffs = {
						order = 5,
						type = "group",
						name = L["Extra Buffs"],
						args = {
							entries = { order = 0, type = "multiselect", name = L["Click an entry to remove it."], values = function() return BuildAuraListValues("extraBuffs") end, get = function() return false end, set = function(_, key) RemoveAuraFromList("extraBuffs", key) end, width = "full" },
							addByName = { order = 1, type = "execute", name = L["Add Buff by Name"], func = function() ShowAuraPrompt("extraBuffs", "NAME") end },
							addByID = { order = 2, type = "execute", name = L["Add Buff by ID"], func = function() ShowAuraPrompt("extraBuffs", "ID") end },
						},
					},
				},
			},
		},
	}
	options.args.stacking = {
		order = 9,
		type = "group",
		get = GetValue,
		set = SetValue,
		name = WithCategoryIcon("stacking", L["Stacking"]),
		args = NotPlater.ConfigPrototypes.NameplateStacking,
	}
	options.args.simulator = {
		order = 10,
		type = "group",
		name = WithCategoryIcon("simulator", L["Simulator"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.Simulator
	}

	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(NotPlater.db)
	options.args.profile.order = 11
	local profileLabel = options.args.profile.name or L["Profiles"] or "Profiles"
	options.args.profile.name = WithCategoryIcon("profile", profileLabel)
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

	local frame = dialog.OpenFrames["NotPlater"]
	if frame and frame.SetStatusText then
		local revision = NotPlater.revision or ""
		
		local cTitle   = "|cffffcc00"  -- gold
		local cVersion = "|cffaaaaaa"  -- light gray
		local cAuthor  = "|cff00ff96"  -- green-ish
		local cHint    = "|cff808080"  -- dark gray
		
		local icon = "|T" .. BuildAssetPath("images", "logo") .. ":24:24:0:0|t "
		
		local text = icon ..
			cTitle .. "NotPlater|r " ..
			(revision ~= "" and (cVersion .. revision .. "|r  ") or "") ..
			cAuthor .. "by RichSteini|r  " ..
			cHint .. "(/np help)|r"

		frame:SetStatusText(text)
	end
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

--[[
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
	
	dialog:SetDefaultSize("NotPlater-Bliz", 850, 650)
	dialog:AddToBlizOptions("NotPlater-Bliz", "NotPlater")

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

	config:RegisterOptionsTable("NotPlater-Target", options.args.target)
	dialog:AddToBlizOptions("NotPlater-Target", options.args.target.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Stacking", options.args.stacking)
	dialog:AddToBlizOptions("NotPlater-Stacking", options.args.stacking.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Simulator", options.args.simulator)
	dialog:AddToBlizOptions("NotPlater-Simulator", options.args.simulator.name, "NotPlater")

	config:RegisterOptionsTable("NotPlater-Profile", options.args.profile)
	dialog:AddToBlizOptions("NotPlater-Profile", options.args.profile.name, "NotPlater")
end)
]]
