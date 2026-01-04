if not NotPlater then return end

local L = NotPlaterLocals
local dialog = LibStub("AceConfigDialog-3.0", true)
local tinsert = table.insert
local tsort = table.sort
local ceil = math.ceil
local ipairs = ipairs
local pairs = pairs
local unpack = unpack
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local GetTime = GetTime
local tostring = tostring

local TEMPLATE_COLUMNS = 2
local TEMPLATE_SPACING = 12
local TEMPLATE_MIN_WIDTH = 240
local TEMPLATE_HEIGHT = 110
local TEMPLATE_PADDING = 8
local SIM_CAST_TIME = 5000
local RAID_ICON_BASE_PATH = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local MAX_RAID_ICONS = 8
local RAID_ICON_INTERVAL = 5

local function GetConfigContentFrame()
	if not dialog then
		return nil
	end
	local root = dialog.OpenFrames["NotPlater"]
	if not root or not root.children then
		return nil
	end
	for _, child in ipairs(root.children) do
		if child.type == "TreeGroup" and child.content then
			return child.content
		end
	end
	return nil
end

local function RunWithProfile(profile, func, ...)
	if not profile then
		return func(...)
	end
	local original = NotPlater.db.profile
	NotPlater.db.profile = profile
	local result1, result2, result3, result4 = func(...)
	NotPlater.db.profile = original
	return result1, result2, result3, result4
end

local function RunWithProfileAndAuras(profile, func, ...)
	if not profile then
		return func(...)
	end
	local original = NotPlater.db.profile
	local auraModule = NotPlater.Auras
	NotPlater.db.profile = profile
	if auraModule and auraModule.RefreshConfig then
		auraModule:RefreshConfig()
	end
	local results = {func(...)}
	NotPlater.db.profile = original
	if auraModule and auraModule.RefreshConfig then
		auraModule:RefreshConfig()
	end
	return unpack(results)
end

local function TemplateCastBarOnUpdate(self, elapsed)
	local profile = self.npTemplateProfile or (self.GetParent and self:GetParent().npTemplateProfile)
	if profile then
		local original = NotPlater.db.profile
		NotPlater.db.profile = profile
		NotPlater.CastBarOnUpdate(self, elapsed)
		NotPlater.db.profile = original
	else
		NotPlater.CastBarOnUpdate(self, elapsed)
	end
end

local function StartSimulatedCast(frame)
	if not frame or not frame.castBar then
		return
	end
	if frame.castBar.casting or frame.castBar.channeling then
		return
	end
	if not NotPlater.db.profile.castBar.statusBar.general.enable then
		frame.castBar.casting = false
		return
	end
	local startTime = GetTime()
	local endTime = startTime + SIM_CAST_TIME
	NotPlater:SetCastBarNameText(frame, L["Spellname"])
	frame.castBar.value = 0
	frame.castBar.maxValue = (endTime - startTime) / 1000
	frame.castBar:SetMinMaxValues(0, frame.castBar.maxValue)
	frame.castBar:SetValue(frame.castBar.value)
	if frame.castBar.icon then
		frame.castBar.icon.texture:SetTexture("Interface\\Icons\\Temp")
	end
	frame.castBar.casting = true
	frame.castBar:Show()
end

local function UpdateSimulatedRaidIcon(frame, elapsed)
	if not frame or not frame.defaultRaidIcon then
		return
	end
	local elapsedValue = frame.npRaidIconElapsed or RAID_ICON_INTERVAL
	elapsedValue = elapsedValue + elapsed
	if elapsedValue > RAID_ICON_INTERVAL then
		local iconIndex = frame.npRaidIconIndex or 1
		frame.defaultRaidIcon:SetTexture(RAID_ICON_BASE_PATH .. tostring(iconIndex))
		iconIndex = iconIndex + 1
		if iconIndex > MAX_RAID_ICONS then
			iconIndex = 1
		end
		frame.npRaidIconIndex = iconIndex
		elapsedValue = 0
	end
	frame.npRaidIconElapsed = elapsedValue
end

function NotPlater:GetTemplateList()
	local data = self.TemplateData
	local list = {}
	if data then
		for name, importString in pairs(data) do
			if type(name) == "string" and name ~= "" and type(importString) == "string" and importString ~= "" then
				tinsert(list, {name = name, importString = importString})
			end
		end
	end
	tsort(list, function(a, b)
		return a.name < b.name
	end)
	return list
end

function NotPlater:GetSelectedTemplateName()
	return self.selectedTemplateName
end

function NotPlater:SelectTemplate(name)
	self.selectedTemplateName = name
	self:UpdateTemplateSelection()
end

function NotPlater:ActivateSelectedTemplate()
	local selected = self:GetSelectedTemplateName()
	if not selected then
		self:Print(L["Select a template to activate."])
		return
	end
	local templateData = self.TemplateData and self.TemplateData[selected]
	if not templateData then
		self:Print(L["Select a template to activate."])
		return
	end
	local profileSharing = self:GetModule("ProfileSharing", true)
	if not profileSharing or not profileSharing.ImportProfileFromString then
		self:Print(L["Profile sharing is currently disabled."])
		return
	end
	local ok = profileSharing:ImportProfileFromString(templateData, selected, true)
	local summary = profileSharing:GetLastImportSummary()
	if ok and summary then
		self:Print(summary)
	elseif summary then
		self:Print(summary)
	end
end

function NotPlater:TemplateGalleryOnUpdate(elapsed)
	if not dialog or not dialog.GetStatusTable then
		return
	end
	self.templateGalleryElapsed = (self.templateGalleryElapsed or 0) + elapsed
	if self.templateGalleryElapsed < 0.1 then
		return
	end
	self.templateGalleryElapsed = 0
	local status = dialog:GetStatusTable("NotPlater")
	local selected = status and status.groups and status.groups.selected
	if selected ~= self.templateGalleryLastGroup then
		self.templateGalleryLastGroup = selected
		self:UpdateTemplateGalleryVisibility()
	end
end

function NotPlater:HookTemplateGalleryWatcher(frame)
    if self.templateGalleryWatcher then
        return
    end
    local anchor = frame and frame.frame or frame
    if not anchor or not anchor.SetScript then
        return
    end
    self.templateGalleryWatcher = true
    
    local function GalleryOnUpdate(_, elapsed)
        NotPlater:TemplateGalleryOnUpdate(elapsed)
    end
    
    local oldOnUpdate = anchor:GetScript("OnUpdate")
    if oldOnUpdate then
        anchor:HookScript("OnUpdate", GalleryOnUpdate)
    else
        anchor:SetScript("OnUpdate", GalleryOnUpdate)
    end
end

function NotPlater:UpdateTemplateGalleryVisibility()
	if not dialog or not dialog.GetStatusTable then
		return
	end
	local status = dialog:GetStatusTable("NotPlater")
	local selected = status and status.groups and status.groups.selected
	if selected == "templates" then
		self:ShowTemplateGallery()
	else
		self:HideTemplateGallery()
	end
end

function NotPlater:ShowTemplateGallery()
	local parent = GetConfigContentFrame()
	if not parent then
		return
	end
	local gallery = self.templateGallery
	if not gallery then
		gallery = self:CreateTemplateGallery(parent)
		self.templateGallery = gallery
	else
		gallery:SetParent(parent)
		gallery:ClearAllPoints()
		gallery:SetAllPoints(parent)
	end
    if not gallery.npHideHooked then
        gallery.npHideHooked = true
        parent:HookScript("OnHide", function()
            NotPlater:HideTemplateGallery()
        end)
    end
	gallery:Show()
	self:RefreshTemplateGallery()
	if not self:GetSelectedTemplateName() and gallery.templates and #gallery.templates > 0 then
		self:SelectTemplate(gallery.templates[1].name)
	end
end

function NotPlater:HideTemplateGallery()
	local gallery = self.templateGallery
	if gallery then
		local simAuras = self.SimulatorAuras
		if simAuras and simAuras.OnHide and gallery.cards then
			for _, card in ipairs(gallery.cards) do
				if card.previewFrame then
					simAuras:OnHide(card.previewFrame)
                    card.previewFrame:Hide()
				end
			end
		end
		self:ResetTemplateGallerySimulation()
		gallery:Hide()
	end
end

function NotPlater:ResetTemplateGallerySimulation()
	local gallery = self.templateGallery
	if not gallery or not gallery.cards then
		self.templateGalleryElapsed = nil
		self.templateGalleryLastGroup = nil
		return
	end
	for _, card in ipairs(gallery.cards) do
		local preview = card.previewFrame
		if preview then
			preview.targetChanged = true
			preview.npRaidIconElapsed = nil
			preview.npRaidIconIndex = nil
			if preview.castBar then
				preview.castBar.casting = nil
				preview.castBar.channeling = nil
				preview.castBar.value = 0
				preview.castBar.maxValue = 0
				preview.castBar:SetValue(0)
				preview.castBar:Hide()
			end
		end
	end
	self.templateGalleryElapsed = nil
	self.templateGalleryLastGroup = nil
end

function NotPlater:CreateTemplateGallery(parent)
	local gallery = CreateFrame("Frame", nil, parent)
	gallery:SetAllPoints(parent)
	gallery:Hide()

	gallery.header = gallery:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	gallery.header:SetPoint("TOPLEFT", gallery, "TOPLEFT", 8, -8)
	gallery.header:SetText(L["Templates"])

	gallery.description = gallery:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	gallery.description:SetPoint("TOPLEFT", gallery.header, "BOTTOMLEFT", 0, -6)
	gallery.description:SetPoint("RIGHT", gallery, "RIGHT", -8, 0)
	gallery.description:SetJustifyH("LEFT")
	gallery.description:SetText(L["Preview a template, then activate it to import as a new profile and set it active."])

	gallery.activateButton = CreateFrame("Button", "NotPlaterTemplateGalleryActivateButton", gallery, "UIPanelButtonTemplate")
	gallery.activateButton:SetPoint("TOPLEFT", gallery.description, "BOTTOMLEFT", 0, -10)
	self:SetSize(gallery.activateButton, 200, 22)
	gallery.activateButton:SetText(L["Activate Selected Template"])
	gallery.activateButton:SetScript("OnClick", function()
		NotPlater:ActivateSelectedTemplate()
	end)

	gallery.scrollFrame = CreateFrame("ScrollFrame", "NotPlaterTemplateGalleryScrollFrame", gallery, "UIPanelScrollFrameTemplate")
	gallery.scrollFrame:SetPoint("TOPLEFT", gallery.activateButton, "BOTTOMLEFT", 0, -12)
	gallery.scrollFrame:SetPoint("BOTTOMRIGHT", gallery, "BOTTOMRIGHT", -26, 10)
	gallery.scrollFrame:SetScript("OnSizeChanged", function()
		NotPlater:LayoutTemplateGallery()
	end)

	gallery.scrollChild = CreateFrame("Frame", nil, gallery.scrollFrame)
	gallery.scrollChild:SetPoint("TOPLEFT")
	self:SetSize(gallery.scrollChild, 1, 1)
	gallery.scrollFrame:SetScrollChild(gallery.scrollChild)

	gallery.emptyText = gallery.scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	gallery.emptyText:SetPoint("TOPLEFT", gallery.scrollChild, "TOPLEFT", 4, -4)
	gallery.emptyText:SetJustifyH("LEFT")
	gallery.emptyText:SetText(L["No templates are defined in template_data.lua."])
	gallery.emptyText:Hide()

	gallery.cards = {}
	gallery:SetScript("OnUpdate", function(_, elapsed)
		NotPlater:TemplateGalleryPreviewUpdate(elapsed)
	end)
	return gallery
end

local function GetCardWidth(gallery)
	local width = gallery.scrollFrame:GetWidth()
	if not width or width <= 0 then
		return TEMPLATE_MIN_WIDTH
	end
	local spacing = TEMPLATE_SPACING * (TEMPLATE_COLUMNS - 1)
	local usable = width - spacing
	if usable <= 0 then
		return TEMPLATE_MIN_WIDTH
	end
	local cardWidth = math.floor(usable / TEMPLATE_COLUMNS)
	if cardWidth < TEMPLATE_MIN_WIDTH then
		cardWidth = TEMPLATE_MIN_WIDTH
	end
	return cardWidth
end

local function CreateTemplateCard(gallery)
	local card = CreateFrame("Button", nil, gallery.scrollChild)
	card:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	card:SetBackdropColor(0, 0, 0, 0.2)
	card:SetBackdropBorderColor(0, 0, 0, 0)
	card:SetScript("OnEnter", function(self)
		NotPlater:TemplateCardOnEnter(self)
	end)
	card:SetScript("OnLeave", function(self)
		NotPlater:TemplateCardOnLeave(self)
	end)
	card:SetScript("OnClick", function(self)
		NotPlater:SelectTemplate(self.templateName)
	end)

	card.label = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	card.label:SetPoint("TOPLEFT", card, "TOPLEFT", TEMPLATE_PADDING, -TEMPLATE_PADDING)
	card.label:SetJustifyH("LEFT")

	card.errorText = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	card.errorText:SetPoint("CENTER", card, "CENTER", 0, 0)
	card.errorText:SetText("")
	card.errorText:Hide()

	return card
end

function NotPlater:TemplateCardOnEnter(card)
	card.isHovered = true
	if not card.isSelected then
		card:SetBackdropBorderColor(0.4, 0.7, 1, 0.9)
	end
end

function NotPlater:TemplateCardOnLeave(card)
	card.isHovered = false
	if not card.isSelected then
		card:SetBackdropBorderColor(0, 0, 0, 0)
	end
end

function NotPlater:UpdateTemplateSelection()
	local gallery = self.templateGallery
	if not gallery then
		return
	end
	local selected = self:GetSelectedTemplateName()
	for _, card in ipairs(gallery.cards) do
		if card:IsShown() then
			local isSelected = selected and card.templateName == selected
			card.isSelected = isSelected
			if isSelected then
				card:SetBackdropBorderColor(1, 0.82, 0, 1)
			elseif card.isHovered then
				card:SetBackdropBorderColor(0.4, 0.7, 1, 0.9)
			else
				card:SetBackdropBorderColor(0, 0, 0, 0)
			end
		end
	end
	if gallery.activateButton then
		if selected then
			gallery.activateButton:Enable()
		else
			gallery.activateButton:Disable()
		end
	end
end

function NotPlater:ApplyTemplatePreviewData(frame, templateName)
	if not frame then
		return
	end
	frame.defaultNameText:SetText(templateName)
	frame.defaultLevelText:SetText(L["70"])
	frame.defaultLevelText:SetTextColor(1, 1, 0, 1)

	local _, classToken = UnitClass("player")
	if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
		frame.unitClassToken = classToken
		frame.unitClass = RAID_CLASS_COLORS[classToken]
	end
	frame.unitFaction = UnitFactionGroup("player")

	self:NameTextOnShow(frame)
	self:LevelTextOnShow(frame.levelText, frame.healthBar)

	if self.db.profile.healthBar.statusBar.general.useClassColors and frame.unitClass then
		frame.healthBar:SetStatusBarColor(frame.unitClass.r, frame.unitClass.g, frame.unitClass.b, 1)
	end
	if self.db.profile.nameText.general.useClassColor and not frame.filterHideNameText and frame.unitClass then
		frame.nameText:SetTextColor(frame.unitClass.r, frame.unitClass.g, frame.unitClass.b, 1)
	end

	self:UpdateClassIcon(frame)
	self:UpdateFactionIcon(frame)
	self:UpdateEliteIcon(frame)
	self:UpdateNpcIcons(frame)

	local _, maxValue = frame.defaultHealthFrame:GetMinMaxValues()
	self:HealthOnValueChanged(frame.defaultHealthFrame, maxValue)
end

function NotPlater:UpdateTemplatePreviewFrame(frame, elapsed)
	if not frame or not frame.npTemplateProfile then
		return
	end
	local profile = frame.npTemplateProfile
	RunWithProfileAndAuras(profile, function()
		if frame.targetChanged then
			NotPlater:TargetCheck(frame)
			frame.targetChanged = nil
		end
		if NotPlater:IsTarget(frame) then
			StartSimulatedCast(frame)
		end
	end)
	UpdateSimulatedRaidIcon(frame, elapsed)
	local simAuras = NotPlater.SimulatorAuras
	if simAuras and simAuras.OnUpdate then
		RunWithProfileAndAuras(profile, function()
			simAuras:OnUpdate(elapsed, frame)
		end)
	end
end

function NotPlater:TemplateGalleryPreviewUpdate(elapsed)
	local gallery = self.templateGallery
	if not gallery or not gallery:IsShown() then
		return
	end
	for _, card in ipairs(gallery.cards) do
		local preview = card.previewFrame
		if preview and preview:IsShown() then
			self:UpdateTemplatePreviewFrame(preview, elapsed)
		end
	end
end

local worldHelper = CreateFrame("Frame", nil, WorldFrame)
worldHelper:SetFrameStrata("TOOLTIP")

function NotPlater:UpdateTemplatePreview(card, profileData, templateName)
	local preview = card.previewFrame
	if not preview then
		preview = self:ConstructSimulatedPlate(card)
		preview.isTemplatePreview = true
		preview:EnableMouse(true)
		preview:SetPoint("CENTER", card, "CENTER", 0, -14)
		card.previewFrame = preview
	end
    preview:SetParent(worldHelper)
    preview:ClearAllPoints()
    preview:SetPoint("CENTER", card, "CENTER", 0, -14)
	preview.npTemplateProfile = profileData
	preview.npTemplateCard = card
	if not preview.npTemplateClickHooked then
		preview.npTemplateClickHooked = true
		preview:RegisterForClicks("AnyDown")
		preview:SetScript("OnClick", function(self, mouseButton)
			if self.npTemplateCard and self.npTemplateCard.templateName then
				NotPlater:SelectTemplate(self.npTemplateCard.templateName)
			end
			if mouseButton == "LeftButton" or mouseButton == "RightButton" then
				self.simulatedTarget = not self.simulatedTarget
				self.targetChanged = true
			end
		end)
	end
	if preview.simulatedTarget == nil then
		preview.simulatedTarget = true
	end
	preview.targetChanged = true
	RunWithProfileAndAuras(profileData, function()
		NotPlater:PrepareFrame(preview)
		if NotPlater.Auras then
			if NotPlater.Auras.AttachToFrame then
				NotPlater.Auras:AttachToFrame(preview)
			end
			if NotPlater.Auras.ConfigureFrame then
				NotPlater.Auras:ConfigureFrame(preview)
			end
		end
		NotPlater:ApplyTemplatePreviewData(preview, templateName)
	end)
	if preview.castBar and preview.castBar.GetScript then
		preview.castBar.npTemplateProfile = profileData
		if not preview.castBar.npTemplateCastHooked then
			preview.castBar.npTemplateCastHooked = true
			preview.castBar:SetScript("OnUpdate", TemplateCastBarOnUpdate)
		end
	end
	if NotPlater.SimulatorAuras and NotPlater.SimulatorAuras.AttachFrame then
		NotPlater.SimulatorAuras:AttachFrame(preview)
		if NotPlater.SimulatorAuras.OnShow then
			NotPlater.SimulatorAuras:OnShow(preview)
		end
	end
	preview:Show()
end

function NotPlater:RefreshTemplateGallery()
	local gallery = self.templateGallery
	if not gallery then
		return
	end
	local templates = self:GetTemplateList()
	gallery.templates = templates
	if #templates == 0 then
		gallery.emptyText:Show()
		gallery.scrollFrame:Hide()
		self:UpdateTemplateSelection()
		return
	end
	gallery.emptyText:Hide()
	gallery.scrollFrame:Show()

	for index, info in ipairs(templates) do
		local card = gallery.cards[index]
		if not card then
			card = CreateTemplateCard(gallery)
			gallery.cards[index] = card
		end
		card.templateName = info.name
		card.importString = info.importString
		card.label:SetText(info.name)
		card.errorText:Hide()
		card:Show()

		local profileSharing = self:GetModule("ProfileSharing", true)
		local profileData = profileSharing and profileSharing.DecodeImportString and profileSharing:DecodeImportString(info.importString)
		if not profileData then
			card.errorText:SetText(L["Invalid import string"])
			card.errorText:Show()
			if card.previewFrame then
				if NotPlater.SimulatorAuras and NotPlater.SimulatorAuras.OnHide then
					NotPlater.SimulatorAuras:OnHide(card.previewFrame)
				end
				card.previewFrame:Hide()
			end
		else
			card.errorText:Hide()
			self:UpdateTemplatePreview(card, profileData, info.name)
		end
	end

	for i = #templates + 1, #gallery.cards do
		local card = gallery.cards[i]
		if card.previewFrame and NotPlater.SimulatorAuras and NotPlater.SimulatorAuras.OnHide then
			NotPlater.SimulatorAuras:OnHide(card.previewFrame)
		end
		card:Hide()
	end

	self:LayoutTemplateGallery()
	self:UpdateTemplateSelection()
end

function NotPlater:LayoutTemplateGallery()
	local gallery = self.templateGallery
	if not gallery or not gallery.templates then
		return
	end
	local cardWidth = GetCardWidth(gallery)
	local total = #gallery.templates
	if total == 0 then
		return
	end
	for index = 1, total do
		local card = gallery.cards[index]
		if card and card:IsShown() then
			self:SetSize(card, cardWidth, TEMPLATE_HEIGHT)
			card.label:SetWidth(cardWidth - (TEMPLATE_PADDING * 2))
			local row = math.floor((index - 1) / TEMPLATE_COLUMNS)
			local col = (index - 1) % TEMPLATE_COLUMNS
			local x = (cardWidth + TEMPLATE_SPACING) * col
			local y = (TEMPLATE_HEIGHT + TEMPLATE_SPACING) * row
			card:ClearAllPoints()
			card:SetPoint("TOPLEFT", gallery.scrollChild, "TOPLEFT", x, -y)
			if card.previewFrame then
				card.previewFrame:ClearAllPoints()
				card.previewFrame:SetPoint("CENTER", card, "CENTER", 0, -14)
			end
		end
	end
	local rows = ceil(total / TEMPLATE_COLUMNS)
	local height = (rows * TEMPLATE_HEIGHT) + ((rows - 1) * TEMPLATE_SPACING)
	gallery.scrollChild:SetWidth(gallery.scrollFrame:GetWidth())
	gallery.scrollChild:SetHeight(height)
end
