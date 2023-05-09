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
    iconFrame:ClearAllPoints()
    self:SetSize(iconFrame, config.size.width, config.size.height)
    iconFrame:SetPoint(self.oppositeAnchors[config.position.anchor], anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
    iconFrame:SetAlpha(config.general.opacity)
end

