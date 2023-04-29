if( not NotPlater ) then return end

local UnitAffectingCombat = UnitAffectingCombat

local targetCheckElapsed = 0

function NotPlater:ConstructTargetBorder(healthFrame, frame)
	local healthBarConfig = self.db.profile.healthBar
	local generalConfig = self.db.profile.general

    if(not healthBarConfig.hideTargetBorder) then
        self:HookScript(frame, 'OnUpdate', function(_, elapsed)
            targetCheckElapsed = targetCheckElapsed + elapsed
            if (targetCheckElapsed >= 0.1) then
                if (self:IsTarget(frame)) then
                    if (not frame.npTargetHighlight) then
                        frame.npTargetHighlight = frame:CreateTexture(nil, 'ARTWORK')
                        frame.npTargetHighlight:SetPoint("TOPRIGHT", healthFrame, 2, 2)
                        frame.npTargetHighlight:SetPoint("BOTTOMLEFT", healthFrame, -2, -2)
                        frame.npTargetHighlight:SetTexture('Interface\\AddOns\\NotPlater\\images\\targetTextureOverlay')
                        frame.npTargetHighlight:Hide()
                    end
    
                    if (not frame.npTargetHighlight:IsVisible()) then
                        frame.npTargetHighlight:Show()
				        self:CastCheck(frame)
                    end
                    if generalConfig.nameplateStacking.enabled and not UnitAffectingCombat("player") then
                        if frame:GetFrameStrata() ~= generalConfig.frameStrata.targetFrame then
                            frame:SetFrameStrata(generalConfig.frameStrata.targetFrame)
                        end
                    end
                else
                    if (frame.npTargetHighlight and frame.npTargetHighlight:IsVisible()) then
                        frame.npTargetHighlight:Hide()
                    end
                    if generalConfig.nameplateStacking.enabled and not UnitAffectingCombat("player") then
                        if frame:GetFrameStrata() ~= generalConfig.frameStrata.frame then
                            frame:SetFrameStrata(generalConfig.frameStrata.frame)
                        end
                    end
                end
                targetCheckElapsed = 0
            end
        end)
    end
end