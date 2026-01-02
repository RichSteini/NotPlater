if( not NotPlater ) then return end

function NotPlater:GetActiveNameTextConfig(frame)
	if frame and frame.filterNameTextConfig then
		return frame.filterNameTextConfig
	end
	return self.db.profile.nameText
end

function NotPlater:ScaleNameText(nameText, isTarget)
	local scaleConfig = self.db.profile.target.scale
	if scaleConfig.nameText then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		local frame = nameText and nameText:GetParent()
		local config = self:GetActiveNameTextConfig(frame)
		self:ScaleGeneralisedText(nameText, scalingFactor, config)
	end
end

function NotPlater:ConfigureNameTextWithConfig(nameText, anchorFrame, config)
	if not nameText or not config then
		return
	end
	self:ConfigureGeneralisedText(nameText, anchorFrame, config)
	self:NameTextOnShow(anchorFrame and anchorFrame:GetParent() or nameText:GetParent(), config)
end

function NotPlater:ConfigureNameText(nameText, anchorFrame)
	self:ConfigureNameTextWithConfig(nameText, anchorFrame, self.db.profile.nameText)
end

function NotPlater:NameTextOnShow(frame, configOverride)
	if not frame or not frame.nameText or not frame.defaultNameText then
		return
	end
	if frame.filterHideNameText then
		frame.nameText:Hide()
		frame.defaultNameText:Hide()
		return
	end
	local config = configOverride or self:GetActiveNameTextConfig(frame)
	if not config or not config.general then
		return
	end
	if not config.general.enable then
		frame.nameText:Hide()
		frame.defaultNameText:Hide()
		return
	end
	frame.nameText:SetTextColor(self:GetColor(config.general.color))
	if config.general.maxLetters then
		NotPlater:SetMaxLetterText(frame.nameText, frame.defaultNameText:GetText(), config)
	else
		frame.nameText:SetText(frame.defaultNameText:GetText())
	end
	frame.defaultNameText:SetAlpha(0)
	frame.defaultNameText:Hide()
end
