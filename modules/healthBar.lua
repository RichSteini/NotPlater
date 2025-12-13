if( not NotPlater ) then return end

function NotPlater:HealthOnValueChanged(oldHealthBar, value)
	local _, maxValue = oldHealthBar:GetMinMaxValues()
	local healthBarConfig = self.db.profile.healthBar

	-- Validate input values to prevent display issues
	if not value or not maxValue or maxValue <= 0 then
		return
	end
	
	-- Clamp value to valid range to prevent health bar showing incorrect values
	value = math.max(0, math.min(value, maxValue))

	local healthFrame = oldHealthBar.healthBar
	-- Ensure we have a valid health frame reference
	if not healthFrame then
		return
	end
	
	-- Set min/max values before setting the current value to avoid race conditions
	healthFrame:SetMinMaxValues(0, maxValue)
	healthFrame:SetValue(value)

	-- Update health text if it exists
	if healthFrame.healthText then
		if healthBarConfig.healthText.general.displayType == "minmax" then
			if( maxValue == 100 ) then
				healthFrame.healthText:SetFormattedText("%d%% / %d%%", value, maxValue)
			else
				if(maxValue > 1000) then
					if(value > 1000) then
						healthFrame.healthText:SetFormattedText("%.1fk / %.1fk", value / 1000, maxValue / 1000)
					else
						healthFrame.healthText:SetFormattedText("%d / %.1fk", value, maxValue / 1000)
					end
				else
					healthFrame.healthText:SetFormattedText("%d / %d", value, maxValue)
				end
			end
		elseif healthBarConfig.healthText.general.displayType == "both" then
			if(value > 1000) then
				healthFrame.healthText:SetFormattedText("%.1fk (%d%%)", value/1000, math.floor(value/maxValue * 100))
			else
				healthFrame.healthText:SetFormattedText("%d (%d%%)", value, math.floor(value/maxValue * 100))
			end
		elseif healthBarConfig.healthText.general.displayType == "percent" then
			healthFrame.healthText:SetFormattedText("%d%%", math.floor(value / maxValue * 100))
		else
			healthFrame.healthText:SetText("")
		end
	end

	self:ThreatCheck(oldHealthBar:GetParent())
end

function NotPlater:ScaleHealthBar(healthFrame, isTarget)
	local scaleConfig = self.db.profile.target.scale
	if scaleConfig.healthBar then
    	local healthBarConfig = self.db.profile.healthBar
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleGeneralisedStatusBar(healthFrame, scalingFactor, healthBarConfig.statusBar)
		self:ScaleGeneralisedText(healthFrame.healthText, scalingFactor, healthBarConfig.healthText)
	end
end

function NotPlater:HealthBarOnShow(oldHealthBar)
	oldHealthBar.healthBar:SetStatusBarColor(oldHealthBar:GetStatusBarColor())
	oldHealthBar.healthBar.highlightTexture:SetAllPoints(oldHealthBar.healthBar)
end

function NotPlater:ConfigureHealthBar(frame, oldHealthBar)
	local healthBarConfig = self.db.profile.healthBar
	local healthFrame = frame.healthBar
	local stackingSettings = self:GetStackingSettings()
	-- Configure statusbar
	self:ConfigureGeneralisedStatusBar(healthFrame, healthBarConfig.statusBar)

	-- Set points
	healthFrame:ClearAllPoints()
	self:SetSize(healthFrame, healthBarConfig.statusBar.size.width, healthBarConfig.statusBar.size.height)
	healthFrame:SetPoint("TOP", 0, stackingSettings.margin.yStacking)

	-- Set health text
	self:ConfigureGeneralisedText(healthFrame.healthText, healthFrame, healthBarConfig.healthText)

	-- Set Mouseover highlight
	frame.highlightTexture:SetAlpha(self.db.profile.target.mouseoverHighlight.opacity)
	if self.db.profile.target.mouseoverHighlight.enable then
		frame.highlightTexture:SetTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, healthBarConfig.statusBar.general.texture))
	else
		frame.highlightTexture:SetTexture(0, 0, 0, 0)
	end

	self:HealthBarOnShow(oldHealthBar)
	self:HealthOnValueChanged(oldHealthBar, oldHealthBar:GetValue())
end

function NotPlater:ConstructHealthBar(frame, oldHealthBar)
	-- Construct statusbar components

	local healthFrame = CreateFrame("StatusBar", "$parentHealthBar", frame)
	self:ConstructGeneralisedStatusBar(healthFrame)

    -- Create health text
    healthFrame.healthText = healthFrame:CreateFontString(nil, "ARTWORK")

	-- Create Mouseover highlight
	frame.highlightTexture:SetBlendMode("ADD")
	healthFrame.highlightTexture = frame.highlightTexture

	-- Hook to set health text
	self:HookScript(oldHealthBar, "OnValueChanged", "HealthOnValueChanged")

	oldHealthBar.healthBar = healthFrame
	frame.healthBar = healthFrame
end
