if( not NotPlater ) then return end

local unpack = unpack
local tinsert = table.insert
local UnitAffectingCombat = UnitAffectingCombat

function NotPlater:ConfigureTargetBorder(healthFrame, frame)
    local healthBarHeight = healthFrame:GetHeight()

	local preset = self.targetIndicators[self.db.profile.targetBorder.indicator.selection]
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
				texture:SetPoint("topleft", healthFrame, "topleft", -x * scale, y * scale)
				
			elseif(i == 2) then
				texture:SetPoint("bottomleft", healthFrame, "bottomleft", -x * scale, -y * scale)
				
			elseif(i == 3) then
				texture:SetPoint("bottomright", healthFrame, "bottomright", x * scale, -y * scale)
				
			elseif(i == 4) then
				texture:SetPoint("topright", healthFrame, "topright", x * scale, y * scale)
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
				texture:SetPoint("left", healthFrame, "left", -x * scale, y * scale)
			elseif (i == 2) then
				texture:SetPoint("right", healthFrame, "right", x * scale, y * scale)
			end
		end
	end

    -- highlight (glow)
    local targetHighlightConfig = self.db.profile.targetBorder.highlight
    frame.targetNeonUp:SetVertexColor(self:GetColor(targetHighlightConfig.color))
	frame.targetNeonUp:SetAlpha (targetHighlightConfig.color.a)
	frame.targetNeonUp:SetTexture(targetHighlightConfig.texture)
	frame.targetNeonUp:SetHeight(targetHighlightConfig.thickness)
	frame.targetNeonUp:SetPoint("bottomleft", healthFrame, "topleft", 0, 0)
	frame.targetNeonUp:SetPoint("bottomright", healthFrame, "topright", 0, 0)

	frame.targetNeonDown:SetVertexColor(self:GetColor(targetHighlightConfig.color))
	frame.targetNeonDown:SetAlpha(targetHighlightConfig.color.a)
	frame.targetNeonDown:SetTexture(targetHighlightConfig.texture)
	frame.targetNeonDown:SetHeight(targetHighlightConfig.thickness)
	frame.targetNeonDown:SetPoint("topleft", healthFrame, "bottomleft", 0, 0)
	frame.targetNeonDown:SetPoint("topright", healthFrame, "bottomright", 0, 0)
end

function NotPlater:ConstructTargetBorder(healthFrame, frame)

    frame.targetTextures2Sides = {}
    frame.targetTextures4Sides = {}
    for i = 1, 2 do
        local targetTexture = healthFrame:CreateTexture(nil, "overlay")
        targetTexture:SetDrawLayer("overlay", 7)
        tinsert (frame.targetTextures2Sides, targetTexture)
    end
    for i = 1, 4 do
        local targetTexture = healthFrame:CreateTexture(nil, "overlay")
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
		
    --frame.targetOverlayTexture = healthFrame:CreateTexture (nil, "artwork")
    --frame.targetOverlayTexture:SetDrawLayer("artwork", 2)
    --frame.targetOverlayTexture:SetBlendMode("ADD")
    --frame.targetOverlayTexture:SetAllPoints()

    self:HookScript(frame, 'OnUpdate', function(self, elapsed)
        if not self.targetCheckElapsed then self.targetCheckElapsed = 0 end
        self.targetCheckElapsed = self.targetCheckElapsed + elapsed
        if (self.targetCheckElapsed >= 0.1) then
            if (NotPlater:IsTarget(self)) then
                local hide2s, hide4s = false, false
	            local targetBorderConfig = NotPlater.db.profile.targetBorder
                if targetBorderConfig.indicator.enabled or healthFrame:GetHeight() < 4 then
                    local preset = NotPlater.targetIndicators[NotPlater.db.profile.targetBorder.indicator.selection]
                    if (not preset) then preset = NotPlater.targetIndicators["Silver"] end
	                if (#preset.coords == 4) then
                        hide2s = true
                        for i = 1, 4 do
                            self.targetTextures4Sides[i]:Show()
                        end
                    else
                        hide4s = true
                        for i = 1, 2 do
                            self.targetTextures2Sides[i]:Show()
                        end
                    end
                else
                    hide2s = true
                    hide4s = true
                end

                if hide2s then
                    for i = 1, 2 do
                        self.targetTextures2Sides[i]:Hide()
                    end
                end
                if hide4s then
                    for i = 1, 4 do
                        self.targetTextures4Sides[i]:Hide()
                    end
                end

                if targetBorderConfig.highlight.enabled then
                    self.targetNeonDown:Show()
                    self.targetNeonUp:Show()
                else
                    self.targetNeonDown:Hide()
                    self.targetNeonUp:Hide()
                end
                NotPlater:SetTargetFrameStrata(self)
                if not self.initTarget then
                    NotPlater:CastCheck(self)
                    self.initTarget = true
                end
            else
                for i = 1, 2 do
                    self.targetTextures2Sides[i]:Hide()
                end
                for i = 1, 4 do
                    self.targetTextures4Sides[i]:Hide()
                end
                self.targetNeonDown:Hide()
                self.targetNeonUp:Hide()
                NotPlater:SetNormalFrameStrata(self)
                self.initTarget = false
            end
            self.targetCheckElapsed = 0
        end
    end)
end