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