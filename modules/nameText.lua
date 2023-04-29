if( not NotPlater ) then return end

function NotPlater:ConfigureNameText(nameText, anchorFrame)
	local nameTextConfig = self.db.profile.nameText
	-- Set name text
	nameText:ClearAllPoints()
	nameText:SetPoint(nameTextConfig.anchor, anchorFrame, nameTextConfig.xOffset, nameTextConfig.yOffset)
	self:SetupFontString(nameText, nameTextConfig, false)
	if not nameTextConfig.fontEnabled then
		nameText:Hide()
	else
		nameText:Show()
	end
end