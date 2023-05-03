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

	-- Set border
	if healthBarConfig.border.enabled then
		healthFrame.npHealthBorder:ClearAllPoints()
		healthFrame.npHealthBorder:SetAllPoints(healthFrame)
		healthFrame.npHealthBorder:SetBackdrop({bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", tileSize=16, tile=true, edgeSize=healthBarConfig.border.thickness})
		healthFrame.npHealthBorder:SetBackdropColor(0, 0, 0, 0)
		healthFrame.npHealthBorder:SetBackdropBorderColor(self:GetColor(healthBarConfig.border.color))
		healthFrame.npHealthBorder:Show()
	else
		healthFrame.npHealthBorder:Hide()
	end

	self:HealthOnValueChanged(healthFrame, healthFrame:GetValue())
end

function NotPlater:ConstructHealthBar(healthFrame)
	local healthBarConfig = self.db.profile.healthBar

    -- Background
    healthFrame.npHealthBackground = healthFrame:CreateTexture(nil, 'BORDER')

    -- Create health text
    healthFrame.npHealthText = healthFrame:CreateFontString(nil, "ARTWORK")

	-- Border
	healthFrame.npHealthBorder = CreateFrame("Frame", nil, healthFrame)
    healthFrame.npHealthBorder:SetFrameLevel(healthFrame:GetFrameLevel() + 1)
    
    -- Hook to set health text
	self:HookScript(healthFrame, "OnValueChanged", "HealthOnValueChanged")
end