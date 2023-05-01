if( not NotPlater ) then return end

local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local FAILED = FAILED
local INTERRUPTED = INTERRUPTED

function NotPlater:CastBarOnUpdate(elapsed)
    local castBarConfig = NotPlater.db.profile.castBar
	if not NotPlater:IsTarget(self:GetParent()) then
		self:Hide()
	elseif self.casting then
		self.value = self.value + elapsed
		if self.value >= self.maxValue then
			self:SetValue(self.maxValue)
			self:Hide()
			self.casting = nil
			return
		end
		self:SetValue(self.value)

        if castBarConfig.castTimeText.type == "crtmax" then
            self.npCastTimeText:SetFormattedText("%.1f / %.1f", self.value, self.maxValue)
        elseif castBarConfig.castTimeText.type == "crt" then
            self.npCastTimeText:SetFormattedText("%.1f", self.value)
        elseif castBarConfig.castTimeText.type == "percent" then
            self.npCastTimeText:SetFormattedText("%d%%", self.value / self.maxValue * 100)
        elseif castBarConfig.castTimeText.type == "timeleft" then
            self.npCastTimeText:SetFormattedText("%.1f", self.maxValue - self.value)
        else
            self.npCastTimeText:SetText("")
        end
	elseif self.channeling then
		self.value = self.value - elapsed
		if self.value <= 0 then
			self:Hide()
			self.channeling = nil
			return
		end
		self:SetValue(self.value)

        if castBarConfig.castTimeText.type == "crtmax" then
            self.npCastTimeText:SetFormattedText("%.1f / %.1f", self.value, self.maxValue)
        elseif castBarConfig.castTimeText.type == "crt" then
            self.npCastTimeText:SetFormattedText("%.1f", self.value)
        elseif castBarConfig.castTimeText.type == "percent" then
            self.npCastTimeText:SetFormattedText("%d%%", self.value / self.maxValue * 100)
        elseif castBarConfig.castTimeText.type == "timeleft" then
            self.npCastTimeText:SetFormattedText("%.1f", self.value - self.maxValue)
        else
            self.npCastTimeText:SetText("")
        end
	else
		self:Hide()
	end
	self.lastUpdate = GetTime()
end

function NotPlater:CastBarOnCast(frame, event, unit)
	local castBarConfig = self.db.profile.castBar
	if not castBarConfig.enabled then return end

	frame.npCastBar.lastUpdate = GetTime()
	if unit then
		if not event then
			if UnitChannelInfo(unit) then
				event = "UNIT_SPELLCAST_CHANNEL_START"
			elseif UnitCastingInfo(unit) then
				event = "UNIT_SPELLCAST_START"
			end
		end
	elseif frame.npCastBar:IsShown() then
		frame.npCastBar:Hide()
	end

	if event == "UNIT_SPELLCAST_START" then
		local name, _, _, texture, startTime, endTime = UnitCastingInfo(unit)
		if not name then
			frame.npCastBar:Hide()
			return
		end

		frame.npCastBar.npCastNameText:SetText(name)
		frame.npCastBar.value = (GetTime() - (startTime / 1000))
		frame.npCastBar.maxValue = (endTime - startTime) / 1000
		frame.npCastBar:SetMinMaxValues(0, frame.npCastBar.maxValue)
		frame.npCastBar:SetValue(frame.npCastBar.value)

		if frame.npCastBar.npCastIcon then
			frame.npCastBar.npCastIcon.texture:SetTexture(texture)
		end

		frame.npCastBar.casting = true
		frame.npCastBar.channeling = nil

		frame.npCastBar:Show()
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not frame.npCastBar:IsVisible() then
			frame.npCastBar:Hide()
		end
		if (frame.npCastBar.casting and event == "UNIT_SPELLCAST_STOP") or (frame.npCastBar.channeling and event == "UNIT_SPELLCAST_CHANNEL_STOP") then

			frame.npCastBar:SetValue(frame.npCastBar.maxValue)
			if event == "UNIT_SPELLCAST_STOP" then
				frame.npCastBar.casting = nil
			else
				frame.npCastBar.channeling = nil
			end

			frame.npCastBar:Hide()
		end
	elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if frame.npCastBar:IsShown() then
			frame.npCastBar:SetValue(frame.npCastBar.maxValue)

			if event == "UNIT_SPELLCAST_FAILED" then
				frame.npCastBar.Name:SetText(FAILED)
			else
				frame.npCastBar.Name:SetText(INTERRUPTED)
			end
			frame.npCastBar.casting = nil
			frame.npCastBar.channeling = nil
		end
	elseif event == "UNIT_SPELLCAST_DELAYED" then
		if frame:IsShown() then
			local name, _, _, _, startTime, endTime = UnitCastingInfo(unit)
			if not name then
				-- if there is no name, there is no bar
				frame.npCastBar:Hide()
				return
			end

			frame.npCastBar.Name:SetText(name)
			frame.npCastBar.value = (GetTime() - (startTime / 1000))
			frame.npCastBar.maxValue = (endTime - startTime) / 1000
			frame.npCastBar:SetMinMaxValues(0, frame.npCastBar.maxValue)

			if not frame.npCastBar.casting then
				frame.npCastBar.casting = true
				frame.npCastBar.channeling = nil
			end
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local name, _, _, texture, startTime, endTime = UnitChannelInfo(unit)
		if not name then
			frame.npCastBar:Hide()
			return
		end

		frame.npCastBar.npCastNameText:SetText(name)
		frame.npCastBar.value = (endTime / 1000) - GetTime()
		frame.npCastBar.maxValue = (endTime - startTime) / 1000
		frame.npCastBar:SetMinMaxValues(0, frame.npCastBar.maxValue)
		frame.npCastBar:SetValue(frame.npCastBar.value)

		if frame.npCastBar.npCastIcon then
			frame.npCastBar.npCastIcon.texture:SetTexture(texture)
		end

		frame.npCastBar.casting = nil
		frame.npCastBar.channeling = true

		frame.npCastBar:Show()
	elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		if frame.npCastBar:IsShown() then
			local name, _, _, _, startTime, endTime = UnitChannelInfo(unit)
			if not name then
				frame.npCastBar:Hide()
				return
			end

			frame.npCastBar.npCastNameText:SetText(name)
			frame.npCastBar.value = ((endTime / 1000) - GetTime())
			frame.npCastBar.maxValue = (endTime - startTime) / 1000
			frame.npCastBar:SetMinMaxValues(0, frame.npCastBar.maxValue)
			frame.npCastBar:SetValue(frame.npCastBar.value)
		end
	end
end

function NotPlater:CastCheck(frame)
	self:CastBarOnCast(frame, "UNIT_SPELLCAST_START", "target")
	if not frame.npCastBar.casting then
		self:CastBarOnCast(frame, "UNIT_SPELLCAST_CHANNEL_START", "target")
	end
end

function NotPlater:CastBarOnShow(frame)
    local castBarConfig = self.db.profile.castBar
	local health, cast = frame:GetChildren()
	local castFrame = frame.npCastBar
	castFrame:ClearAllPoints()
	self:SetSize(castFrame, castBarConfig.position.xSize, castBarConfig.position.ySize)
	castFrame:SetPoint(castBarConfig.position.anchor, health, castBarConfig.position.xOffset, castBarConfig.position.yOffset)
	-- Tried to make it reappear, but this does not really work since you can't track whether something was interrupted
	if castFrame.casting or castFrame.channeling then
		if castFrame.lastUpdate then
			castFrame.helper = self.CastBarOnUpdate
			castFrame:helper(GetTime() - castFrame.lastUpdate)
		end
		castFrame:Show()
	end
end

function NotPlater:ConfigureCastBar(frame)
    local castBarConfig = self.db.profile.castBar
	local castFrame = frame.npCastBar

	-- Set point for castbar
	self:CastBarOnShow(frame)
	castFrame:SetFrameLevel(frame:GetFrameLevel() + 1)

    -- Set statusbar texture
    castFrame:SetStatusBarTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, castBarConfig.texture))
	castFrame:SetStatusBarColor(self:GetColor(castBarConfig.barColor))

	-- Set castbar icon
	castFrame.npCastIcon:ClearAllPoints()
	self:SetSize(castFrame.npCastIcon, castBarConfig.castSpellIcon.xSize, castBarConfig.castSpellIcon.ySize)
	castFrame.npCastIcon:SetPoint(castBarConfig.castSpellIcon.anchor, castFrame, castBarConfig.castSpellIcon.xOffset, castBarConfig.castSpellIcon.yOffset)
	castFrame.npCastIcon:SetAlpha(castBarConfig.castSpellIcon.opacity)

    -- Set background color
	castFrame.npCastBackground:ClearAllPoints()
	castFrame.npCastBackground:SetAllPoints(castFrame)
	castFrame.npCastBackground:SetTexture(self:GetColor(castBarConfig.backgroundColor))

    -- Set cast text
	castFrame.npCastTimeText:ClearAllPoints()
	castFrame.npCastTimeText:SetPoint(castBarConfig.castTimeText.anchor, castFrame, castBarConfig.castTimeText.xOffset, castBarConfig.castTimeText.yOffset)
	castFrame.npCastNameText:ClearAllPoints()
	castFrame.npCastNameText:SetPoint(castBarConfig.castNameText.anchor, castFrame, castBarConfig.castNameText.xOffset, castBarConfig.castNameText.yOffset)
	self:SetupFontString(castFrame.npCastTimeText, castBarConfig.castTimeText, true)
	self:SetupFontString(castFrame.npCastNameText, castBarConfig.castNameText, true)
end

function NotPlater:ConstructCastBar(frame)
    local castBarConfig = self.db.profile.castBar

	local castFrame = CreateFrame("StatusBar", "$parentCastBar", frame)
	castFrame:SetScript("OnUpdate", NotPlater.CastBarOnUpdate)

    -- Create the icon
	castFrame.npCastIcon = CreateFrame("Frame", nil, castFrame)
	castFrame.npCastIcon.texture = castFrame.npCastIcon:CreateTexture(nil, "BORDER")
	castFrame.npCastIcon.texture:SetAllPoints()

    -- Create cast time text and set font
    castFrame.npCastTimeText = castFrame:CreateFontString(nil, "ARTWORK")

    -- Create cast name text and set font
    castFrame.npCastNameText = castFrame:CreateFontString(nil, "ARTWORK")

    -- Create and set background
	castFrame.npCastBackground = castFrame:CreateTexture(nil, 'BORDER')

	frame.npCastBar = castFrame
	castFrame:Hide()
end

function NotPlater:RegisterCastBarEvents(frame)
	frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	frame:RegisterEvent("UNIT_SPELLCAST_START")
	frame:RegisterEvent("UNIT_SPELLCAST_STOP")
	frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
end

function NotPlater:UnregisterCastBarEvents(frame)
	frame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	frame:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
	frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	frame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	frame:UnregisterEvent("UNIT_SPELLCAST_START")
	frame:UnregisterEvent("UNIT_SPELLCAST_STOP")
	frame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
end