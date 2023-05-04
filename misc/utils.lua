if( not NotPlater ) then return end

local L = NotPlaterLocals
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

function NotPlater:GetColor(config)
	return config.r, config.g, config.b, config.a
end

function NotPlater:SetupFontString(text, type, color)
	local config = type

	if text then
		text:SetFont(self.SML:Fetch(self.SML.MediaType.FONT, config.fontName), config.fontSize, config.fontBorder)

		-- Set color
		if color then
			text:SetTextColor(config.fontColor.r, config.fontColor.g, config.fontColor.b, config.fontColor.a)
		end

		-- Set shadow
		if( config.fontShadowEnabled ) then
			if( not text.npOriginalShadow ) then
				local x, y = text:GetShadowOffset()
				local r, g, b, a = text:GetShadowColor()
				
				text.npOriginalShadow = { r = r, g = g, b = b, a = a, y = y, x = x }
			end
			
			text:SetShadowColor(config.fontShadowColor.r, config.fontShadowColor.g, config.fontShadowColor.b, config.fontShadowColor.a)
			text:SetShadowOffset(config.fontShadowXOffset, config.fontShadowYOffset)
		-- Restore original
		elseif( text.npOriginalShadow ) then
			text:SetShadowColor(text.npOriginalShadow.r, text.npOriginalShadow.g, text.npOriginalShadow.b, text.npOriginalShadow.a)
			text:SetShadowOffset(text.npOriginalShadow.x, text.npOriginalShadow.y)
			text.npOriginalShadow = nil
		end
	end
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