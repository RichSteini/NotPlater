if( not NotPlater ) then return end

function NotPlater:ConfigureIcon(iconFrame, anchorFrame, config)
    iconFrame:ClearAllPoints()
    self:SetSize(iconFrame, config.xSize, config.ySize)
    iconFrame:SetPoint(config.anchor, anchorFrame, config.xOffset, config.yOffset)
    iconFrame:SetAlpha(config.opacity)
end

