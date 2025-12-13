if( not NotPlater ) then return end

function NotPlater:ScaleNameText(nameText, isTarget)
	local scaleConfig = self.db.profile.target.scale
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

	local baseText = nameText.npOriginalText or nameText:GetText() or ""
	local parent = nameText:GetParent()
	if parent and parent.defaultNameText and parent.defaultNameText.GetText then
		baseText = parent.defaultNameText:GetText() or baseText
	end

	NotPlater:NameTextOnShow(anchorFrame:GetParent())
end

function NotPlater:NameTextOnShow(frame)
	local config = self.db.profile.nameText
	frame.nameText:SetTextColor(self:GetColor(config.general.color))
	if config.general.maxLetters then
		NotPlater:SetMaxLetterText(frame.nameText, frame.defaultNameText:GetText(), config)
	else
		frame.nameText:SetText(frame.defaultNameText:GetText())
	end
	frame.defaultNameText:SetAlpha(0)
	frame.defaultNameText:Hide()
end
