if( not NotPlater ) then return end

local L = NotPlaterLocals
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local unpack = unpack
local slen = string.len
local ssub = string.sub
local tinsert = table.insert

function NotPlater:GetColor(config)
	return unpack(config)
end

function NotPlater:GetAlpha(config)
	return config[4]
end

function NotPlater:SetupFontString(text, config)
	if not text then return end

	text:SetFont(self.SML:Fetch(self.SML.MediaType.FONT, config.general.name), config.general.size, config.general.border)

	-- Set color
	if config.general.color then
		text:SetTextColor(self:GetColor(config.general.color))
	end

	-- Set shadow
	if config.shadow.enable then
		if( not text.npOriginalShadow ) then
			local x, y = text:GetShadowOffset()
			local r, g, b, a = text:GetShadowColor()
			
			text.npOriginalShadow = {r = r, g = g, b = b, a = a, y = y, x = x}
		end
		
		text:SetShadowColor(self:GetColor(config.shadow.color))
		text:SetShadowOffset(config.shadow.xOffset, config.shadow.yOffset)
	elseif text.npOriginalShadow then -- Restore original shadow
		text:SetShadowColor(text.npOriginalShadow.r, text.npOriginalShadow.g, text.npOriginalShadow.b, text.npOriginalShadow.a)
		text:SetShadowOffset(text.npOriginalShadow.x, text.npOriginalShadow.y)
		text.npOriginalShadow = nil
	end
end

function NotPlater:SetMaxLetterText(textObject, text, config)
	local configMaxLength = config.general.maxLetters
	if text and slen(text) > configMaxLength then
		textObject:SetText(ssub(text, 1, configMaxLength) .. "...")
	else
		textObject:SetText(text)
	end
end

function NotPlater:ScaleGeneralisedText(text, scalingFactor, config)
	text:SetFont(self.SML:Fetch(self.SML.MediaType.FONT, config.general.name), config.general.size * scalingFactor, config.general.border)
end

function NotPlater:ConfigureGeneralisedText(text, anchorFrame, config)
    text:ClearAllPoints()
	text:SetPoint(config.position.anchor, anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
	self:SetupFontString(text, config)
	if config.general.enable then
		text:Show()
	else
		text:Hide()
	end
end

function NotPlater:ScaleGeneralisedStatusBar(bar, scalingFactor, config)
	if bar.scaleAnim:IsPlaying() then
		bar.scaleAnim:Stop()
	end
	bar.scaleAnim.width:SetChange(config.size.width * scalingFactor)
	bar.scaleAnim.height:SetChange(config.size.height * scalingFactor)
	bar.scaleAnim:Play()
end

function NotPlater:ConfigureGeneralisedPositionedStatusBar(bar, anchorFrame, config)
	bar:ClearAllPoints()
	self:SetSize(bar, config.size.width, config.size.height)
	bar:SetPoint(self.oppositeAnchors[config.position.anchor], anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
	self:ConfigureGeneralisedStatusBar(bar, config)
end

function NotPlater:ConfigureFullBorder(border, parent, config)
	border.left:ClearAllPoints()
	border.left:SetTexture(self:GetColor(config.color))
	border.left:SetWidth(config.thickness)
	border.left:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, config.thickness)
	border.left:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", 0, -config.thickness)

	border.right:ClearAllPoints()
	border.right:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, config.thickness)
	border.right:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 0, -config.thickness)
	border.right:SetTexture(self:GetColor(config.color))
	border.right:SetWidth(config.thickness)

	border.bottom:ClearAllPoints()
	border.bottom:SetTexture(self:GetColor(config.color))
	border.bottom:SetHeight(config.thickness)
	border.bottom:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, 0)
	border.bottom:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, 0)

	border.top:ClearAllPoints()
	border.top:SetTexture(self:GetColor(config.color))
	border.top:SetHeight(config.thickness)
	border.top:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 0)
	border.top:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 0, 0)
end

function NotPlater:CreateFullBorder(parent)
	local border = {}

	local left = parent:CreateTexture("$parentLeft", "BACKGROUND")
	border.left = left

	local right = parent:CreateTexture("$parentRight", "BACKGROUND")
	border.right = right

	local bottom = parent:CreateTexture("$parentBottom", "BACKGROUND")
	border.bottom = bottom

	local top = parent:CreateTexture("$parentTop", "BACKGROUND")
	border.top = top

	border.Show = function()
		border.left:Show()
		border.right:Show()
		border.bottom:Show()
		border.top:Show()
	end

	border.Hide = function()
		border.left:Hide()
		border.right:Hide()
		border.bottom:Hide()
		border.top:Hide()
	end

	return border
end

function NotPlater:ConfigureGeneralisedIcon(iconFrame, anchorFrame, config)
    iconFrame:ClearAllPoints()
    self:SetSize(iconFrame, config.size.width, config.size.height)
    iconFrame:SetPoint(self.oppositeAnchors[config.position.anchor], anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
    iconFrame:SetAlpha(config.general.opacity)
end

function NotPlater:ConfigureGeneralisedStatusBar(bar, config)
	-- Set textures for health- and castbar
	bar:SetStatusBarTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, config.general.texture))

	-- Set background
	if config.background.enable then
		bar.background:SetTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, config.background.texture))
		bar.background:SetVertexColor(self:GetColor(config.background.color))
		bar.background:Show()
	else
		bar.background:Hide()
	end

	-- Set border
	if config.border.enable then
		self:ConfigureFullBorder(bar.border, bar, config.border)
		bar.border:Show()
	else
		bar.border:Hide()
	end

end

function NotPlater:ConstructGeneralisedStatusBar(bar)
    -- Background
    bar.background = bar:CreateTexture(nil, "BORDER")
	bar.background:SetAllPoints(bar)

	-- Border
	bar.border = self:CreateFullBorder(bar)

	bar.scaleAnim = CreateAnimationGroup(bar)
	bar.scaleAnim.width = bar.scaleAnim:CreateAnimation("Width")
	bar.scaleAnim.width:SetDuration(0.15)
	bar.scaleAnim.height = bar.scaleAnim:CreateAnimation("Height")
	bar.scaleAnim.height:SetDuration(0.15)
end

function NotPlater:SetSize(frame, width, height)
	frame:SetWidth(width)
	frame:SetHeight(height)
end

function NotPlater:PrintHelp()
    self:Print(L["Usage:"])
    self:Print(L["/np help - Show this message"])
    self:Print(L["/np config - Toggle the config window"])
    self:Print(L["/np simulator - Toggle the simulator frame"])
    self:Print(L["/np minimap - Toggle the minimap icon"])
end

function NotPlater:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99NotPlater|r: " .. msg)
end