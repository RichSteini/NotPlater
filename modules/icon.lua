if( not NotPlater ) then return end

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
local ELITE_ICON_TEXTURE = "Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons"
local ELITE_ICON_TCOORDS = {0.75, 1, 0, 1}

local function ResolveClassToken(frame)
	if not frame then
		return nil
	end
	if frame.unitClassToken then
		return frame.unitClassToken
	end
	local nameText = frame.defaultNameText
	if nameText and NotPlater.classTokenCache then
		local unitName = nameText:GetText()
		if unitName and unitName ~= "" then
			local cachedToken = NotPlater.classTokenCache[unitName]
			if cachedToken then
				frame.unitClassToken = cachedToken
				return cachedToken
			end
		end
	end
	if frame.unitClass and NotPlater.GetClassTokenFromColor then
		local classToken = NotPlater:GetClassTokenFromColor(frame.unitClass)
		frame.unitClassToken = classToken
		return classToken
	end
	return nil
end

function NotPlater:ScaleIcon(iconFrame, scalingFactor, config)
    self:SetSize(iconFrame, config.size.width * scalingFactor, config.size.height * scalingFactor)
	local position = config.position
	local anchorFrame = iconFrame and iconFrame.npAnchorFrame
	if position and anchorFrame then
		iconFrame:ClearAllPoints()
		local xOffset = (position.xOffset or 0) * scalingFactor
		local yOffset = (position.yOffset or 0) * scalingFactor
		iconFrame:SetPoint(self.oppositeAnchors[position.anchor], anchorFrame, position.anchor, xOffset, yOffset)
	end
end

function NotPlater:ScaleBossIcon(iconFrame, isTarget)
	local bossIconConfig = self.db.profile.icons.bossIcon
	if bossIconConfig.general.enable == false then
		return
	end
	local scaleConfig = self.db.profile.target.scale
	if scaleConfig.bossIcon then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
        self:ScaleIcon(iconFrame, scalingFactor, bossIconConfig)
    end
end

function NotPlater:ScaleRaidIcon(iconFrame, isTarget)
	local raidIconConfig = self.db.profile.icons.raidIcon
	if raidIconConfig.general.enable == false then
		return
	end
	local scaleConfig = self.db.profile.target.scale
	if scaleConfig.raidIcon then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
        self:ScaleIcon(iconFrame, scalingFactor, raidIconConfig)
    end
end

function NotPlater:ScaleEliteIcon(iconFrame, isTarget)
	if not self.isWrathClient then
		return
	end
	if not iconFrame then
		return
	end
	local eliteIconConfig = self.db.profile.icons.eliteIcon
	if eliteIconConfig.general.enable == false then
		return
	end
	local scaleConfig = self.db.profile.target.scale
	if scaleConfig.eliteIcon then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleIcon(iconFrame, scalingFactor, eliteIconConfig)
	end
end

function NotPlater:ScaleClassIcon(iconFrame, isTarget)
	local classIconConfig = self.db.profile.icons.classIcon
	if classIconConfig.general.enable == false then
		return
	end
	local scaleConfig = self.db.profile.target.scale
	if scaleConfig.classIcon then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleIcon(iconFrame, scalingFactor, classIconConfig)
	end
end

function NotPlater:ConfigureIcon(iconFrame, anchorFrame, config)
    self:ConfigureGeneralisedIcon(iconFrame, anchorFrame, config)
	-- Set border
	if config.border.enable then
		self:ConfigureFullBorder(iconFrame.border, iconFrame, config.border)
		iconFrame.border:Show()
	else
		iconFrame.border:Hide()
	end
	-- Set background
	if config.background.enable then
		iconFrame.background:SetTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, config.background.texture))
		iconFrame.background:SetVertexColor(self:GetColor(config.background.color))
		iconFrame.background:Show()
	else
		iconFrame.background:Hide()
	end
end

function NotPlater:ConstructIcon(parentFrame)
	parentFrame.icon = CreateFrame("Frame", nil, parentFrame)
	parentFrame.icon.texture = parentFrame.icon:CreateTexture(nil, "BORDER")
	parentFrame.icon.texture:SetAllPoints()
	parentFrame.icon.border = self:CreateFullBorder(parentFrame.icon)
    parentFrame.icon.background = parentFrame.icon:CreateTexture(nil, "BACKGROUND")
	parentFrame.icon.background:SetAllPoints(parentFrame.icon)
end

function NotPlater:ConstructClassIcon(frame)
	if not frame or frame.classIcon then
		return
	end
	frame.classIcon = frame:CreateTexture(nil, "ARTWORK")
	frame.classIcon:SetTexture(CLASS_ICON_TEXTURE)
	frame.classIcon:SetTexCoord(0, 0, 0, 0)
	frame.classIcon:SetAlpha(0)
end

function NotPlater:UpdateClassIcon(frame)
	if not frame or not frame.classIcon then
		return
	end
	local classIconConfig = self.db.profile.icons.classIcon
	local enabled = classIconConfig.general.enable
	if enabled == nil then
		enabled = true
	end
	if not enabled then
		frame.classIcon:SetAlpha(0)
		return
	end
	local classToken = ResolveClassToken(frame)
	local coords = classToken and CLASS_ICON_TCOORDS[classToken]
	if not coords then
		frame.classIcon:SetAlpha(0)
		return
	end
	frame.classIcon:SetTexture(CLASS_ICON_TEXTURE)
	frame.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	frame.classIcon:SetAlpha(classIconConfig.general.opacity or 1)
end

function NotPlater:UpdateEliteIcon(frame)
	if not self.isWrathClient then
		return
	end
	if not frame or not frame.eliteIcon then
		return
	end
	local eliteIconConfig = self.db.profile.icons.eliteIcon
	local enabled = eliteIconConfig.general.enable
	if not enabled then
		frame.eliteIcon:SetAlpha(0)
		return
	end
	local nameText = frame.defaultNameText
	if not nameText then
		frame.eliteIcon:SetAlpha(0)
		return
	end
	local unitName = nameText:GetText()
	if not unitName or unitName == "" then
		frame.eliteIcon:SetAlpha(0)
		return
	end
	local npcData = NotPlater.NPCData and NotPlater.NPCData[unitName]
	local rank = npcData and npcData.rank
	local rankEnums = NotPlater.NPCEnums and NotPlater.NPCEnums.Rank
	if not rank or not rankEnums then
		frame.eliteIcon:SetAlpha(0)
		return
	end

	local opacity = eliteIconConfig.general.opacity or 1
	if rank == rankEnums.Rare or rank == rankEnums.RareElite then
		frame.eliteIcon:SetTexture(ELITE_ICON_TEXTURE)
		frame.eliteIcon:SetTexCoord(ELITE_ICON_TCOORDS[1], ELITE_ICON_TCOORDS[2], ELITE_ICON_TCOORDS[3], ELITE_ICON_TCOORDS[4])
		frame.eliteIcon:SetVertexColor(1, 1, 1, 1)
		frame.eliteIcon:SetDesaturated(true)
		frame.eliteIcon:SetAlpha(opacity)
		frame.eliteIcon:Show()
	elseif rank == rankEnums.Elite or rank == rankEnums.WorldBoss then
		frame.eliteIcon:SetTexture(ELITE_ICON_TEXTURE)
		frame.eliteIcon:SetTexCoord(ELITE_ICON_TCOORDS[1], ELITE_ICON_TCOORDS[2], ELITE_ICON_TCOORDS[3], ELITE_ICON_TCOORDS[4])
		frame.eliteIcon:SetVertexColor(1, 0.8, 0, 1)
		frame.eliteIcon:SetDesaturated(false)
		frame.eliteIcon:SetAlpha(opacity)
	else
		frame.eliteIcon:SetAlpha(0)
	end
end

function NotPlater:ConfigureClassIcon(frame)
	if not frame or not frame.classIcon then
		return
	end
	local classIconConfig = self.db.profile.icons.classIcon
	self:ConfigureGeneralisedIcon(frame.classIcon, frame.healthBar, classIconConfig)
	self:UpdateClassIcon(frame)
end

function NotPlater:ConfigureEliteIcon(frame)
	if not self.isWrathClient then
		return
	end
	if not frame or not frame.eliteIcon then
		return
	end
	local eliteIconConfig = self.db.profile.icons.eliteIcon
	self:ConfigureGeneralisedIcon(frame.eliteIcon, frame.healthBar, eliteIconConfig)
	self:UpdateEliteIcon(frame)
end
