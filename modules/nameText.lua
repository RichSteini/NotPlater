if( not NotPlater ) then return end

function NotPlater:ScaleNameText(nameText, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.nameText then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleGeneralisedText(nameText, scalingFactor, self.db.profile.nameText)
	end
end

function NotPlater:ConfigureNameText(nameText, anchorFrame)
	local config = self.db.profile.nameText
	self:ConfigureGeneralisedText(nameText, anchorFrame, config)

	if not nameText or not config or not config.general then
		return
	end

	-- Use the original plate text so max-letter changes are always applied to the full name.
	local baseText = nameText.npOriginalText or nameText:GetText() or ""
	local parent = nameText:GetParent()
	if parent and parent.defaultNameText and parent.defaultNameText.GetText then
		baseText = parent.defaultNameText:GetText() or baseText
	end

	if config.general.maxLetters then
		self:SetMaxLetterText(nameText, baseText, config)
	else
		nameText:SetText(baseText)
	end
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
