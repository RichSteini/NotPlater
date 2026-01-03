if not NotPlater then return end

local Config = NotPlater:NewModule("Config")
local AceTimer = LibStub("AceTimer-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local registry = LibStub("AceConfigRegistry-3.0")
local L = NotPlaterLocals

local addonName = ...
if type(addonName) ~= "string" or addonName == "" then
	addonName = (NotPlater and NotPlater.addonName) or "NotPlater-2.4.3"
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

local function GetProfileSharingModule()
	if not NotPlater or type(NotPlater.GetModule) ~= "function" then
		return nil
	end
	return NotPlater:GetModule("ProfileSharing", true)
end

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
	templates = "Interface\\Icons\\INV_Scroll_05",
	threat = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
	healthBar = "Interface\\Icons\\Spell_Holy_FlashHeal",
	castBar = "Interface\\Icons\\Spell_Frost_Frostbolt02",
	nameText = "Interface\\Icons\\INV_Scroll_03",
	levelText = "Interface\\Icons\\INV_Misc_Note_01",
	icons = "Interface\\Icons\\INV_Misc_Gear_01",
	raidIcon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
	bossIcon = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull",
	filters = "Interface\\Icons\\INV_Misc_Book_11",
	target = "Interface\\Icons\\Ability_Hunter_SniperShot",
	range = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
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
local auraListPopupContext

local function TraverseBuffDB(info)
	if not NotPlater.db or not NotPlater.db.profile then return end
	local db = NotPlater.db.profile.buffs
	if not db then return end
	for i = 2, #info - 1 do
		local key = info[i]
		if i == #info - 1 and key == info[#info] and type(db) == "table" and type(db[key]) ~= "table" then
			break
		end
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

local function GetAuraBorderStyleValues()
	local values = {
		SQUARE = L["Squared"],
		NONE = L["None"],
	}
	local media = NotPlater.SML or SML or LibStub("LibSharedMedia-3.0", true)
	if media then
		for _, name in ipairs(media:List(media.MediaType.BORDER)) do
			if name ~= "None" then
				values[name] = name
			end
		end
	end
	return values
end

local function IsSwipeTextureDisabled(info)
	local db = TraverseBuffDB(info)
	if not db then
		return true
	end
	return (db.style or "vertical") ~= "swirl"
end

local function NotifyAuraOptions()
	if registry then
		registry:NotifyChange("NotPlater")
	end
end

local function RefreshAuraModule()
	local module = NotPlater.Auras
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

local function SetSwipeStyle(info, value)
	BuffsSet(info, value)
	if value == "swirl" then
		StaticPopup_Show("NOTPLATER_SWIRL_WARNING")
	end
end

local trackedUnitArgs = {
	description = {
		order = 0,
		type = "description",
		name = L["Choose which unit IDs NotPlater polls with UnitAura. Only these units provide exact aura timers when combat log tracking is disabled."],
		fontSize = NotPlater.isWrathClient and "medium" or nil,
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

local function BuildAuraListIDString(listKey)
	local list = GetAuraList(listKey)
	local ids = {}
	for _, entry in ipairs(list) do
		local spellID = tonumber(entry.spellID)
		if spellID and spellID > 0 then
			ids[#ids + 1] = tostring(spellID)
		end
	end
	return tconcat(ids, ",")
end

local function ImportAuraListIDs(listKey, text)
	local list = GetAuraList(listKey)
	for i = #list, 1, -1 do
		list[i] = nil
	end

	local invalid = false
	if text and text:match("%d") then
		local seen = {}
		for token in text:gmatch("%d+") do
			local spellID = tonumber(token)
			if spellID and spellID > 0 and not seen[spellID] then
				seen[spellID] = true
				local name, _, icon = GetSpellInfo(spellID)
				if not name then
					invalid = true
				end
				local matched = false
				for _, entry in ipairs(list) do
					if AuraEntriesMatch(entry, spellID, name) then
						entry.spellID = spellID
						entry.name = name or entry.name
						entry.icon = icon or entry.icon
						matched = true
						break
					end
				end
				if not matched then
					tinsert(list, { spellID = spellID, name = name, icon = icon })
				end
			end
		end
	end

	if invalid then
		NotPlater:Print(L["Invalid spell name or ID"])
	end
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

local function ShowAuraListPrompt(listKey)
	auraListPopupContext = { listKey = listKey }
	local dialog = StaticPopup_Show("NOTPLATER_AURA_LIST_PROMPT")
	if dialog then
		dialog.text:SetText(L["Paste spell IDs separated by commas."])
		dialog.editBox:SetNumeric(false)
		dialog.editBox:SetAutoFocus(true)
		dialog.editBox:SetText(BuildAuraListIDString(listKey))
		dialog.editBox:HighlightText()
		dialog.editBox:SetFocus()
	end
end

if NotPlater.isWrathClient then
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
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			if parent and parent.button1 and parent.button1.Click then
				parent.button1:Click()
			end
		end,
		EditBoxOnEscapePressed = function(editBox)
			local parent = editBox:GetParent()
			if parent then
				parent:Hide()
			end
		end,
		text = "",
	}
else
	StaticPopupDialogs["NOTPLATER_AURA_PROMPT"] = {
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnShow = function()
			this:SetFrameStrata("FULLSCREEN_DIALOG")
			this:Raise()
		end,
		OnAccept = function()
			local text = this.editBox:GetText()
			if auraPopupContext then
				AddAuraToList(auraPopupContext.listKey, text)
			end
			this.editBox:SetText("")
		end,
		OnHide = function()
			this.editBox:SetText("")
			auraPopupContext = nil
		end,
		EditBoxOnEnterPressed = function()
			local parent = this:GetParent()
			if parent and parent.button1 and parent.button1.Click then
				parent.button1:Click()
			end
		end,
		EditBoxOnEscapePressed = function()
			local parent = this:GetParent()
			if parent then
				parent:Hide()
			end
		end,
		text = "",
	}
end

if NotPlater.isWrathClient then
	StaticPopupDialogs["NOTPLATER_AURA_LIST_PROMPT"] = {
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
			if auraListPopupContext then
				ImportAuraListIDs(auraListPopupContext.listKey, text)
			end
			self.editBox:SetText("")
		end,
		OnHide = function(self)
			self.editBox:SetText("")
			auraListPopupContext = nil
		end,
		EditBoxOnEnterPressed = function(editBox)
			local parent = editBox:GetParent()
			if parent and parent.button1 and parent.button1.Click then
				parent.button1:Click()
			end
		end,
		EditBoxOnEscapePressed = function(editBox)
			local parent = editBox:GetParent()
			if parent then
				parent:Hide()
			end
		end,
		text = "",
	}
else
	StaticPopupDialogs["NOTPLATER_AURA_LIST_PROMPT"] = {
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnShow = function()
			this:SetFrameStrata("FULLSCREEN_DIALOG")
			this:Raise()
		end,
		OnAccept = function()
			local text = this.editBox:GetText()
			if auraListPopupContext then
				ImportAuraListIDs(auraListPopupContext.listKey, text)
			end
			this.editBox:SetText("")
		end,
		OnHide = function()
			this.editBox:SetText("")
			auraListPopupContext = nil
		end,
		EditBoxOnEnterPressed = function()
			local parent = this:GetParent()
			if parent and parent.button1 and parent.button1.Click then
				parent.button1:Click()
			end
		end,
		EditBoxOnEscapePressed = function()
			local parent = this:GetParent()
			if parent then
				parent:Hide()
			end
		end,
		text = "",
	}
end

if NotPlater.isWrathClient then
	StaticPopupDialogs["NOTPLATER_SWIRL_WARNING"] = {
		button1 = OKAY,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		OnShow = function(self)
			self:SetFrameStrata("FULLSCREEN_DIALOG")
			self:Raise()
		end,
		text = L["Swirl animation warning message"],
	}
else
	StaticPopupDialogs["NOTPLATER_SWIRL_WARNING"] = {
		button1 = OKAY,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
		OnShow = function()
			this:SetFrameStrata("FULLSCREEN_DIALOG")
			this:Raise()
		end,
		text = L["Swirl animation warning message"],
	}
end

NotPlater.ConfigPrototypes.Buffs = NotPlater.ConfigPrototypes:BuildBuffsArgs({
	trackedUnitArgs = trackedUnitArgs,
	GetFontValues = GetFontValues,
	BuffsGetValue = BuffsGetValue,
	BuffsSetValue = BuffsSetValue,
	BuffsGetColor = BuffsGetColor,
	BuffsSetColor = BuffsSetColor,
	GetSwipeTextureValues = GetSwipeTextureValues,
	SetSwipeStyle = SetSwipeStyle,
	IsSwipeTextureDisabled = IsSwipeTextureDisabled,
	GetAuraBorderStyleValues = GetAuraBorderStyleValues,
	IsAuraFrame2Disabled = IsAuraFrame2Disabled,
	IsAuraTimerDisabled = IsAuraTimerDisabled,
	IsAutomaticTracking = IsAutomaticTracking,
	BuildAuraListValues = BuildAuraListValues,
	RemoveAuraFromList = RemoveAuraFromList,
	ShowAuraPrompt = ShowAuraPrompt,
	ShowAuraListPrompt = ShowAuraListPrompt,
})

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

local filterEditingIndex

local CLASS_TOKENS = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}

local function DeepCopyTable(source, seen)
	if type(source) ~= "table" then
		return source
	end
	seen = seen or {}
	if seen[source] then
		return seen[source]
	end
	local copy = {}
	seen[source] = copy
	for key, value in pairs(source) do
		copy[DeepCopyTable(key, seen)] = DeepCopyTable(value, seen)
	end
	return copy
end

local function GetFilterList()
	local profile = NotPlater.db.profile
	profile.filters = profile.filters or {}
	profile.filters.list = profile.filters.list or {}
	return profile.filters.list
end

local function GetEditingFilter()
	local list = GetFilterList()
	if #list == 0 then
		filterEditingIndex = nil
		return nil
	end
	if not filterEditingIndex or not list[filterEditingIndex] then
		filterEditingIndex = 1
	end
	return list[filterEditingIndex], filterEditingIndex
end

local function GetClassLabel(token)
	local male = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]
	if male then
		return male
	end
	local female = LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token]
	if female then
		return female
	end
	return token
end

local function BuildFilterDefaults(name)
	local classValues = {}
	for _, token in ipairs(CLASS_TOKENS) do
		if LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token] then
			classValues[token] = false
		elseif LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token] then
			classValues[token] = false
		end
	end
	local baseNameText = NotPlater.db.profile.nameText
	local nameTextConfig = CopyTable and CopyTable(baseNameText) or DeepCopyTable(baseNameText)
	if nameTextConfig and nameTextConfig.general then
		nameTextConfig.general.size = 12
		nameTextConfig.general.border = "OUTLINE"
	end
	local hideComponents = {}
	local componentOrder = NotPlater:GetStackingComponentOrder()
	for index = 1, #componentOrder do
		local key = componentOrder[index]
		hideComponents[key] = key ~= "nameText" and key ~= "npcIcons"
	end
	return {
		name = name,
		enabled = true,
		criteria = {
			faction = {
				enable = false,
				values = {Alliance = false, Horde = false, Neutral = false},
			},
			class = {
				enable = false,
				values = classValues,
			},
			level = {
				enable = false,
				min = nil,
				max = nil,
			},
			name = {
				enable = false,
				value = "",
			},
			zone = {
				enable = false,
				value = "",
			},
			subzone = {
				enable = false,
				value = "",
			},
			healthColor = {
				enable = false,
				value = "hostile",
			},
		},
	effects = {
		hide = hideComponents,
		nameText = {
			config = nameTextConfig,
		},
	},
	}
end

local function RefreshFilterListOptions()
	if not options or not options.args or not options.args.filters then
		return
	end
	local listGroup = options.args.filters.args.list
	if not listGroup or not listGroup.args then
		return
	end
	local entriesGroup = listGroup.args.entries
	if not entriesGroup then
		entriesGroup = {
			order = 1,
			type = "group",
			name = "",
			inline = true,
			args = {},
		}
		listGroup.args.entries = entriesGroup
	end

	local entries = {}
	local filters = GetFilterList()
	if #filters == 0 then
		entries.empty = {
			order = 0,
			type = "description",
			fontSize = NotPlater.isWrathClient and "medium" or nil,
			name = L["No filters have been created yet."],
		}
	else
		for index, filter in ipairs(filters) do
			local filterName = filter.name or sformat("%s %d", L["Filter"], index)
			entries["filter" .. index] = {
				order = index,
				type = "group",
				inline = true,
				name = filterName,
				args = {
					enabled = {
						order = 0,
						type = "toggle",
						name = L["Enable"],
						get = function()
							return filter.enabled
						end,
						set = function(_, value)
							filter.enabled = value
							NotPlater:ApplyFiltersAll()
						end,
					},
					edit = {
						order = 1,
						type = "execute",
						name = L["Edit"],
						width = "half",
						func = function()
							filterEditingIndex = index
							if dialog and dialog.SelectGroup then
								dialog:SelectGroup("NotPlater", "filters", "editor")
							end
						end,
					},
					duplicate = {
						order = 2,
						type = "execute",
						name = L["Duplicate"],
						func = function()
							local copy = CopyTable and CopyTable(filter) or DeepCopyTable(filter)
							copy.name = sformat(L["Copy of %s"], filterName)
							local insertIndex = index + 1
							tinsert(filters, insertIndex, copy)
							filterEditingIndex = insertIndex
							RefreshFilterListOptions()
							NotPlater:ApplyFiltersAll()
							if dialog and dialog.SelectGroup then
								dialog:SelectGroup("NotPlater", "filters", "editor")
							end
						end,
					},
					delete = {
						order = 3,
						type = "execute",
						name = L["Delete"],
						width = "half",
						confirm = function()
							return sformat(L["Delete filter '%s'?"], filterName)
						end,
						func = function()
							tremove(filters, index)
							if filterEditingIndex and filterEditingIndex > #filters then
								filterEditingIndex = #filters
							end
							if #filters == 0 then
								filterEditingIndex = nil
							end
							RefreshFilterListOptions()
							NotPlater:ApplyFiltersAll()
						end,
					},
				},
			}
		end
	end
	entriesGroup.args = entries
	if registry and registry.NotifyChange then
		registry:NotifyChange("NotPlater")
	end
end

function Config:RefreshFilterOptions()
	RefreshFilterListOptions()
end

local function GetFilterMetaValue(info)
	local filter = GetEditingFilter()
	if not filter then
		return nil
	end
	return filter[info[#info]]
end

local function SetFilterMetaValue(info, value)
	local filter = GetEditingFilter()
	if not filter then
		return
	end
	filter[info[#info]] = value
	RefreshFilterListOptions()
	NotPlater:ApplyFiltersAll()
end

local function GetCriteriaValue(info)
	local filter = GetEditingFilter()
	if not filter then
		return nil
	end
	local criteria = filter.criteria
	local startIndex
	for index = 1, #info do
		if info[index] == "criteria" then
			startIndex = index + 1
			break
		end
	end
	if not startIndex then
		return nil
	end
	local target = criteria
	for index = startIndex, #info do
		target = target and target[info[index]]
	end
	return target
end

local function SetCriteriaValue(info, value)
	local filter = GetEditingFilter()
	if not filter then
		return
	end
	local criteria = filter.criteria
	local startIndex
	for index = 1, #info do
		if info[index] == "criteria" then
			startIndex = index + 1
			break
		end
	end
	if not startIndex then
		return
	end
	local target = criteria
	for index = startIndex, #info - 1 do
		target = target[info[index]]
	end
	target[info[#info]] = value
	NotPlater:ApplyFiltersAll()
end

local function GetEffectsValue(info)
	local filter = GetEditingFilter()
	if not filter then
		return nil
	end
	local effects = filter.effects
	local startIndex
	for index = 1, #info do
		if info[index] == "effects" then
			startIndex = index + 1
			break
		end
	end
	if not startIndex then
		return nil
	end
	local target = effects
	for index = startIndex, #info do
		target = target and target[info[index]]
	end
	return target
end

local function SetEffectsValue(info, value)
	local filter = GetEditingFilter()
	if not filter then
		return
	end
	local effects = filter.effects
	local startIndex
	for index = 1, #info do
		if info[index] == "effects" then
			startIndex = index + 1
			break
		end
	end
	if not startIndex then
		return
	end
	local target = effects
	for index = startIndex, #info - 1 do
		target = target[info[index]]
	end
	target[info[#info]] = value
	NotPlater:ApplyFiltersAll()
end

local function GetNameTextConfigValue(info)
	local filter = GetEditingFilter()
	if not filter or not filter.effects or not filter.effects.nameText then
		return nil
	end
	local config = filter.effects.nameText.config
	if not config then
		return nil
	end
	local startIndex
	for index = 1, #info do
		if info[index] == "config" then
			startIndex = index + 1
			break
		end
	end
	if not startIndex then
		return nil
	end
	local target = config
	for index = startIndex, #info do
		target = target and target[info[index]]
	end
	return target
end

local function SetNameTextConfigValue(info, value)
	local filter = GetEditingFilter()
	if not filter or not filter.effects or not filter.effects.nameText then
		return
	end
	local config = filter.effects.nameText.config
	if not config then
		return
	end
	local startIndex
	for index = 1, #info do
		if info[index] == "config" then
			startIndex = index + 1
			break
		end
	end
	if not startIndex then
		return
	end
	local target = config
	for index = startIndex, #info - 1 do
		target = target[info[index]]
	end
	target[info[#info]] = value
	NotPlater:ApplyFiltersAll()
end

local function LoadOptions()
	options = {}
	options.type = "group"
		options.name = "NotPlater"
	options.args = {}
	local whatsNewModule = NotPlater:GetModule("WhatsNew", true)
	if whatsNewModule and whatsNewModule.GetConfigOptions then
		options.args.whatsNew = whatsNewModule:GetConfigOptions()
	end
	options.args.templates = {
		order = 0,
		type = "group",
		name = WithCategoryIcon("templates", L["Templates"]),
		args = {},
	}
	options.args.threat = {
		order = 1,
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
		order = 2,
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
		order = 3,
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
		order = 4,
		type = "group",
		name = WithCategoryIcon("nameText", L["Name Text"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.NameText
	}
	options.args.levelText = {
		order = 5,
		type = "group",
		name = WithCategoryIcon("levelText", L["Level Text"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.LevelText
	}
	local iconsArgs = {
		raidIcon = {
			order = 0,
			type = "group",
			name = L["Raid Icon"],
			args = NotPlater.ConfigPrototypes.Icon,
		},
		bossIcon = {
			order = 1,
			type = "group",
			name = L["Boss Icon"],
			args = NotPlater.ConfigPrototypes.BossIcon,
		},
		eliteIcon = {
			order = 2,
			type = "group",
			name = L["Elite / Rare Icon"],
			args = NotPlater.ConfigPrototypes.Icon,
		},
		classIcon = {
			order = 3,
			type = "group",
			name = L["Class Icon"],
			args = NotPlater.ConfigPrototypes.Icon,
		},
		factionIcon = {
			order = 4,
			type = "group",
			name = L["Faction Icon"],
			args = NotPlater.ConfigPrototypes.Icon,
		},
		npcIcons = {
			order = 5,
			type = "group",
			name = L["NPC Icons"],
			args = NotPlater.ConfigPrototypes.NpcIcons,
		},
	}
	options.args.icons = {
		order = 6,
		type = "group",
		name = WithCategoryIcon("icons", L["Icons"]),
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
		args = iconsArgs,
	}
	local classCriteriaArgs = {
		enable = {
			order = 0,
			type = "toggle",
			name = L["Enable"],
			get = GetCriteriaValue,
			set = SetCriteriaValue,
		},
	}
	local classOrder = 1
	for _, token in ipairs(CLASS_TOKENS) do
		local label = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token])
		if label then
			local classToken = token
			classCriteriaArgs[classToken] = {
				order = classOrder,
				type = "toggle",
				name = label,
				width = "half",
				get = function()
					local filter = GetEditingFilter()
					return filter and filter.criteria.class.values[classToken]
				end,
				set = function(_, value)
					local filter = GetEditingFilter()
					if filter then
						filter.criteria.class.values[classToken] = value
						NotPlater:ApplyFiltersAll()
					end
				end,
				disabled = function()
					local filter = GetEditingFilter()
					return not (filter and filter.criteria.class.enable)
				end,
			}
			classOrder = classOrder + 1
		end
	end

	local hideComponentArgs = {}
	local componentOrder = NotPlater:GetStackingComponentOrder()
	for index, key in ipairs(componentOrder) do
		local componentKey = key
		hideComponentArgs[componentKey] = {
			order = index,
			type = "toggle",
			name = NotPlater:GetStackingComponentLabel(componentKey),
			get = function()
				local filter = GetEditingFilter()
				return filter and filter.effects.hide[componentKey]
			end,
			set = function(_, value)
				local filter = GetEditingFilter()
				if filter then
					filter.effects.hide[componentKey] = value
					NotPlater:ApplyFiltersAll()
				end
			end,
		}
	end

	options.args.filters = {
		order = 7,
		type = "group",
		name = WithCategoryIcon("filters", L["Filters"]),
		childGroups = "tab",
		args = {
			list = {
				order = 0,
				type = "group",
				name = L["Filter List"],
				args = {
					addFilter = {
						order = 0,
						type = "execute",
						name = L["Add Filter"],
						func = function()
							local filters = GetFilterList()
							local name = sformat("%s %d", L["Filter"], #filters + 1)
							tinsert(filters, BuildFilterDefaults(name))
							filterEditingIndex = #filters
							RefreshFilterListOptions()
							NotPlater:ApplyFiltersAll()
							if dialog and dialog.SelectGroup then
								dialog:SelectGroup("NotPlater", "filters", "editor")
							end
						end,
					},
					entries = {
						order = 1,
						type = "group",
						name = "",
						inline = true,
						args = {},
					},
				},
			},
			editor = {
				order = 1,
				type = "group",
				name = L["Filter Editor"],
				childGroups = "tab",
				args = {
					empty = {
						order = 0,
						type = "description",
						fontSize = NotPlater.isWrathClient and "medium" or nil,
						name = L["Select a filter to edit or add a new one."],
						hidden = function()
							return GetEditingFilter() ~= nil
						end,
					},
					meta = {
						order = 1,
						type = "group",
						name = L["Filter"],
						hidden = function()
							return GetEditingFilter() == nil
						end,
						get = GetFilterMetaValue,
						set = SetFilterMetaValue,
						args = {
							name = {
								order = 0,
								type = "input",
								width = "full",
								name = L["Filter Name"],
							},
							enabled = {
								order = 1,
								type = "toggle",
								name = L["Enable"],
							},
						},
					},
					criteria = {
						order = 2,
						type = "group",
						name = L["Criteria"],
						childGroups = "tab",
						hidden = function()
							return GetEditingFilter() == nil
						end,
						args = {
							hint = {
								order = 0,
								type = "header",
								name = L["Note: Filters match only when all enabled criteria are met."],
							},
							faction = {
								order = 1,
								type = "group",
								name = L["Faction"],
								inline = true,
								args = {
									enable = {
										order = 0,
										type = "toggle",
										name = L["Enable"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
									},
									alliance = {
										order = 1,
										type = "toggle",
										name = L["Alliance"],
										get = function()
											local filter = GetEditingFilter()
											return filter and filter.criteria.faction.values.Alliance
										end,
										set = function(_, value)
											local filter = GetEditingFilter()
											if filter then
												filter.criteria.faction.values.Alliance = value
												NotPlater:ApplyFiltersAll()
											end
										end,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.faction.enable)
										end,
									},
									horde = {
										order = 2,
										type = "toggle",
										name = L["Horde"],
										get = function()
											local filter = GetEditingFilter()
											return filter and filter.criteria.faction.values.Horde
										end,
										set = function(_, value)
											local filter = GetEditingFilter()
											if filter then
												filter.criteria.faction.values.Horde = value
												NotPlater:ApplyFiltersAll()
											end
										end,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.faction.enable)
										end,
									},
									neutral = {
										order = 3,
										type = "toggle",
										name = L["Neutral"],
										get = function()
											local filter = GetEditingFilter()
											return filter and filter.criteria.faction.values.Neutral
										end,
										set = function(_, value)
											local filter = GetEditingFilter()
											if filter then
												filter.criteria.faction.values.Neutral = value
												NotPlater:ApplyFiltersAll()
											end
										end,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.faction.enable)
										end,
									},
								},
							},
							class = {
								order = 2,
								type = "group",
								name = L["Unit Class"],
								inline = true,
								args = classCriteriaArgs,
							},
							level = {
								order = 3,
								type = "group",
								name = L["Level Range"],
								inline = true,
								args = {
									enable = {
										order = 0,
										type = "toggle",
										name = L["Enable"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
									},
									min = {
										order = 1,
										type = "input",
										name = L["Minimum Level"],
										get = function()
											local filter = GetEditingFilter()
											local value = filter and filter.criteria.level.min
											return value and tostring(value) or ""
										end,
										set = function(_, value)
											local filter = GetEditingFilter()
											if not filter then
												return
											end
											local numberValue = tonumber(value)
											filter.criteria.level.min = numberValue
											NotPlater:ApplyFiltersAll()
										end,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.level.enable)
										end,
									},
									max = {
										order = 2,
										type = "input",
										name = L["Maximum Level"],
										get = function()
											local filter = GetEditingFilter()
											local value = filter and filter.criteria.level.max
											return value and tostring(value) or ""
										end,
										set = function(_, value)
											local filter = GetEditingFilter()
											if not filter then
												return
											end
											local numberValue = tonumber(value)
											filter.criteria.level.max = numberValue
											NotPlater:ApplyFiltersAll()
										end,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.level.enable)
										end,
									},
								},
							},
							name = {
								order = 4,
								type = "group",
								name = L["Name"],
								inline = true,
								args = {
									enable = {
										order = 0,
										type = "toggle",
										name = L["Enable"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
									},
									value = {
										order = 1,
										type = "input",
										width = "full",
										name = L["Name"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.name.enable)
										end,
									},
								},
							},
							zone = {
								order = 5,
								type = "group",
								name = L["Zone Name"],
								inline = true,
								args = {
									enable = {
										order = 0,
										type = "toggle",
										name = L["Enable"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
									},
									value = {
										order = 1,
										type = "input",
										width = "full",
										name = L["Zone Name"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.zone.enable)
										end,
									},
								},
							},
							subzone = {
								order = 6,
								type = "group",
								name = L["Subzone Name"],
								inline = true,
								args = {
									enable = {
										order = 0,
										type = "toggle",
										name = L["Enable"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
									},
									value = {
										order = 1,
										type = "input",
										width = "full",
										name = L["Subzone Name"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.subzone.enable)
										end,
									},
								},
							},
							healthColor = {
								order = 7,
								type = "group",
								name = L["Default Healthbar Color"],
								inline = true,
								args = {
									enable = {
										order = 0,
										type = "toggle",
										name = L["Enable"],
										get = GetCriteriaValue,
										set = SetCriteriaValue,
									},
									value = {
										order = 1,
										type = "select",
										name = L["Nameplate Color"],
										values = function()
											return NotPlater:GetNameplateColorOptions()
										end,
										get = GetCriteriaValue,
										set = SetCriteriaValue,
										disabled = function()
											local filter = GetEditingFilter()
											return not (filter and filter.criteria.healthColor.enable)
										end,
									},
								},
							},
						},
					},
					effects = {
						order = 3,
						type = "group",
						name = L["Effects"],
						childGroups = "tab",
						hidden = function()
							return GetEditingFilter() == nil
						end,
						args = {
							hide = {
								order = 0,
								type = "group",
								name = L["Hide Components"],
								args = hideComponentArgs,
								get = GetEffectsValue,
								set = SetEffectsValue,
							},
							nameText = {
								order = 1,
								type = "group",
								name = L["Alternative Name Text"],
								get = GetEffectsValue,
								set = SetEffectsValue,
								args = {
									config = {
										order = 0,
										type = "group",
										inline = true,
										name = L["Name Text"],
										disabled = function()
											local filter = GetEditingFilter()
											return filter and filter.effects.hide.nameText
										end,
										get = GetNameTextConfigValue,
										set = SetNameTextConfigValue,
										args = NotPlater.ConfigPrototypes.NameText,
									},
								},
							},
						},
					},
				},
			},
		},
	}
	options.args.target = {
		order = 8,
		type = "group",
		name = WithCategoryIcon("target", L["Target"]),
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
		args = {
			scale = NotPlater.ConfigPrototypes.Target.scale,
			border = NotPlater.ConfigPrototypes.Target.border,
			overlay = NotPlater.ConfigPrototypes.Target.overlay,
			nonTargetAlpha = NotPlater.ConfigPrototypes.Target.nonTargetAlpha,
			nonTargetShading = NotPlater.ConfigPrototypes.Target.nonTargetShading,
			mouseoverHighlight = NotPlater.ConfigPrototypes.Target.mouseoverHighlight,
			targetTargetText = {
				order = 8,
				type = "group",
				name = L["Target-Target Text"],
				args = NotPlater.ConfigPrototypes.TargetTargetText
			}
		}
	}
	options.args.range = {
		order = 9,
		type = "group",
		name = WithCategoryIcon("range", L["Range Indicator"]),
		get = GetValue,
		set = SetValue,
		childGroups = "tab",
		args = {
			statusBar = NotPlater.ConfigPrototypes.Range.statusBar,
			text = NotPlater.ConfigPrototypes.Range.text,
			buckets = NotPlater.ConfigPrototypes.Range.buckets,
		},
	}
	options.args.buffs = {
		order = 10,
		type = "group",
		name = WithCategoryIcon("buffs", L["Buffs"]),
		childGroups = "tab",
		get = BuffsGetWithDefaults,
		set = BuffsSet,
		args = NotPlater.ConfigPrototypes.Buffs,
	}
	options.args.stacking = {
		order = 11,
        type = "group",
        childGroups = "tab",
		name = WithCategoryIcon("stacking", L["Stacking"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.Stacking,
	}
	options.args.simulator = {
		order = 12,
		type = "group",
		name = WithCategoryIcon("simulator", L["Simulator"]),
		get = GetValue,
		set = SetValue,
		args = NotPlater.ConfigPrototypes.Simulator
	}

	local aceProfileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(NotPlater.db)
	aceProfileOptions.order = 1
	aceProfileOptions.name = L["Profile Management"]

	local profileLabel = L["Profiles"] or "Profiles"
	options.args.profile = {
		order = 13,
		type = "group",
		childGroups = "tab",
		name = WithCategoryIcon("profile", profileLabel),
		args = {
			management = aceProfileOptions,
			export = {
				order = 2,
				type = "group",
				name = L["Export"],
				args = {
					description = {
						order = 0,
						type = "description",
						fontSize = NotPlater.isWrathClient and "medium" or nil,
						name = L["Generate an export string and copy it to share your current profile."],
					},
					generate = {
						order = 1,
						type = "execute",
						name = L["Generate Export String"],
						func = function()
							local module = GetProfileSharingModule()
							if not module then
								NotPlater:Print(L["Profile sharing is currently disabled."])
								return
							end
							local encoded, err = module:GenerateExportString()
							if not encoded then
								NotPlater:Print(err or L["Unable to export the selected profile."])
							else
								NotPlater:Print(L["Profile export string updated."])
							end
						end,
					},
					insertLink = {
						order = 2,
						type = "execute",
						name = L["Insert Share Link"],
						desc = L["Insert a clickable profile link into the active chat edit box."],
						func = function()
							local module = GetProfileSharingModule()
							if not module then
								NotPlater:Print(L["Profile sharing is currently disabled."])
								return
							end
							if not module:InsertShareLink() then
								NotPlater:Print(L["Unable to place the profile link in chat."])
							end
						end,
					},
					exportString = {
						order = 3,
						type = "input",
						multiline = 8,
						width = "full",
						name = L["Profile Export String"],
						get = function()
							local module = GetProfileSharingModule()
							return (module and module:GetExportString()) or ""
						end,
						set = function() end,
					},
					exportSummary = {
						order = 4,
						type = "description",
						fontSize = NotPlater.isWrathClient and "medium" or nil,
						name = function()
							local module = GetProfileSharingModule()
							if not module then
								return ""
							end
							local summary = module:GetLastExportSummary()
							if not summary or summary == "" then
								return L["Generate an export string to populate this field."]
							end
							return summary
						end,
					},
				},
			},
			import = {
				order = 3,
				type = "group",
				name = L["Import"],
				args = {
					description = {
						order = 0,
						type = "description",
						fontSize = NotPlater.isWrathClient and "medium" or nil,
						name = L["Paste a profile string received from another player."],
					},
					importString = {
						order = 1,
						type = "input",
						name = L["Profile Import String"],
						multiline = 8,
						width = "full",
						get = function()
							local module = GetProfileSharingModule()
							return (module and module:GetImportString()) or ""
						end,
						set = function(_, value)
							local module = GetProfileSharingModule()
							if module then
								module:SetImportString(value)
							end
						end,
					},
					importProfileName = {
						order = 2,
						type = "input",
						width = "full",
						name = L["Import Target Name"],
						desc = L["New profile name created from the import string."],
						get = function()
							local module = GetProfileSharingModule()
							return (module and module:GetImportProfileName()) or ""
						end,
						set = function(_, value)
							local module = GetProfileSharingModule()
							if module then
								module:SetImportProfileName(value)
							end
						end,
					},
					switchProfile = {
						order = 3,
						type = "toggle",
						width = "full",
						name = L["Activate After Import"],
						desc = L["Switch to the imported profile as soon as it is created."],
						get = function()
							local module = GetProfileSharingModule()
							return module and module:GetSwitchToImportedProfile()
						end,
						set = function(_, value)
							local module = GetProfileSharingModule()
							if module then
								module:SetSwitchToImportedProfile(value)
							end
						end,
					},
					importButton = {
						order = 4,
						type = "execute",
						name = L["Import Profile"],
						func = function()
							local module = GetProfileSharingModule()
							if not module then
								NotPlater:Print(L["Profile sharing is currently disabled."])
								return
							end
							module:ImportFromOptions()
						end,
					},
					importSummary = {
						order = 5,
						type = "description",
						fontSize = NotPlater.isWrathClient and "medium" or nil,
						name = function()
							local module = GetProfileSharingModule()
							if not module then
								return ""
							end
							local summary = module:GetLastImportSummary()
							if not summary or summary == "" then
								return L["No import has been processed yet."]
							end
							return summary
						end,
					},
				},
			},
		},
	}

	RefreshFilterListOptions()
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
	RefreshFilterListOptions()
	local whatsNew = NotPlater:GetModule("WhatsNew", true)
	if whatsNew and whatsNew.BeginConfigSession then
		whatsNew:BeginConfigSession()
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
		
		local linkColor = "|cff5daeff"
		local link = "|Hurl:https://github.com/RichSteini/NotPlater|h" .. linkColor .. "https://github.com/RichSteini/NotPlater|r|h"

		local text = icon ..
			cTitle .. "NotPlater|r " ..
			(revision ~= "" and (cVersion .. revision .. "|r  ") or "") ..
			cAuthor .. "by RichSteini|r  " ..
			cHint .. "(/np help)|r.  " ..
			cHint .. "For updates visit:|r " .. link

		frame:SetStatusText(text)
	end

	if frame and not frame.npCloseHooked then
		frame.npCloseHooked = true
		NotPlater:HookTemplateGalleryWatcher(frame)
		frame.frame:HookScript("OnHide", function()
			NotPlater:HideSimulatorFrame()
			NotPlater:HideTemplateGallery()
		end)
	end

	AceTimer:ScheduleTimer(function()
		NotPlater:UpdateTemplateGalleryVisibility()
	end, 0)
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
	elseif msg == "whatsnew" then
		local whatsNew = NotPlater:GetModule("WhatsNew", true)
		if whatsNew then
			if whatsNew.RequestManualView then
				whatsNew:RequestManualView()
			end
			Config:OpenConfig()
		else
			NotPlater:Print(L["Release notes are not available."])
		end
	elseif msg == "help" then
        NotPlater:PrintHelp()
	elseif msg == "share" then
		local module = GetProfileSharingModule()
		if not module then
			NotPlater:Print(L["Profile sharing is currently disabled."])
			return
		end
		module:InsertShareLink()
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

	config:RegisterOptionsTable("NotPlater-Icons", options.args.icons)
	dialog:AddToBlizOptions("NotPlater-Icons", options.args.icons.name, "NotPlater")

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
