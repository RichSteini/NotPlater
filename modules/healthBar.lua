if( not NotPlater ) then return end

function NotPlater:HealthOnValueChanged(oldHealthBar, value)
	local _, maxValue = oldHealthBar:GetMinMaxValues()
	local healthBarConfig = self.db.profile.healthBar

	local healthFrame = oldHealthBar.healthBar
	healthFrame:GetParent().healthBar:SetMinMaxValues(0, maxValue)
	healthFrame:SetValue(value)

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
			healthFrame.healthText:SetFormattedText("%.1fk (%d%%)", value/1000, value/maxValue * 100)
		else
			healthFrame.healthText:SetFormattedText("%d (%d%%)", value, value/maxValue * 100)
		end
	elseif healthBarConfig.healthText.general.displayType == "percent" then
		healthFrame.healthText:SetFormattedText("%d%%", value / maxValue * 100)
	else
		healthFrame.healthText:SetText("")
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
	-- Configure statusbar
	self:ConfigureGeneralisedStatusBar(healthFrame, healthBarConfig.statusBar)

	-- Set points
	healthFrame:ClearAllPoints()
	self:SetSize(healthFrame, healthBarConfig.statusBar.size.width, healthBarConfig.statusBar.size.height)
	healthFrame:SetPoint("TOP", 0, self.db.profile.stacking.margin.yStacking)

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