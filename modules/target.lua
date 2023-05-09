if( not NotPlater ) then return end

local unpack = unpack
local tinsert = table.insert

function NotPlater:ConfigureTarget(frame)
    local healthBarHeight = frame.healthBar:GetHeight()

	local preset = self.targetIndicators[self.db.profile.target.general.border.indicator.selection]
	if (not preset) then
		preset = self.targetIndicators["Silver"]
	end
	
	local width, height = preset.width, preset.height
	local wscale, hscale = preset.wscale or 1, preset.hscale or 1
	local x, y = preset.x or 0, preset.y or 0
	local desaturated = preset.desaturated
	local coords = preset.coords
	local path = preset.path
	local blend = preset.blend or "BLEND"
	local alpha = preset.alpha or 1
	local doScale = preset.autoScale
	local custScale = preset.scale
	local overlayColorR, overlayColorG, overlayColorB = preset.color and unpack(preset.color) or 1, 1, 1
	
	local scale = (not doScale and custScale) or (healthBarHeight / (doScale and height or 10))
	
	--four parts (textures)
	if (#coords == 4) then
		for i = 1, 4 do
			local texture = frame.targetTextures4Sides[i]
			texture:SetTexture(path)
			texture:SetTexCoord(unpack(coords[i]))
			self:SetSize(texture, width * scale * wscale, height * scale * hscale)
			texture:SetAlpha(alpha)
			texture:SetVertexColor(overlayColorR, overlayColorG, overlayColorB)
			texture:SetDesaturated(desaturated)
			
			if(i == 1) then
				texture:SetPoint("topleft", frame.healthBar, "topleft", -x * scale, y * scale)
				
			elseif(i == 2) then
				texture:SetPoint("bottomleft", frame.healthBar, "bottomleft", -x * scale, -y * scale)
				
			elseif(i == 3) then
				texture:SetPoint("bottomright", frame.healthBar, "bottomright", x * scale, -y * scale)
				
			elseif(i == 4) then
				texture:SetPoint("topright", frame.healthBar, "topright", x * scale, y * scale)
			end
		end
	else -- two parts
		for i = 1, 2 do
			local texture = frame.targetTextures2Sides[i]
			texture:SetTexture(path)
			texture:SetBlendMode(blend)
			texture:SetTexCoord(unpack(coords[i]))
			self:SetSize(texture, width * scale * wscale, height * scale * hscale)
			texture:SetDesaturated(desaturated)
			texture:SetAlpha(alpha)
			texture:SetVertexColor(overlayColorR, overlayColorG, overlayColorB)
			
			if (i == 1) then
				texture:SetPoint("left", frame.healthBar, "left", -x * scale, y * scale)
			elseif (i == 2) then
				texture:SetPoint("right", frame.healthBar, "right", x * scale, y * scale)
			end
		end
	end

    -- highlight (glow)
    local targetHighlightConfig = self.db.profile.target.general.border.highlight
    frame.targetNeonUp:SetVertexColor(self:GetColor(targetHighlightConfig.color))
	frame.targetNeonUp:SetAlpha (self:GetAlpha(targetHighlightConfig.color))
	frame.targetNeonUp:SetTexture(targetHighlightConfig.texture)
	frame.targetNeonUp:SetHeight(targetHighlightConfig.thickness)
	frame.targetNeonUp:SetPoint("bottomleft", frame.healthBar, "topleft", 0, 0)
	frame.targetNeonUp:SetPoint("bottomright", frame.healthBar, "topright", 0, 0)

	frame.targetNeonDown:SetVertexColor(self:GetColor(targetHighlightConfig.color))
	frame.targetNeonDown:SetAlpha(self:GetAlpha(targetHighlightConfig.color))
	frame.targetNeonDown:SetTexture(targetHighlightConfig.texture)
	frame.targetNeonDown:SetHeight(targetHighlightConfig.thickness)
	frame.targetNeonDown:SetPoint("topleft", frame.healthBar, "bottomleft", 0, 0)
	frame.targetNeonDown:SetPoint("topright", frame.healthBar, "bottomright", 0, 0)

    local targetOverlayConfig = self.db.profile.target.general.overlay
    frame.targetOverlay:SetTexture(self.SML:Fetch(self.SML.MediaType.STATUSBAR, targetOverlayConfig.texture))
    frame.targetOverlay:SetVertexColor(self:GetColor(targetOverlayConfig.color))

    local nonTargetShadingConfig = self.db.profile.target.general.nonTargetShading
    frame.nonTargetShading:SetAlpha(nonTargetShadingConfig.opacity)

	self:ConfigureGeneralisedText(frame.targetTargetText, frame.healthBar, self.db.profile.target.targetTargetText)
end

function NotPlater:TargetOnTarget(frame)
    local hide2s, hide4s = false, false
    local targetBorderConfig = NotPlater.db.profile.target.general.border
    if targetBorderConfig.indicator.enable and frame.healthBar:GetHeight() > 4 then
        local preset = NotPlater.targetIndicators[targetBorderConfig.indicator.selection]
        if (not preset) then preset = NotPlater.targetIndicators["Silver"] end
        if (#preset.coords == 4) then
            hide2s = true
            for i = 1, 4 do
                frame.targetTextures4Sides[i]:Show()
            end
        else
            hide4s = true
            for i = 1, 2 do
                frame.targetTextures2Sides[i]:Show()
            end
        end
    else
        hide2s = true
        hide4s = true
    end

    if hide2s then
        for i = 1, 2 do
            frame.targetTextures2Sides[i]:Hide()
        end
    end
    if hide4s then
        for i = 1, 4 do
            frame.targetTextures4Sides[i]:Hide()
        end
    end

    if targetBorderConfig.highlight.enable then
        frame.targetNeonDown:Show()
        frame.targetNeonUp:Show()
    else
        frame.targetNeonDown:Hide()
        frame.targetNeonUp:Hide()
    end

    if self.db.profile.target.general.overlay.enable then
        frame.targetOverlay:Show()
    else
        frame.targetOverlay:Hide()
    end
    frame.nonTargetShading:Hide()
end

function NotPlater:TargetOnNonTarget(frame)
    for i = 1, 2 do
        frame.targetTextures2Sides[i]:Hide()
    end
    for i = 1, 4 do
        frame.targetTextures4Sides[i]:Hide()
    end
    frame.targetNeonDown:Hide()
    frame.targetNeonUp:Hide()
    frame.targetOverlay:Hide()
    if self.db.profile.target.general.nonTargetShading.enable then
        frame.nonTargetShading:Show()
    else
        frame.nonTargetShading:Hide()
    end
    frame.targetOverlay:Hide()
end

function NotPlater:SetTargetTargetText(frame)
    if NotPlater.db.profile.target.targetTargetText.general.enable then
        if self:IsTarget(frame) then
            local targetTargetName = UnitName("target-target")
            if targetTargetName then
                self:SetMaxLetterText(frame.targetTargetText, targetTargetName, self.db.profile.target.targetTargetText)
                frame.targetTargetText:Show()
            else
                frame.targetTargetText:SetText("")
            end
        else
            frame.targetTargetText:Hide()
        end
    else
        if frame.targetTargetText:IsShown() then
            frame.targetTargetText:Hide()
        end
    end
end

function NotPlater:ScaleTargetTargetText(targetTargetText, isTarget)
	local scaleConfig = self.db.profile.target.general.scale
	if scaleConfig.targetTargetText then
		local scalingFactor = isTarget and scaleConfig.scalingFactor or 1
		self:ScaleGeneralisedText(targetTargetText, scalingFactor, self.db.profile.target.targetTargetText)
	end
end

function NotPlater:TargetCheck(frame)
    local isTarget = NotPlater:IsTarget(frame)
    if(isTarget) then
        NotPlater:TargetOnTarget(frame)
        NotPlater:SetTargetFrameStrata(frame)
        NotPlater:CastCheck(frame)
    else
        NotPlater:TargetOnNonTarget(frame)
        NotPlater:SetNormalFrameStrata(frame)
    end
    NotPlater:ScaleHealthBar(frame.healthBar, isTarget)
    NotPlater:ScaleCastBar(frame.castBar, isTarget)
    NotPlater:ScaleNameText(frame.nameText, isTarget)
    NotPlater:ScaleTargetTargetText(frame.targetTargetText, isTarget)
    NotPlater:ScaleLevelText(frame.levelText, isTarget)
    NotPlater:ScaleBossIcon(frame.bossIcon, isTarget)
    NotPlater:ScaleRaidIcon(frame.raidIcon, isTarget)
    NotPlater:ScaleThreatComponents(frame.healthBar,isTarget)
end

function NotPlater:ConstructTarget(frame)
    frame.targetTextures2Sides = {}
    frame.targetTextures4Sides = {}
    for i = 1, 2 do
        local targetTexture = frame.healthBar:CreateTexture(nil, "overlay")
        targetTexture:SetDrawLayer("overlay", 7)
        tinsert (frame.targetTextures2Sides, targetTexture)
    end
    for i = 1, 4 do
        local targetTexture = frame.healthBar:CreateTexture(nil, "overlay")
        targetTexture:SetDrawLayer("overlay", 7)
        tinsert(frame.targetTextures4Sides, targetTexture)
    end

    local targetNeonUp = frame:CreateTexture(nil, "overlay")
    targetNeonUp:SetDrawLayer("overlay", 7)
    targetNeonUp:SetBlendMode("ADD")
    targetNeonUp:Hide()
    frame.targetNeonUp = targetNeonUp
		
    local targetNeonDown = frame:CreateTexture (nil, "overlay")
    targetNeonDown:SetDrawLayer("overlay", 7)
    targetNeonDown:SetBlendMode("ADD")
    targetNeonDown:SetTexCoord(0, 1, 1, 0)
    targetNeonDown:Hide()
    frame.targetNeonDown = targetNeonDown
		
    frame.targetOverlay = frame.healthBar:CreateTexture (nil, "overlay")
    frame.targetOverlay:SetDrawLayer("overlay", 6)
    frame.targetOverlay:SetBlendMode("ADD")
    frame.targetOverlay:SetAllPoints()

    frame.nonTargetShading = frame.healthBar:CreateTexture (nil, "overlay")
    frame.nonTargetShading:SetDrawLayer ("overlay", 6)
    frame.nonTargetShading:SetAllPoints()
    frame.nonTargetShading:SetTexture ("Interface\\Tooltips\\UI-Tooltip-Background")
    frame.nonTargetShading:SetVertexColor (0, 0, 0, 1)

    -- Create health text
    frame.targetTargetText = frame.healthBar:CreateFontString(nil, "ARTWORK")
end