--[[ profileSharing.lua
This file implements the profile sharing functionality for NotPlater, similar to WeakAuras.
It handles export/import of profiles as strings, chat links for sharing, and transmission over addon channels.
]]--

if not NotPlater then return end
local ProfileSharing = NotPlater:NewModule("ProfileSharing")
local L = NotPlaterLocals
local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local AceSerializer = LibStub("AceSerializer-3.0", true)
local AceComm = LibStub("AceComm-3.0")
local dialog = LibStub("AceConfigDialog-3.0", true)
local registry = LibStub("AceConfigRegistry-3.0", true)
local configForDeflate = {level = 9}
local configForLS = {errorOnUnserializableType = false}
local addonPrefix = "NotPlater"
local tooltipLoading = false
local receivedData = false
local safeSenders = {}
local linkedProfiles = {}
local linkValidityDuration = 60 * 5
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local UnitName = UnitName
local GetTime = GetTime

local PLATER_TEXTURE_MAP = {
	["PlaterHealth"] = "NotPlater HealthBar",
	["PlaterBackground"] = "NotPlater Background",
	["PlaterBackground 2"] = "NotPlater Background",
	["PlaterTexture"] = "NotPlater Default",
	["Details Flat"] = "flat",
}

local PLATER_ANCHORS = {
	[1] = "TOPLEFT",
	[2] = "TOP",
	[3] = "TOPRIGHT",
	[4] = "RIGHT",
	[5] = "BOTTOMRIGHT",
	[6] = "BOTTOM",
	[7] = "BOTTOMLEFT",
	[8] = "LEFT",
	[9] = "CENTER",
	[10] = "TOPLEFT",
	[11] = "RIGHT",
	[12] = "BOTTOM",
	[13] = "LEFT",
}

local function DeepCopyTable(source, seen)
	if type(source) ~= "table" then
		return source
	end
	if seen and seen[source] then
		return seen[source]
	end
	local copy = {}
	seen = seen or {}
	seen[source] = copy
	for key, value in pairs(source) do
		copy[DeepCopyTable(key, seen)] = DeepCopyTable(value, seen)
	end
	return copy
end

local function ResolveTextureName(textureName, fallback)
	if not textureName or textureName == "" then
		return fallback
	end
	local mapped = PLATER_TEXTURE_MAP[textureName] or textureName
	if NotPlater and NotPlater.SML and NotPlater.SML.IsValid then
		if NotPlater.SML:IsValid(NotPlater.SML.MediaType.STATUSBAR, mapped) then
			return mapped
		end
	end
	return fallback
end

local function ResolveFontName(fontName, fallback)
	if not fontName or fontName == "" then
		return fallback
	end
	if NotPlater and NotPlater.SML and NotPlater.SML.IsValid then
		if NotPlater.SML:IsValid(NotPlater.SML.MediaType.FONT, fontName) then
			return fontName
		end
	end
	return fallback
end

local function NormalizeOutline(outline)
	if outline == "NONE" then
		return ""
	end
	return outline
end

local function ResolveAnchorPoint(anchor)
	if type(anchor) ~= "table" then
		return nil
	end
	local side = PLATER_ANCHORS[anchor.side]
	if not side then
		return nil
	end
	return side, anchor.x or 0, anchor.y or 0
end

local function ApplyAnchorSpacing(anchorPoint, xOffset, yOffset, spacing)
	if not spacing or spacing == 0 then
		return xOffset, yOffset
	end
	if anchorPoint == "TOP" or anchorPoint == "TOPLEFT" or anchorPoint == "TOPRIGHT" then
		return xOffset, yOffset + spacing
	end
	if anchorPoint == "BOTTOM" or anchorPoint == "BOTTOMLEFT" or anchorPoint == "BOTTOMRIGHT" then
		return xOffset, yOffset - spacing
	end
	if anchorPoint == "LEFT" then
		return xOffset - spacing, yOffset
	end
	if anchorPoint == "RIGHT" then
		return xOffset + spacing, yOffset
	end
	return xOffset, yOffset
end

function ProfileSharing:DecodePlaterImportString(value)
	if type(value) ~= "string" or value == "" then
		return nil, L["Invalid import string"]
	end
	if not AceSerializer then
		return nil, L["Invalid import string"]
	end
	local payload = value
	local stripped = value:match("^!%w+:%d+!%s*(.+)$") or value:match("^!%w+!%s*(.+)$")
	if stripped and stripped ~= "" then
		payload = stripped
	end
	local decoded = LibDeflate:DecodeForPrint(payload)
	if not decoded then
		return nil, L["Invalid import string"]
	end
	local decompressed = LibDeflate:DecompressDeflate(decoded, configForDeflate)
	if not decompressed then
		return nil, L["Invalid import string"]
	end
	local ok, data = AceSerializer:Deserialize(decompressed)
	if not ok or type(data) ~= "table" then
		return nil, L["Invalid import string"]
	end
	local profile = data.profile or data
	if type(profile) ~= "table" or not profile.plate_config then
		return nil, L["Invalid import string"]
	end
	return profile, nil
end

function ProfileSharing:ConvertPlaterProfile(platerProfile)
	if type(platerProfile) ~= "table" then
		return nil
	end
	local baseProfile = NotPlater and NotPlater.defaults and NotPlater.defaults.profile
	if not baseProfile then
		return nil
	end
	local profile = DeepCopyTable(baseProfile)
	local plateConfig = platerProfile.plate_config or {}
	local plate = plateConfig.enemyplayer or plateConfig.enemynpc or plateConfig.friendlyplayer or plateConfig.friendlynpc or plateConfig.player or {}
	local spellTextAnchorPoint, spellTextX, spellTextY = ResolveAnchorPoint(plate.spellname_text_anchor)
	local spellTimeAnchorPoint, spellTimeX, spellTimeY = ResolveAnchorPoint(plate.spellpercent_text_anchor)
	local healthTextAnchorPoint, healthTextX, healthTextY = ResolveAnchorPoint(plate.percent_text_anchor)
	local nameTextAnchorPoint, nameTextX, nameTextY = ResolveAnchorPoint(plate.actorname_text_anchor)
	local levelTextAnchorPoint, levelTextX, levelTextY = ResolveAnchorPoint(plate.level_text_anchor)

	if plate.health and type(plate.health) == "table" then
		profile.healthBar.statusBar.size.width = plate.health[1] or profile.healthBar.statusBar.size.width
		profile.healthBar.statusBar.size.height = plate.health[2] or profile.healthBar.statusBar.size.height
	end
	if plate.cast and type(plate.cast) == "table" then
		profile.castBar.statusBar.size.width = plate.cast[1] or profile.castBar.statusBar.size.width
		profile.castBar.statusBar.size.height = plate.cast[2] or profile.castBar.statusBar.size.height
	end
	if type(plate.castbar_offset_x) == "number" then
		profile.castBar.statusBar.position.xOffset = plate.castbar_offset_x
	end
	if type(plate.castbar_offset) == "number" then
		profile.castBar.statusBar.position.yOffset = plate.castbar_offset
	end

	if type(plate.actorname_text_spacing) == "number" and nameTextAnchorPoint then
		nameTextX, nameTextY = ApplyAnchorSpacing(nameTextAnchorPoint, nameTextX, nameTextY, plate.actorname_text_spacing)
	end

	if nameTextAnchorPoint then
		profile.nameText.position.anchor = nameTextAnchorPoint
		profile.nameText.position.xOffset = nameTextX
		profile.nameText.position.yOffset = nameTextY
	end
	if levelTextAnchorPoint then
		profile.levelText.position.anchor = levelTextAnchorPoint
		profile.levelText.position.xOffset = levelTextX
		profile.levelText.position.yOffset = levelTextY
	end
	if spellTextAnchorPoint then
		profile.castBar.spellNameText.position.anchor = spellTextAnchorPoint
		profile.castBar.spellNameText.position.xOffset = spellTextX
		profile.castBar.spellNameText.position.yOffset = spellTextY
	end
	if spellTimeAnchorPoint then
		profile.castBar.spellTimeText.position.anchor = spellTimeAnchorPoint
		profile.castBar.spellTimeText.position.xOffset = spellTimeX
		profile.castBar.spellTimeText.position.yOffset = spellTimeY
	end
	if healthTextAnchorPoint then
		profile.healthBar.healthText.position.anchor = healthTextAnchorPoint
		profile.healthBar.healthText.position.xOffset = healthTextX
		profile.healthBar.healthText.position.yOffset = healthTextY
	end

	profile.healthBar.statusBar.general.texture = ResolveTextureName(platerProfile.health_statusbar_texture, profile.healthBar.statusBar.general.texture)
	profile.healthBar.statusBar.background.texture = ResolveTextureName(platerProfile.health_statusbar_bgtexture, profile.healthBar.statusBar.background.texture)
	if type(platerProfile.health_statusbar_bgcolor) == "table" then
		profile.healthBar.statusBar.background.color = {
			platerProfile.health_statusbar_bgcolor[1] or 0.1,
			platerProfile.health_statusbar_bgcolor[2] or 0.1,
			platerProfile.health_statusbar_bgcolor[3] or 0.1,
			platerProfile.health_statusbar_bgcolor[4] or 0.8,
		}
	end

	profile.castBar.statusBar.general.texture = ResolveTextureName(platerProfile.cast_statusbar_texture, profile.castBar.statusBar.general.texture)
	profile.castBar.statusBar.background.texture = ResolveTextureName(platerProfile.cast_statusbar_bgtexture, profile.castBar.statusBar.background.texture)
	if type(platerProfile.cast_statusbar_color) == "table" then
		profile.castBar.statusBar.general.color = {
			platerProfile.cast_statusbar_color[1] or 1,
			platerProfile.cast_statusbar_color[2] or 1,
			platerProfile.cast_statusbar_color[3] or 1,
			platerProfile.cast_statusbar_color[4] or 1,
		}
	end
	if type(platerProfile.cast_statusbar_bgcolor) == "table" then
		profile.castBar.statusBar.background.color = {
			platerProfile.cast_statusbar_bgcolor[1] or 0.1,
			platerProfile.cast_statusbar_bgcolor[2] or 0.1,
			platerProfile.cast_statusbar_bgcolor[3] or 0.1,
			platerProfile.cast_statusbar_bgcolor[4] or 0.8,
		}
	end

	if type(platerProfile.castbar_icon_show) == "boolean" then
		profile.castBar.spellIcon.general.enable = platerProfile.castbar_icon_show
	end
	if type(platerProfile.castbar_icon_size) == "string" then
		local castHeight = profile.castBar.statusBar.size.height or 14
		local healthHeight = profile.healthBar.statusBar.size.height or 14
		local iconSize = castHeight
		if platerProfile.castbar_icon_size == "same as castbar plus healthbar" then
			iconSize = castHeight + healthHeight
		end
		profile.castBar.spellIcon.size.width = iconSize
		profile.castBar.spellIcon.size.height = iconSize
	end
	if type(platerProfile.castbar_icon_attach_to_side) == "string" then
		if platerProfile.castbar_icon_attach_to_side == "right" then
			profile.castBar.spellIcon.position.anchor = "RIGHT"
		else
			profile.castBar.spellIcon.position.anchor = "LEFT"
		end
	end
	if type(platerProfile.castbar_icon_x_offset) == "number" then
		profile.castBar.spellIcon.position.xOffset = platerProfile.castbar_icon_x_offset
	end

	if plate.actorname_text_font then
		profile.nameText.general.name = ResolveFontName(plate.actorname_text_font, profile.nameText.general.name)
	end
	if plate.actorname_text_size then
		profile.nameText.general.size = plate.actorname_text_size
	end
	if plate.actorname_text_outline then
		profile.nameText.general.border = NormalizeOutline(plate.actorname_text_outline)
	end
	if type(plate.actorname_text_color) == "table" then
		profile.nameText.general.color = {
			plate.actorname_text_color[1] or 1,
			plate.actorname_text_color[2] or 1,
			plate.actorname_text_color[3] or 1,
			plate.actorname_text_color[4] or 1,
		}
	end
	if type(plate.actorname_use_class_color) == "boolean" then
		profile.nameText.general.useClassColor = plate.actorname_use_class_color
	end
	if type(plate.actorname_text_shadow_color) == "table" then
		profile.nameText.shadow.enable = true
		profile.nameText.shadow.color = {
			plate.actorname_text_shadow_color[1] or 0,
			plate.actorname_text_shadow_color[2] or 0,
			plate.actorname_text_shadow_color[3] or 0,
			plate.actorname_text_shadow_color[4] or 1,
		}
	end
	if type(plate.actorname_text_shadow_color_offset) == "table" then
		profile.nameText.shadow.enable = true
		profile.nameText.shadow.xOffset = plate.actorname_text_shadow_color_offset[1] or 0
		profile.nameText.shadow.yOffset = plate.actorname_text_shadow_color_offset[2] or 0
	end

	if type(plate.percent_text_enabled) == "boolean" then
		profile.healthBar.healthText.general.enable = plate.percent_text_enabled
	end
	if type(plate.percent_text_show_decimals) == "boolean" then
		profile.healthBar.healthText.general.showDecimalPercent = plate.percent_text_show_decimals
	end
	if type(plate.percent_show_health) == "boolean" or type(plate.percent_show_percent) == "boolean" then
		local showHealth = plate.percent_show_health == true
		local showPercent = plate.percent_show_percent ~= false
		if showHealth and showPercent then
			profile.healthBar.healthText.general.displayType = "both"
		elseif showPercent then
			profile.healthBar.healthText.general.displayType = "percent"
		elseif showHealth then
			profile.healthBar.healthText.general.displayType = "minmax"
		else
			profile.healthBar.healthText.general.displayType = "none"
		end
	end
	if plate.percent_text_font then
		profile.healthBar.healthText.general.name = ResolveFontName(plate.percent_text_font, profile.healthBar.healthText.general.name)
	end
	if plate.percent_text_size then
		profile.healthBar.healthText.general.size = plate.percent_text_size
	end
	if plate.percent_text_outline then
		profile.healthBar.healthText.general.border = NormalizeOutline(plate.percent_text_outline)
	end
	if type(plate.percent_text_color) == "table" then
		profile.healthBar.healthText.general.color = {
			plate.percent_text_color[1] or 1,
			plate.percent_text_color[2] or 1,
			plate.percent_text_color[3] or 1,
			plate.percent_text_color[4] or 1,
		}
	end
	if type(plate.percent_text_alpha) == "number" then
		profile.healthBar.healthText.general.color[4] = plate.percent_text_alpha
	end
	if type(plate.percent_text_shadow_color) == "table" then
		profile.healthBar.healthText.shadow.enable = true
		profile.healthBar.healthText.shadow.color = {
			plate.percent_text_shadow_color[1] or 0,
			plate.percent_text_shadow_color[2] or 0,
			plate.percent_text_shadow_color[3] or 0,
			plate.percent_text_shadow_color[4] or 1,
		}
	end
	if type(plate.percent_text_shadow_color_offset) == "table" then
		profile.healthBar.healthText.shadow.enable = true
		profile.healthBar.healthText.shadow.xOffset = plate.percent_text_shadow_color_offset[1] or 0
		profile.healthBar.healthText.shadow.yOffset = plate.percent_text_shadow_color_offset[2] or 0
	end

	if type(plate.level_text_enabled) == "boolean" then
		profile.levelText.general.enable = plate.level_text_enabled
	end
	if plate.level_text_font then
		profile.levelText.general.name = ResolveFontName(plate.level_text_font, profile.levelText.general.name)
	end
	if plate.level_text_size then
		profile.levelText.general.size = plate.level_text_size
	end
	if plate.level_text_outline then
		profile.levelText.general.border = NormalizeOutline(plate.level_text_outline)
	end
	if type(plate.level_text_alpha) == "number" then
		profile.levelText.general.opacity = plate.level_text_alpha
	end
	if type(plate.level_text_shadow_color) == "table" then
		profile.levelText.shadow.enable = true
		profile.levelText.shadow.color = {
			plate.level_text_shadow_color[1] or 0,
			plate.level_text_shadow_color[2] or 0,
			plate.level_text_shadow_color[3] or 0,
			plate.level_text_shadow_color[4] or 1,
		}
	end
	if type(plate.level_text_shadow_color_offset) == "table" then
		profile.levelText.shadow.enable = true
		profile.levelText.shadow.xOffset = plate.level_text_shadow_color_offset[1] or 0
		profile.levelText.shadow.yOffset = plate.level_text_shadow_color_offset[2] or 0
	end

	if type(plate.spellpercent_text_enabled) == "boolean" then
		profile.castBar.spellTimeText.general.enable = plate.spellpercent_text_enabled
	end
	if plate.spellpercent_text_font then
		profile.castBar.spellTimeText.general.name = ResolveFontName(plate.spellpercent_text_font, profile.castBar.spellTimeText.general.name)
	end
	if plate.spellpercent_text_size then
		profile.castBar.spellTimeText.general.size = plate.spellpercent_text_size
	end
	if plate.spellpercent_text_outline then
		profile.castBar.spellTimeText.general.border = NormalizeOutline(plate.spellpercent_text_outline)
	end
	if type(plate.spellpercent_text_color) == "table" then
		profile.castBar.spellTimeText.general.color = {
			plate.spellpercent_text_color[1] or 1,
			plate.spellpercent_text_color[2] or 1,
			plate.spellpercent_text_color[3] or 1,
			plate.spellpercent_text_color[4] or 1,
		}
	end
	if type(plate.spellpercent_text_shadow_color) == "table" then
		profile.castBar.spellTimeText.shadow.enable = true
		profile.castBar.spellTimeText.shadow.color = {
			plate.spellpercent_text_shadow_color[1] or 0,
			plate.spellpercent_text_shadow_color[2] or 0,
			plate.spellpercent_text_shadow_color[3] or 0,
			plate.spellpercent_text_shadow_color[4] or 1,
		}
	end
	if type(plate.spellpercent_text_shadow_color_offset) == "table" then
		profile.castBar.spellTimeText.shadow.enable = true
		profile.castBar.spellTimeText.shadow.xOffset = plate.spellpercent_text_shadow_color_offset[1] or 0
		profile.castBar.spellTimeText.shadow.yOffset = plate.spellpercent_text_shadow_color_offset[2] or 0
	end

	if plate.spellname_text_font then
		profile.castBar.spellNameText.general.name = ResolveFontName(plate.spellname_text_font, profile.castBar.spellNameText.general.name)
	end
	if plate.spellname_text_size then
		profile.castBar.spellNameText.general.size = plate.spellname_text_size
	end
	if plate.spellname_text_outline then
		profile.castBar.spellNameText.general.border = NormalizeOutline(plate.spellname_text_outline)
	end
	if type(plate.spellname_text_color) == "table" then
		profile.castBar.spellNameText.general.color = {
			plate.spellname_text_color[1] or 1,
			plate.spellname_text_color[2] or 1,
			plate.spellname_text_color[3] or 1,
			plate.spellname_text_color[4] or 1,
		}
	end
	if type(plate.spellname_text_shadow_color) == "table" then
		profile.castBar.spellNameText.shadow.enable = true
		profile.castBar.spellNameText.shadow.color = {
			plate.spellname_text_shadow_color[1] or 0,
			plate.spellname_text_shadow_color[2] or 0,
			plate.spellname_text_shadow_color[3] or 0,
			plate.spellname_text_shadow_color[4] or 1,
		}
	end
	if type(plate.spellname_text_shadow_color_offset) == "table" then
		profile.castBar.spellNameText.shadow.enable = true
		profile.castBar.spellNameText.shadow.xOffset = plate.spellname_text_shadow_color_offset[1] or 0
		profile.castBar.spellNameText.shadow.yOffset = plate.spellname_text_shadow_color_offset[2] or 0
	end

	if type(platerProfile.aura_alpha) == "number" then
		profile.buffs.general.alpha = platerProfile.aura_alpha
	end
	if type(platerProfile.aura_padding) == "number" then
		profile.buffs.general.iconSpacing = platerProfile.aura_padding
	end
	if type(platerProfile.aura_width) == "number" then
		profile.buffs.auraFrame1.width = platerProfile.aura_width
	end
	if type(platerProfile.aura_height) == "number" then
		profile.buffs.auraFrame1.height = platerProfile.aura_height
	end
	if type(platerProfile.aura_border_thickness) == "number" then
		profile.buffs.auraFrame1.borderThickness = platerProfile.aura_border_thickness
	end
	if type(platerProfile.auras_per_row_amount) == "number" then
		profile.buffs.auraFrame1.rowCount = platerProfile.auras_per_row_amount
	end
	if type(platerProfile.aura_consolidate) == "boolean" then
		profile.buffs.general.stackSimilarAuras = platerProfile.aura_consolidate
	end
	if type(platerProfile.aura_consolidate_timeleft_lower) == "boolean" then
		profile.buffs.general.showShortestStackTime = platerProfile.aura_consolidate_timeleft_lower
	end
	if type(platerProfile.aura_timer) == "boolean" then
		profile.buffs.auraTimer.general.enable = platerProfile.aura_timer
	end
	if type(platerProfile.aura_timer_decimals) == "boolean" then
		profile.buffs.auraTimer.general.showDecimals = platerProfile.aura_timer_decimals
	end
	if type(platerProfile.aura_timer_text_size) == "number" then
		profile.buffs.auraTimer.general.size = platerProfile.aura_timer_text_size
	end
	if platerProfile.aura_timer_text_font then
		profile.buffs.auraTimer.general.name = ResolveFontName(platerProfile.aura_timer_text_font, profile.buffs.auraTimer.general.name)
	end
	if platerProfile.aura_timer_text_outline then
		profile.buffs.auraTimer.general.border = NormalizeOutline(platerProfile.aura_timer_text_outline)
	end
	if type(platerProfile.aura_timer_text_color) == "table" then
		profile.buffs.auraTimer.general.color = {
			platerProfile.aura_timer_text_color[1] or 1,
			platerProfile.aura_timer_text_color[2] or 1,
			platerProfile.aura_timer_text_color[3] or 1,
			platerProfile.aura_timer_text_color[4] or 1,
		}
	end

	if type(platerProfile.target_highlight) == "boolean" then
		profile.target.border.highlight.enable = platerProfile.target_highlight
	end
	if type(platerProfile.target_highlight_alpha) == "number" then
		profile.target.border.highlight.color[4] = platerProfile.target_highlight_alpha
	end
	if type(platerProfile.target_highlight_height) == "number" then
		profile.target.border.highlight.thickness = platerProfile.target_highlight_height
	end
	if type(platerProfile.target_highlight_color) == "table" then
		profile.target.border.highlight.color = {
			platerProfile.target_highlight_color[1] or 1,
			platerProfile.target_highlight_color[2] or 1,
			platerProfile.target_highlight_color[3] or 1,
			platerProfile.target_highlight_color[4] or 1,
		}
	end
	if type(platerProfile.target_highlight_texture) == "string" then
		profile.target.border.highlight.texture = ResolveTextureName(platerProfile.target_highlight_texture, profile.target.border.highlight.texture)
	end
	if type(platerProfile.target_indicator) == "string" and platerProfile.target_indicator ~= "" then
		profile.target.border.indicator.enable = true
		profile.target.border.indicator.selection = platerProfile.target_indicator
	end

	if type(platerProfile.health_selection_overlay) == "string" then
		profile.target.overlay.texture = ResolveTextureName(platerProfile.health_selection_overlay, profile.target.overlay.texture)
	end
	if type(platerProfile.health_selection_overlay_alpha) == "number" then
		profile.target.overlay.color[4] = platerProfile.health_selection_overlay_alpha
	end
	if type(platerProfile.health_selection_overlay_color) == "table" then
		profile.target.overlay.color = {
			platerProfile.health_selection_overlay_color[1] or 1,
			platerProfile.health_selection_overlay_color[2] or 1,
			platerProfile.health_selection_overlay_color[3] or 1,
			platerProfile.health_selection_overlay_color[4] or 1,
		}
	end

	if type(platerProfile.non_targeted_alpha_enabled) == "boolean" then
		profile.target.nonTargetAlpha.enable = platerProfile.non_targeted_alpha_enabled
	end
	if type(platerProfile.non_targeted_alpha) == "number" then
		profile.target.nonTargetAlpha.opacity = platerProfile.non_targeted_alpha
	end
	if type(platerProfile.target_shady_enabled) == "boolean" then
		profile.target.nonTargetShading.enable = platerProfile.target_shady_enabled
	end
	if type(platerProfile.target_shady_alpha) == "number" then
		profile.target.nonTargetShading.opacity = platerProfile.target_shady_alpha
	end
	if type(platerProfile.hover_highlight) == "boolean" then
		profile.target.mouseoverHighlight.enable = platerProfile.hover_highlight
	end
	if type(platerProfile.hover_highlight_alpha) == "number" then
		profile.target.mouseoverHighlight.opacity = platerProfile.hover_highlight_alpha
	end

	if type(platerProfile.indicator_raidmark) == "boolean" then
		profile.icons.raidIcon.general.enable = platerProfile.indicator_raidmark
	end
	if type(platerProfile.indicator_raidmark_scale) == "number" then
		local size = 20 * platerProfile.indicator_raidmark_scale
		profile.icons.raidIcon.size.width = size
		profile.icons.raidIcon.size.height = size
	end
	local raidAnchorPoint, raidX, raidY = ResolveAnchorPoint(platerProfile.indicator_raidmark_anchor)
	if raidAnchorPoint then
		profile.icons.raidIcon.position.anchor = raidAnchorPoint
		profile.icons.raidIcon.position.xOffset = raidX
		profile.icons.raidIcon.position.yOffset = raidY
	end

	if type(platerProfile.indicator_elite) == "boolean" then
		profile.icons.eliteIcon.general.enable = platerProfile.indicator_elite
	end
	if type(platerProfile.indicator_worldboss) == "boolean" then
		profile.icons.bossIcon.general.enable = platerProfile.indicator_worldboss
	end
	if type(platerProfile.indicator_faction) == "boolean" or type(platerProfile.indicator_friendlyfaction) == "boolean" then
		profile.icons.factionIcon.general.enable = platerProfile.indicator_faction or platerProfile.indicator_friendlyfaction
	end
	if type(platerProfile.indicator_enemyclass) == "boolean" or type(platerProfile.indicator_friendlyclass) == "boolean" then
		profile.icons.classIcon.general.enable = platerProfile.indicator_enemyclass or platerProfile.indicator_friendlyclass
	end
	if type(platerProfile.indicator_scale) == "number" and type(platerProfile.indicator_anchor) == "table" then
		local indicatorAnchorPoint, indicatorX, indicatorY = ResolveAnchorPoint(platerProfile.indicator_anchor)
		if indicatorAnchorPoint then
			profile.icons.classIcon.position.anchor = indicatorAnchorPoint
			profile.icons.classIcon.position.xOffset = indicatorX
			profile.icons.classIcon.position.yOffset = indicatorY
			profile.icons.factionIcon.position.anchor = indicatorAnchorPoint
			profile.icons.factionIcon.position.xOffset = indicatorX
			profile.icons.factionIcon.position.yOffset = indicatorY
			profile.icons.eliteIcon.position.anchor = indicatorAnchorPoint
			profile.icons.eliteIcon.position.xOffset = indicatorX
			profile.icons.eliteIcon.position.yOffset = indicatorY
			profile.icons.bossIcon.position.anchor = indicatorAnchorPoint
			profile.icons.bossIcon.position.xOffset = indicatorX
			profile.icons.bossIcon.position.yOffset = indicatorY
		end
		local base = 16 * platerProfile.indicator_scale
		profile.icons.classIcon.size.width = base
		profile.icons.classIcon.size.height = base
		profile.icons.eliteIcon.size.width = math.max(12, base * 0.75)
		profile.icons.eliteIcon.size.height = math.max(12, base * 0.75)
		profile.icons.factionIcon.size.width = math.max(12, base * 0.75)
		profile.icons.factionIcon.size.height = math.max(12, base * 0.75)
	end

	return profile
end

local function ShortName(name)
	if not name then
		return nil
	end
	local short = name:gsub("|c[Ff][Ff]%x%x%x%x%x%x", ""):gsub("|r", "")
	local dash = short:find("-")
	if dash then
		short = short:sub(1, dash - 1)
	end
	return short
end

local function RecordLinkedProfile(profileName)
	if profileName and profileName ~= "" then
		linkedProfiles[profileName] = GetTime()
	end
end

local function IsLinkedProfileRecent(profileName)
	if not profileName then
		return false
	end
	local timestamp = linkedProfiles[profileName]
	if not timestamp then
		return false
	end
	if (GetTime() - timestamp) > linkValidityDuration then
		linkedProfiles[profileName] = nil
		return false
	end
	return true
end

local function GetGroupChannelForTarget(target)
	local short = ShortName(target)
	if not short then
		return nil
	end
	for i = 1, GetNumRaidMembers() do
		local name = UnitName("raid" .. i)
		if name == short then
			return "RAID"
		end
	end
	for i = 1, GetNumPartyMembers() do
		local name = UnitName("party" .. i)
		if name == short then
			return "PARTY"
		end
	end
	return nil
end

local function SendProfileCommMessage(message, target, queueName, callbackFn, callbackArg)
	local channel = GetGroupChannelForTarget(target) or "WHISPER"
	local destination = target
	local payload = message
	if channel ~= "WHISPER" then
		local shortTarget = ShortName(target)
		payload = ("§§%s:%s"):format(shortTarget or target, message)
		destination = nil
	end
	AceComm:SendCommMessage(addonPrefix, payload, channel, destination, queueName, callbackFn, callbackArg)
end

local function OpenSharingOptions()
	local configModule = NotPlater:GetModule("Config", true)
	if configModule and configModule.OpenConfig then
		configModule:OpenConfig()
	end
	if dialog and dialog.SelectGroup then
		dialog:SelectGroup("NotPlater", "profile", "import")
	end
end

-- Local functions
local function TableToString(inTable, forPrint)
  local serialized = LibSerialize:SerializeEx(configForLS, inTable)
  local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
  local encoded = "!NP:1!"
  if forPrint then
    encoded = encoded .. LibDeflate:EncodeForPrint(compressed)
  else
    encoded = encoded .. LibDeflate:EncodeForWoWAddonChannel(compressed)
  end
  return encoded
end

local function StringToTable(inString, fromPrint)
  local _, _, encodeVersion, encoded = inString:find("^(!NP:%d+!)(.+)$")
  encodeVersion = tonumber(encodeVersion:match("%d+")) or 1
  local decoded
  if fromPrint then
    decoded = LibDeflate:DecodeForPrint(encoded)
  else
    decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
  end
  if not decoded then
    return "Error decoding."
  end
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if not decompressed then
    return "Error decompressing."
  end
  local success, deserialized = LibSerialize:Deserialize(decompressed)
  if not success then
    return "Error deserializing: " .. deserialized
  end
  return deserialized
end

local function ShowTooltip(lines)
  ItemRefTooltip:ClearLines()
  if not ItemRefTooltip:IsVisible() then
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
  end
  for i, line in ipairs(lines) do
    local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(line)
    if sides == 1 then
      ItemRefTooltip:AddLine(a1, a2, a3, a4, a5)
    elseif sides == 2 then
      ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8)
    end
  end
  ItemRefTooltip:Show()
end

local function HandleProfileChatFilter(msg, event, player, l, cs, t, flag, channelId, ...)
  local selfName = ShortName(UnitName("player"))
  if flag == "GM" or flag == "DEV" or (event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0) then
    return
  end
  local newMsg = ""
  local remaining = msg
  local done
  repeat
    local start, finish, characterName, profileName = remaining:find("%[NotPlater: ([^%s]+) %- (.*)%]")
    if characterName and profileName then
      characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "")
      profileName = profileName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "")
      if player and ShortName(player) == selfName then
        RecordLinkedProfile(profileName)
      end
      newMsg = newMsg .. remaining:sub(1, start - 1)
      newMsg = newMsg .. "|HNotPlater:" .. characterName .. ":" .. profileName .. "|h|cFF8800FF[" .. characterName .. " |r|cFF8800FF- " .. profileName .. "]|h|r"
      remaining = remaining:sub(finish + 1)
    else
      done = true
    end
  until done
  if newMsg ~= "" then
    if event == "CHAT_MSG_WHISPER" and not (UnitInParty(player) or UnitInRaid(player)) then
      return true -- Filter strangers not in group
    end
    return false, newMsg, player, l, cs, t, flag, channelId, ...
  end
end

local function LegacyChatFilter(msg, event, _, player, l, cs, t, flag, channelId, ...)
  return HandleProfileChatFilter(msg, event, player, l, cs, t, flag, channelId, ...)
end

local function ModernChatFilter(_, event, msg, player, l, cs, t, flag, channelId, ...)
  return HandleProfileChatFilter(msg, event, player, l, cs, t, flag, channelId, ...)
end

local chatFilterFunc = NotPlater.isWrathClient and ModernChatFilter or LegacyChatFilter

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", chatFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND_LEADER", chatFilterFunc)

local origSetItemRef = SetItemRef
SetItemRef = function(link, text, button, chatFrame)
  local linkType, characterName, profileName = link:match("^(%w+):([^:]+):(.+)$")
  if linkType == "NotPlater" and characterName and profileName then
    if IsShiftKeyDown() then
      local editbox = GetCurrentKeyBoardFocus()
      if editbox then
        editbox:Insert("[NotPlater: " .. characterName .. " - " .. profileName .. "]")
      end
    else
      ShowTooltip({
        {2, "NotPlater", profileName, 0.5, 0, 1, 1, 1, 1},
        {1, L["Requesting profile information from %s ..."]:format(characterName), 1, 0.82, 0},
        {1, L["Note, that cross realm transmission may not be supported in this version"], 1, 0.82, 0}
      })
      tooltipLoading = true
      receivedData = false
      ProfileSharing:RequestProfile(characterName, profileName)
      local timer = CreateFrame("Frame")
      timer:SetScript("OnUpdate", function(self, elapsed)
        self.time = (self.time or 0) + elapsed
        if self.time > 5 then
          if tooltipLoading and not receivedData then
            ShowTooltip({
              {2, "NotPlater", profileName, 0.5, 0, 1, 1, 1, 1},
              {1, L["Error not receiving profile information from %s"]:format(characterName), 1, 0, 0},
              {1, L["Note, that cross realm transmission may not be supported in this version"], 1, 0.82, 0}
            })
          end
          self:SetScript("OnUpdate", nil)
        end
      end)
    end
  else
    origSetItemRef(link, text, button, chatFrame)
  end
end

function ProfileSharing:OnInitialize()
  self.exportString = ""
  self.importString = ""
  self.importProfileName = ""
  self.switchToImportedProfile = true
  self.lastExportSummary = L["Generate an export string to populate this field."]
  self.lastImportSummary = L["No import has been processed yet."]
  AceComm:RegisterComm(addonPrefix, function(_, message, distribution, sender)
    local payload
    if distribution == "WHISPER" then
      payload = message
    elseif distribution == "PARTY" or distribution == "RAID" then
      local dest, encoded = message:match("^§§([^:]+):(.+)$")
      if not dest then
        return
      end
      local playerShort = ShortName(UnitName("player"))
      if ShortName(dest) ~= playerShort then
        return
      end
      payload = encoded
    else
      return
    end

    local received = StringToTable(payload, false)
    if type(received) == "string" then
      return
    end

    local senderKey = ShortName(sender) or sender

    if received.m == "pR" then
      local requestedProfile = received.n
      if not requestedProfile then
        return
      end
      if not safeSenders[senderKey] and not IsLinkedProfileRecent(requestedProfile) then
        return
      end
      self:TransmitProfile(sender, requestedProfile)
    elseif received.m == "p" then
      if not safeSenders[senderKey] then
        return
      end
      safeSenders[senderKey] = nil
      tooltipLoading = false
      receivedData = true
      ItemRefTooltip:Hide()
      local data = received.d
      local profName = received.n
      local serialized = LibSerialize:SerializeEx(configForLS, data)
      local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
      local encoded = "!NP:1!" .. LibDeflate:EncodeForPrint(compressed)
      self:SetImportString(encoded)
      self:SetImportProfileName("Imported from " .. (ShortName(sender) or sender) .. " (" .. profName .. ")")
      OpenSharingOptions()
    end
  end)
end

function ProfileSharing:GenerateExportString()
  local profile = NotPlater.db.profile
  local data = CopyTable(profile)
  local serialized = LibSerialize:SerializeEx(configForLS, data)
  if not serialized then
    return nil, "Serialization failed"
  end
  local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
  local encoded = LibDeflate:EncodeForPrint(compressed)
  self.exportString = "!NP:1!" .. encoded
  self.lastExportSummary = L["Profile exported: "] .. NotPlater.db:GetCurrentProfile()
  return self.exportString
end

function ProfileSharing:GetExportString()
  return self.exportString
end

function ProfileSharing:InsertShareLink()
  local raidMembers = GetNumRaidMembers()
  local partyMembers = GetNumPartyMembers()
  local channel
  if raidMembers and raidMembers > 0 then
    channel = "RAID"
  elseif partyMembers and partyMembers > 0 then
    channel = "PARTY"
  else
    NotPlater:Print(L["Profile sharing requires being in a party or raid."])
    return false
  end
  local profileName = NotPlater.db:GetCurrentProfile()
  local link = "[NotPlater: " .. UnitName("player") .. " - " .. profileName .. "]"
  SendChatMessage(link, channel)
  RecordLinkedProfile(profileName)
  return true
end

function ProfileSharing:SetImportString(value)
  self.importString = value
end

function ProfileSharing:GetImportString()
  return self.importString
end

function ProfileSharing:SetImportProfileName(value)
  self.importProfileName = value
end

function ProfileSharing:GetImportProfileName()
  return self.importProfileName
end

function ProfileSharing:SetSwitchToImportedProfile(value)
  self.switchToImportedProfile = value
end

function ProfileSharing:GetSwitchToImportedProfile()
  return self.switchToImportedProfile
end

function ProfileSharing:GetLastExportSummary()
  return self.lastExportSummary
end

function ProfileSharing:GetLastImportSummary()
  return self.lastImportSummary
end

function ProfileSharing:DecodeImportString(value)
	if type(value) == "string" and value:match("^!NP:1!") then
		local data = StringToTable(value, true)
		if type(data) == "string" then
			return nil, data
		end
		return data, nil, "notplater"
	end
	local data, err = self:DecodePlaterImportString(value)
	if data then
		return data, nil, "plater"
	end
	return nil, err or L["Invalid import string"]
end

function ProfileSharing:ImportProfileFromString(value, profileName, switchToImportedProfile)
	local data, err, source = self:DecodeImportString(value)
	if not data then
		self.lastImportSummary = err
		return false, err
	end
	if source == "plater" then
		data = self:ConvertPlaterProfile(data)
		if not data then
			self.lastImportSummary = L["Invalid import string"]
			return false, self.lastImportSummary
		end
	end
	local name = profileName
	if not name or name == "" then
		name = "Imported"
	end
	local baseName = name
	local i = 2
	while NotPlater.db.profiles[name] do
		name = baseName .. " " .. i
		i = i + 1
	end
	NotPlater.db.profiles[name] = data
	if source == "plater" then
		self.lastImportSummary = L["Imported Plater profile as "] .. name
	else
		self.lastImportSummary = L["Imported as "] .. name
	end
	if switchToImportedProfile then
		NotPlater.db:SetProfile(name)
		NotPlater:Reload()
	end
	if registry then
		registry:NotifyChange("NotPlater")
	end
	return true, name
end

function ProfileSharing:ImportFromOptions()
	self:ImportProfileFromString(self.importString, self.importProfileName, self.switchToImportedProfile)
end

function ProfileSharing:RequestProfile(characterName, profileName)
  local senderKey = ShortName(characterName) or characterName
  safeSenders[senderKey] = true
  local transmit = {m = "pR", n = profileName}
  local transmitString = TableToString(transmit, false)
  SendProfileCommMessage(transmitString, characterName)
end

function ProfileSharing:TransmitProfile(characterName, requestedProfile)
  local profileName = requestedProfile or NotPlater.db:GetCurrentProfile()
  local sourceProfile = NotPlater.db.profiles[profileName]
  if not sourceProfile then
    profileName = NotPlater.db:GetCurrentProfile()
    sourceProfile = NotPlater.db.profile
  end
  local data = CopyTable(sourceProfile)
  local transmit = {m = "p", d = data, n = profileName}
  local encoded = TableToString(transmit, false)
  SendProfileCommMessage(encoded, characterName, "BULK")
end
