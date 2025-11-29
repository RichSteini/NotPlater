if( not NotPlater ) then return end

function NotPlater:ScaleNameText(nameText, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.nameText then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleGeneralisedText(nameText, scalingFactor, self.db.profile.nameText)
	end
end

function NotPlater:ConfigureNameText(nameText, anchorFrame)
	self:ConfigureGeneralisedText(nameText, anchorFrame, self.db.profile.nameText)
end

function NotPlater:NameTextOnShow(nameText)
	local config = self.db.profile.nameText
	if config.general.useCustomColor and config.general.color then
		nameText:SetTextColor(self:GetColor(config.general.color))
	end
	if config.general.maxLetters then
		self:SetMaxLetterText(nameText, nameText:GetText(), config)
	end
end
