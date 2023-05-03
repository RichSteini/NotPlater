if( not NotPlater ) then return end

local UnitAffectingCombat = UnitAffectingCombat

function NotPlater:ConstructTargetBorder(healthFrame, frame)
	local healthBarConfig = self.db.profile.healthBar
	local generalConfig = self.db.profile.general

    if(not healthBarConfig.hideTargetBorder) then
        self:HookScript(frame, 'OnUpdate', function(self, elapsed)
            if not self.targetCheckElapsed then self.targetCheckElapsed = 0 end
            self.targetCheckElapsed = self.targetCheckElapsed + elapsed
            if (self.targetCheckElapsed >= 0.2) then
                if (NotPlater:IsTarget(self)) then
                    if (not self.npTargetHighlight) then
                        self.npTargetHighlight = self:CreateTexture(nil, 'ARTWORK')
                        self.npTargetHighlight:SetPoint("TOPRIGHT", healthFrame, 2, 2)
                        self.npTargetHighlight:SetPoint("BOTTOMLEFT", healthFrame, -2, -2)
                        self.npTargetHighlight:SetTexture('Interface\\AddOns\\NotPlater\\images\\targetTextureOverlay')
                        self.npTargetHighlight:Hide()
                    end
    
                    if (not self.npTargetHighlight:IsVisible()) then
                        self.npTargetHighlight:Show()
				        NotPlater:CastCheck(self)
                    end
                    if generalConfig.nameplateStacking.enabled and not UnitAffectingCombat("player") then
                        if self:GetFrameStrata() ~= generalConfig.frameStrata.targetFrame then
                            self:SetFrameStrata(generalConfig.frameStrata.targetFrame)
                        end
                    end
                else
                    if (self.npTargetHighlight and self.npTargetHighlight:IsVisible()) then
                        self.npTargetHighlight:Hide()
                    end
                    if generalConfig.nameplateStacking.enabled and not UnitAffectingCombat("player") then
                        if self:GetFrameStrata() ~= generalConfig.frameStrata.frame then
                            self:SetFrameStrata(generalConfig.frameStrata.frame)
                        end
                    end
                end
                self.targetCheckElapsed = 0
            end
        end)
    end
end