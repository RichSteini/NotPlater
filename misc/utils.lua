if( not NotPlater ) then return end

local L = NotPlaterLocals
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local unpack = unpack
local slen = string.len
local ssub = string.sub
local tinsert = table.insert

function NotPlater:GetClassColorFromRGB(r, g, b)
	local tolerance = 0.1
	for _, color in pairs(RAID_CLASS_COLORS) do
		if math.abs(color.r - r) <= tolerance and math.abs(color.g - g) <= tolerance and math.abs(color.b - b) <= tolerance then
			return color
		end
	end
	return nil
end

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
	local colorConfig = config.general.color
	local useConfiguredColor = colorConfig ~= nil
	if config.general.useCustomColor ~= nil then
		useConfiguredColor = config.general.useCustomColor and colorConfig ~= nil
	end
	if useConfiguredColor and colorConfig then
		if not text.npOriginalColor then
			local r, g, b, a = text:GetTextColor()
			text.npOriginalColor = {r = r, g = g, b = b, a = a}
		end
		text:SetTextColor(self:GetColor(colorConfig))
	elseif text.npOriginalColor then
		text:SetTextColor(text.npOriginalColor.r, text.npOriginalColor.g, text.npOriginalColor.b, text.npOriginalColor.a)
		text.npOriginalColor = nil
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

function NotPlater:ScaleGeneralisedText(text, scalingFactor, config, anchorFrame)
	if not text or not config then
		return
	end

	text:SetFont(self.SML:Fetch(self.SML.MediaType.FONT, config.general.name), config.general.size * scalingFactor, config.general.border)

	local position = config.position
	local targetAnchor = anchorFrame or text.npAnchorFrame
	if position and targetAnchor then
		text:ClearAllPoints()
		local xOffset = (position.xOffset or 0) * scalingFactor
		local yOffset = (position.yOffset or 0) * scalingFactor
		text:SetPoint(position.anchor, targetAnchor, position.anchor, xOffset, yOffset)
	end
end

function NotPlater:ConfigureGeneralisedText(text, anchorFrame, config)
    text:ClearAllPoints()
	text:SetPoint(config.position.anchor, anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
	text.npAnchorFrame = anchorFrame
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

	local position = config.position
	local anchorFrame = bar.npAnchorFrame
	if position and anchorFrame then
		bar:ClearAllPoints()
		local xOffset = (position.xOffset or 0) * scalingFactor
		local yOffset = (position.yOffset or 0) * scalingFactor
		bar:SetPoint(self.oppositeAnchors[position.anchor], anchorFrame, position.anchor, xOffset, yOffset)
	end
end

function NotPlater:ConfigureGeneralisedPositionedStatusBar(bar, anchorFrame, config)
	bar:ClearAllPoints()
	self:SetSize(bar, config.size.width, config.size.height)
	bar:SetPoint(self.oppositeAnchors[config.position.anchor], anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
	bar.npAnchorFrame = anchorFrame
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
	if not iconFrame or not anchorFrame or not config then
		return
	end

    iconFrame:ClearAllPoints()
    self:SetSize(iconFrame, config.size.width, config.size.height)
    iconFrame:SetPoint(self.oppositeAnchors[config.position.anchor], anchorFrame, config.position.anchor, config.position.xOffset, config.position.yOffset)
	iconFrame.npAnchorFrame = anchorFrame
	local enabled = config.general.enable
	if enabled == nil then
		enabled = true
	end
    iconFrame:SetAlpha(enabled and config.general.opacity or 0)
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
    self:Print(L["/np whatsnew - Show the latest release notes"])
    self:Print(L["/np simulator - Toggle the simulator frame"])
    self:Print(L["/np minimap - Toggle the minimap icon"])
    self:Print(L["/np share - Send a profile link to your party or raid chat"])
end

function NotPlater:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99NotPlater|r: " .. msg)
end
