if( not NotPlater ) then return end

function NotPlater:ScaleIcon(iconFrame, scalingFactor, config)
    self:SetSize(iconFrame, config.size.width * scalingFactor, config.size.height * scalingFactor)
end

function NotPlater:ScaleBossIcon(iconFrame, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.bossIcon then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
        self:ScaleIcon(iconFrame, scalingFactor, self.db.profile.bossIcon)
    end
end

function NotPlater:ScaleRaidIcon(iconFrame, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.raidIcon then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
        self:ScaleIcon(iconFrame, scalingFactor, self.db.profile.raidIcon)
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