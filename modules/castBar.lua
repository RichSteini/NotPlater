if( not NotPlater ) then return end

local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local FAILED = FAILED
local INTERRUPTED = INTERRUPTED
local slen = string.len
local ssub = string.sub

function NotPlater:SetCastBarNameText(frame, text)
	local configMaxLength = NotPlater.db.profile.castBar.spellNameText.general.maxLetters
	if text and slen(text) > configMaxLength then
		frame.castBar.spellNameText:SetText(ssub(text, 1, configMaxLength) .. "...")
	else
		frame.castBar.spellNameText:SetText(text)
	end
end

function NotPlater:CastBarOnUpdate(elapsed)
    local castBarConfig = NotPlater.db.profile.castBar
	if not NotPlater:IsTarget(self:GetParent()) then
		self.casting = nil
		self.channeling = nil
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

        if castBarConfig.spellTimeText.general.displayType == "crtmax" then
            self.spellTimeText:SetFormattedText("%.1f / %.1f", self.value, self.maxValue)
        elseif castBarConfig.spellTimeText.general.displayType == "crt" then
            self.spellTimeText:SetFormattedText("%.1f", self.value)
        elseif castBarConfig.spellTimeText.general.displayType == "percent" then
            self.spellTimeText:SetFormattedText("%d%%", self.value / self.maxValue * 100)
        elseif castBarConfig.spellTimeText.general.displayType == "timeleft" then
            self.spellTimeText:SetFormattedText("%.1f", self.maxValue - self.value)
        else
            self.spellTimeText:SetText("")
        end
	elseif self.channeling then
		self.value = self.value - elapsed
		if self.value <= 0 then
			self:Hide()
			self.channeling = nil
			return
		end
		self:SetValue(self.value)

        if castBarConfig.spellTimeText.general.displayType == "crtmax" then
            self.spellTimeText:SetFormattedText("%.1f / %.1f", self.value, self.maxValue)
        elseif castBarConfig.spellTimeText.general.displayType == "crt" then
            self.spellTimeText:SetFormattedText("%.1f", self.value)
        elseif castBarConfig.spellTimeText.general.displayType == "percent" then
            self.spellTimeText:SetFormattedText("%d%%", self.value / self.maxValue * 100)
        elseif castBarConfig.spellTimeText.general.displayType == "timeleft" then
            self.spellTimeText:SetFormattedText("%.1f", self.value - self.maxValue)
        else
            self.spellTimeText:SetText("")
        end
	else
		self:Hide()
	end
	self.lastUpdate = GetTime()
end

function NotPlater:CastBarOnCast(frame, event, unit)
	local castBarConfig = self.db.profile.castBar
	if not castBarConfig.statusBar.general.enable then return end

	frame.castBar.lastUpdate = GetTime()
	if unit then
		if not event then
			if UnitChannelInfo(unit) then
				event = "UNIT_SPELLCAST_CHANNEL_START"
			elseif UnitCastingInfo(unit) then
				event = "UNIT_SPELLCAST_START"
			end
		end
	elseif frame.castBar:IsShown() then
		frame.castBar:Hide()
	end

	if event == "UNIT_SPELLCAST_START" then
		local name, _, _, texture, startTime, endTime = UnitCastingInfo(unit)
		if not name then
			frame.castBar:Hide()
			return
		end

		NotPlater:SetCastBarNameText(frame, name)
		frame.castBar.value = (GetTime() - (startTime / 1000))
		frame.castBar.maxValue = (endTime - startTime) / 1000
		frame.castBar:SetMinMaxValues(0, frame.castBar.maxValue)
		frame.castBar:SetValue(frame.castBar.value)

		if frame.castBar.icon then
			frame.castBar.icon.texture:SetTexture(texture)
		end

		frame.castBar.casting = true
		frame.castBar.channeling = nil

		frame.castBar:Show()
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not frame.castBar:IsVisible() then
			frame.castBar:Hide()
		end
		if (frame.castBar.casting and event == "UNIT_SPELLCAST_STOP") or (frame.castBar.channeling and event == "UNIT_SPELLCAST_CHANNEL_STOP") then

			frame.castBar:SetValue(frame.castBar.maxValue)
			if event == "UNIT_SPELLCAST_STOP" then
				frame.castBar.casting = nil
			else
				frame.castBar.channeling = nil
			end

			frame.castBar:Hide()
		end
	elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if frame.castBar:IsShown() then
			frame.castBar:SetValue(frame.castBar.maxValue)

			if event == "UNIT_SPELLCAST_FAILED" then
				NotPlater:SetCastBarNameText(frame, FAILED)
			else
				NotPlater:SetCastBarNameText(frame, INTERRUPTED)
			end
			frame.castBar.casting = nil
			frame.castBar.channeling = nil
		end
	elseif event == "UNIT_SPELLCAST_DELAYED" then
		if frame:IsShown() then
			local name, _, _, _, startTime, endTime = UnitCastingInfo(unit)
			if not name then
				-- if there is no name, there is no bar
				frame.castBar:Hide()
				return
			end

			NotPlater:SetCastBarNameText(frame, name)
			frame.castBar.value = (GetTime() - (startTime / 1000))
			frame.castBar.maxValue = (endTime - startTime) / 1000
			frame.castBar:SetMinMaxValues(0, frame.castBar.maxValue)

			if not frame.castBar.casting then
				frame.castBar.casting = true
				frame.castBar.channeling = nil
			end
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local name, _, _, texture, startTime, endTime = UnitChannelInfo(unit)
		if not name then
			frame.castBar:Hide()
			return
		end

		NotPlater:SetCastBarNameText(frame, name)
		frame.castBar.value = (endTime / 1000) - GetTime()
		frame.castBar.maxValue = (endTime - startTime) / 1000
		frame.castBar:SetMinMaxValues(0, frame.castBar.maxValue)
		frame.castBar:SetValue(frame.castBar.value)

		if frame.castBar.icon then
			frame.castBar.icon.texture:SetTexture(texture)
		end

		frame.castBar.casting = nil
		frame.castBar.channeling = true

		frame.castBar:Show()
	elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		if frame.castBar:IsShown() then
			local name, _, _, _, startTime, endTime = UnitChannelInfo(unit)
			if not name then
				frame.castBar:Hide()
				return
			end

			NotPlater:SetCastBarNameText(frame, name)
			frame.castBar.value = ((endTime / 1000) - GetTime())
			frame.castBar.maxValue = (endTime - startTime) / 1000
			frame.castBar:SetMinMaxValues(0, frame.castBar.maxValue)
			frame.castBar:SetValue(frame.castBar.value)
		end
	end
end

function NotPlater:CastCheck(frame)
	if frame.castBar.casting or frame.castBar.channeling then
		frame.castBar:Show()
	else
		self:CastBarOnCast(frame, "UNIT_SPELLCAST_START", "target")
		if not frame.castBar.casting then
			self:CastBarOnCast(frame, "UNIT_SPELLCAST_CHANNEL_START", "target")
		end
	end
end

function NotPlater:ScaleCastBar(castFrame, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.castBar then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
    	local castBarConfig = self.db.profile.castBar
		self:ScaleGeneralisedStatusBar(castFrame, scalingFactor, castBarConfig.statusBar)
		self:ScaleIcon(castFrame.icon, scalingFactor, castBarConfig.spellIcon)
		self:ScaleGeneralisedText(castFrame.spellNameText, scalingFactor, castBarConfig.spellNameText)
		self:ScaleGeneralisedText(castFrame.spellTimeText, scalingFactor, castBarConfig.spellTimeText)
	end
end

function NotPlater:CastBarOnShow(frame)
	local castFrame = frame.castBar
	castFrame.casting = nil
	castFrame.channeling = nil
	NotPlater:CastCheck(frame)
	-- Tried to make it reappear, but this does not really work since you can't track whether something was interrupted
	--if castFrame.casting or castFrame.channeling then
		--if castFrame.lastUpdate then
			--castFrame.helper = self.CastBarOnUpdate
			--castFrame:helper(GetTime() - castFrame.lastUpdate)
		--end
		--castFrame:Show()
	--end
end

function NotPlater:ConfigureCastBar(frame)
    local castBarConfig = self.db.profile.castBar
	local castFrame = frame.castBar

    -- Set background
	self:ConfigureGeneralisedPositionedStatusBar(castFrame, frame.healthBar, castBarConfig.statusBar)
	castFrame:SetStatusBarColor(self:GetColor(castBarConfig.statusBar.general.color))

	-- Set castbar icon
	self:ConfigureIcon(castFrame.icon, castFrame, castBarConfig.spellIcon)
	
    -- Set text
	self:ConfigureGeneralisedText(castFrame.spellTimeText, castFrame, castBarConfig.spellTimeText)
	self:ConfigureGeneralisedText(castFrame.spellNameText, castFrame, castBarConfig.spellNameText)
end

function NotPlater:ConstructCastBar(frame)
	local castFrame = CreateFrame("StatusBar", "$parentCastBar", frame)
	castFrame:SetScript("OnUpdate", NotPlater.CastBarOnUpdate)
	castFrame:SetFrameLevel(frame:GetFrameLevel() + 2)

    -- Create the icon
	self:ConstructIcon(castFrame)

    -- Create cast time text and set font
    castFrame.spellTimeText = castFrame:CreateFontString(nil, "ARTWORK")

    -- Create cast name text and set font
    castFrame.spellNameText = castFrame:CreateFontString(nil, "ARTWORK")

    -- Create and set background
	self:ConstructGeneralisedStatusBar(castFrame)

	frame.castBar = castFrame
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