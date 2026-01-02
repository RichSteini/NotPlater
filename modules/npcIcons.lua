if( not NotPlater ) then return end

local playerFaction = UnitFactionGroup("player")
local band = bit.band
local ceil = math.ceil
local floor = math.floor
local max = math.max
local tinsert = table.insert

local ICONS = {
	{ key = "vendor", texture = "Interface\\ICONS\\INV_Misc_Bag_10", flag = "Vendor" },
	{ key = "repair", texture = "Interface\\MINIMAP\\TRACKING\\Repair", flag = "Repair" },
	{ key = "innkeeper", texture = "Interface\\MINIMAP\\TRACKING\\Innkeeper", flag = "Innkeeper" },
	{ key = "flightMaster", texture = "Interface\\MINIMAP\\TRACKING\\FlightMaster", flag = "FlightMaster" },
	{ key = "auctioneer", texture = "Interface\\MINIMAP\\TRACKING\\Auctioneer", flag = "Auctioneer" },
	{ key = "banker", texture = "Interface\\MINIMAP\\TRACKING\\Banker", flag = "Banker" },
	{ key = "classTrainer", trainer = true },
}

local CLASS_ICON_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local CLASS_ICON_TCOORDS = {
	WARRIOR = {0, 0.25, 0, 0.25},
	MAGE = {0.25, 0.5, 0, 0.25},
	ROGUE = {0.5, 0.75, 0, 0.25},
	DRUID = {0.75, 1, 0, 0.25},
	HUNTER = {0, 0.25, 0.25, 0.5},
	SHAMAN = {0.25, 0.5, 0.25, 0.5},
	PRIEST = {0.5, 0.75, 0.25, 0.5},
	WARLOCK = {0.75, 1, 0.25, 0.5},
	PALADIN = {0, 0.25, 0.5, 0.75},
	DEATHKNIGHT = {0.25, 0.5, 0.5, 0.75},
}

local function GetTrainerClassToken(trainerId)
	local enums = NotPlater.NPCEnums and NotPlater.NPCEnums.Trainer
	if not enums then
		return nil
	end
	if trainerId == enums.Druid then return "DRUID" end
	if trainerId == enums.Rogue then return "ROGUE" end
	if trainerId == enums.Warrior then return "WARRIOR" end
	if trainerId == enums.Paladin then return "PALADIN" end
	if trainerId == enums.Hunter then return "HUNTER" end
	if trainerId == enums.Priest then return "PRIEST" end
	if trainerId == enums.DeathKnight then return "DEATHKNIGHT" end
	if trainerId == enums.Shaman then return "SHAMAN" end
	if trainerId == enums.Mage then return "MAGE" end
	if trainerId == enums.Warlock then return "WARLOCK" end
	return nil
end

local function GetTrainerProfessionIcon(trainerId)
	local enums = NotPlater.NPCEnums and NotPlater.NPCEnums.Trainer
	if not enums then
		return nil
	end
	if trainerId == enums.Alchemy then return "Interface\\Icons\\Trade_Alchemy" end
	if trainerId == enums.Blacksmithing then return "Interface\\Icons\\Trade_BlackSmithing" end
	if trainerId == enums.Enchanting then return "Interface\\Icons\\Trade_Engraving" end
	if trainerId == enums.Engineering then return "Interface\\Icons\\Trade_Engineering" end
	if trainerId == enums.Herbalism then return "Interface\\Icons\\Trade_Herbalism" end
	if trainerId == enums.Inscription then return "Interface\\Icons\\INV_Inscription_Tradeskill01" end
	if trainerId == enums.Jewelcrafting then return "Interface\\Icons\\INV_Misc_Gem_01" end
	if trainerId == enums.Leatherworking then return "Interface\\Icons\\Trade_LeatherWorking" end
	if trainerId == enums.Tailoring then return "Interface\\Icons\\Trade_Tailoring" end
	if trainerId == enums.Mining then return "Interface\\Icons\\Trade_Mining" end
	if trainerId == enums.Skinning then return "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" end
	if trainerId == enums.Cooking then return "Interface\\Icons\\INV_Misc_Food_15" end
	if trainerId == enums.FirstAid then return "Interface\\Icons\\Spell_Holy_SealOfSacrifice" end
	if trainerId == enums.Fishing then return "Interface\\Icons\\Trade_Fishing" end
	if trainerId == enums.Riding then return "Interface\\Icons\\Ability_Mount_RidingHorse" end
	return nil
end

local function IsFactionMatch(factionId)
	local enums = NotPlater.NPCEnums and NotPlater.NPCEnums.Faction
	if not enums then
		return false
	end
	if playerFaction == "Horde" then
		return factionId == enums.Horde
	end
	if playerFaction == "Alliance" then
		return factionId == enums.Alliance
	end
	return false
end

local function IsClassTrainer(trainerId)
	local enums = NotPlater.NPCEnums and NotPlater.NPCEnums.Trainer
	if not enums then
		return false
	end
	return trainerId and trainerId >= enums.Druid and trainerId <= enums.Warlock
end

local function PositionIcon(container, icon, index, perRow, totalIcons, growDirection, size, spacing, rowSpacing)
	local iconWidth = size.width or 12
	local iconHeight = size.height or 12
	local stepX = iconWidth + spacing
	local stepY = iconHeight + rowSpacing
	local row = floor((index - 1) / perRow)
	local column = (index - 1) % perRow
	local totalRows = max(1, ceil(totalIcons / perRow))
	local isLastRow = (row == totalRows - 1)
	local iconsInRow = isLastRow and max(1, totalIcons - row * perRow) or perRow
	icon:ClearAllPoints()
	if growDirection == "LEFT" then
		icon:SetPoint("TOPRIGHT", container, "TOPRIGHT", -(column * stepX), -row * stepY)
	elseif growDirection == "CENTER" then
		local offset = column - ((iconsInRow - 1) / 2)
		icon:SetPoint("TOP", container, "TOP", offset * stepX, -row * stepY)
	else
		icon:SetPoint("TOPLEFT", container, "TOPLEFT", column * stepX, -row * stepY)
	end
end

function NotPlater:ConstructNpcIcons(frame)
	if not frame or frame.npcIcons then
		return
	end
	local container = CreateFrame("Frame", nil, frame)
	container.icons = {}
	frame.npcIcons = container
end

function NotPlater:ConfigureNpcIcons(frame)
	if not frame or not frame.npcIcons then
		return
	end
	self:UpdateNpcIcons(frame)
end

function NotPlater:ScaleNpcIcons(frame, isTarget)
	if not frame or not frame.npcIcons then
		return
	end
	local scaleConfig = self.db.profile.target.scale
	if not scaleConfig.npcIcons then
		frame.npcIconsScale = 1
		return
	end
	frame.npcIconsScale = isTarget and scaleConfig.scalingFactor or 1
	self:UpdateNpcIcons(frame)
end

function NotPlater:UpdateNpcIcons(frame)
	if not frame or not frame.npcIcons then
		return
	end
	local config = self.db.profile.icons.npcIcons
	if not config.general.enable then
		frame.npcIcons:Hide()
		return
	end
	local layout = config.layout
	local general = config.general
	local iconToggles = config.icons
	local container = frame.npcIcons
	local iconsToShow = {}
	local scale = frame.npcIconsScale or 1
	local anchorFrame = frame.nameText or frame.healthBar
	container:ClearAllPoints()
	container:SetPoint(self.oppositeAnchors[layout.anchor], anchorFrame, layout.anchor, layout.xOffset * scale, layout.yOffset * scale)
	local strata = frame.healthBar:GetFrameStrata() or frame:GetFrameStrata() or "MEDIUM"
	container:SetFrameStrata(strata)
	local baseLevel = frame.healthBar:GetFrameLevel() or frame:GetFrameLevel()
	container:SetFrameLevel(baseLevel + 1)

	if frame.isSimulatorFrame then
		local classToken = select(2, UnitClass("player"))
		for _, info in ipairs(ICONS) do
			if iconToggles[info.key] then
				if info.trainer then
					tinsert(iconsToShow, {info = info, classToken = classToken})
				elseif not (info.key == "banker" or info.key == "auctioneer") then
					tinsert(iconsToShow, {info = info})
				end
			end
		end
	else
		local unitName = frame.defaultNameText and frame.defaultNameText:GetText()
		local npcData = unitName and NotPlater.NPCData and NotPlater.NPCData[unitName]
		if not npcData or not IsFactionMatch(npcData.faction) then
			container:Hide()
			return
		end
		local flags = npcData.flags or 0
		local enums = NotPlater.NPCEnums
		local flagEnums = enums and enums.Flags
		for _, info in ipairs(ICONS) do
			if iconToggles[info.key] then
				if info.trainer then
					if IsClassTrainer(npcData.trainer) then
						local classToken = GetTrainerClassToken(npcData.trainer)
						if classToken then
							tinsert(iconsToShow, {info = info, classToken = classToken})
						end
					else
						local professionIcon = GetTrainerProfessionIcon(npcData.trainer)
						if professionIcon then
							tinsert(iconsToShow, {info = info, professionIcon = professionIcon})
						end
					end
				elseif flagEnums and info.flag and band(flags, flagEnums[info.flag]) > 0 then
					tinsert(iconsToShow, {info = info})
				end
			end
		end
	end

	if #iconsToShow == 0 then
		container:Hide()
		return
	end

	local perRow = max(1, layout.iconsPerRow or 6)
	local spacing = (general.iconSpacing or 0) * scale
	local rowSpacing = (general.rowSpacing or 0) * scale
	local size = { width = (layout.width or 12) * scale, height = (layout.height or 12) * scale }
	local rows = max(1, ceil(#iconsToShow / perRow))
	local width = perRow * size.width + (perRow - 1) * spacing
	local height = rows * size.height + (rows - 1) * rowSpacing
	self:SetSize(container, width, height)
	container:Show()

	for i = 1, #container.icons do
		container.icons[i]:Hide()
	end

	for index, entry in ipairs(iconsToShow) do
		local icon = container.icons[index]
		if not icon then
			icon = container:CreateTexture(nil, "ARTWORK")
			container.icons[index] = icon
		end
		local info = entry.info
		if info.trainer and entry.classToken then
			local coords = CLASS_ICON_TCOORDS[entry.classToken]
			icon:SetTexture(CLASS_ICON_TEXTURE)
			icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		elseif info.trainer and entry.professionIcon then
			icon:SetTexture(entry.professionIcon)
			icon:SetTexCoord(0, 1, 0, 1)
		else
			icon:SetTexture(info.texture)
			icon:SetTexCoord(0, 1, 0, 1)
		end
		self:SetSize(icon, size.width, size.height)
		icon:SetAlpha(general.opacity or 1)
		PositionIcon(container, icon, index, perRow, #iconsToShow, layout.growDirection, size, spacing, rowSpacing)
		icon:Show()
	end

end
