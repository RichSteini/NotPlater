if( not NotPlater ) then return end

function NotPlater:HealthOnValueChanged(health, value)
	local _, maxValue = health:GetMinMaxValues()
	local healthBarConfig = self.db.profile.healthBar

	if( healthBarConfig.healthText.type == "minmax" ) then
		if( maxValue == 100 ) then
			health.npHealthText:SetFormattedText("%d%% / %d%%", value, maxValue)	
		else
			if(maxValue > 1000) then
				if(value > 1000) then
					health.npHealthText:SetFormattedText("%.1fk / %.1fk", value / 1000, maxValue / 1000)
				else
					health.npHealthText:SetFormattedText("%d / %.1fk", value, maxValue / 1000)
				end
			else
				health.npHealthText:SetFormattedText("%d / %d", value, maxValue)
			end
		end
	elseif( healthBarConfig.healthText.type == "both" ) then
		if(value > 1000) then
			health.npHealthText:SetFormattedText("%.1fk (%d%%)", value/1000, value/maxValue * 100)
		else
			health.npHealthText:SetFormattedText("%d (%d%%)", value, value/maxValue * 100)
		end
	elseif( healthBarConfig.healthText.type == "percent" ) then
		health.npHealthText:SetFormattedText("%d%%", value / maxValue * 100)
	else
		health.npHealthText:SetText("")
	end

	self:ThreatCheck(health)
end

function NotPlater:HealthBarOnShow(healthFrame)
	local healthBarConfig = self.db.profile.healthBar
	local generalConfig = self.db.profile.general

	healthFrame:ClearAllPoints()
	self:SetSize(healthFrame, healthBarConfig.position.xSize, healthBarConfig.position.ySize)
	healthFrame:SetPoint("TOP", 0, generalConfig.nameplateStacking.yMargin)
	if not healthBarConfig.hideBorder then
		healthFrame.npHealthOverlay:ClearAllPoints()
		healthFrame.npHealthOverlay:SetAllPoints(healthFrame)
		healthFrame.npHealthOverlay:Show()
	end
end

function NotPlater:ConfigureHealthBar(healthFrame)
	local healthBarConfig = self.db.profile.healthBar

	-- Set points
	self:HealthBarOnShow(healthFrame)

	-- Set textures for health- and castbar
	healthFrame:SetStatusBarTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, healthBarConfig.texture))

	-- Set health text
	healthFrame.npHealthText:ClearAllPoints()
	healthFrame.npHealthText:SetPoint(healthBarConfig.healthText.anchor, healthFrame, healthBarConfig.healthText.xOffset, healthBarConfig.healthText.yOffset)
	self:SetupFontString(healthFrame.npHealthText, healthBarConfig.healthText, true)

	-- Set background
	healthFrame.npHealthBackground:SetAllPoints(healthFrame)
	healthFrame.npHealthBackground:SetTexture(healthBarConfig.backgroundColor.r, healthBarConfig.backgroundColor.g, healthBarConfig.backgroundColor.b, healthBarConfig.backgroundColor.a)

	self:HealthOnValueChanged(healthFrame, healthFrame:GetValue())
end

function NotPlater:ConstructHealthBar(healthFrame)
	local healthBarConfig = self.db.profile.healthBar

    -- Other addons need the texture of healthBorder to not change, therefore we have to create a new one
    healthFrame.npHealthOverlay = healthFrame:CreateTexture(nil, 'OVERLAY')
    healthFrame.npHealthOverlay:SetTexture('Interface\\AddOns\\NotPlater\\images\\textureOverlay')

    -- Background
    healthFrame.npHealthBackground = healthFrame:CreateTexture(nil, 'BORDER')

    -- Create health text
    healthFrame.npHealthText = healthFrame:CreateFontString(nil, "ARTWORK")
    
    -- Hook to set health text
	self:HookScript(healthFrame, "OnValueChanged", "HealthOnValueChanged")
end