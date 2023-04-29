if( not NotPlater ) then return end

function NotPlater:LevelTextOnShow(levelText, anchorFrame)
	local levelTextConfig = self.db.profile.levelText
	levelText:ClearAllPoints()
	levelText:SetPoint(levelTextConfig.anchor, anchorFrame, levelTextConfig.xOffset, levelTextConfig.yOffset)
	levelText:SetAlpha(levelTextConfig.fontOpacity)
end

function NotPlater:ConfigureLevelText(levelText, anchorFrame)
	local levelTextConfig = self.db.profile.levelText
	-- Set level text
	self:SetupFontString(levelText, levelTextConfig, false)
	self:LevelTextOnShow(levelText, anchorFrame)
end