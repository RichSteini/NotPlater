if( not NotPlater ) then return end

function NotPlater:ConfigureStacking(frame)
	local generalConfig = self.db.profile.general
	local healthBarConfig = self.db.profile.healthBar
	local castBarConfig = self.db.profile.castBar
	if generalConfig.nameplateStacking.enabled and not UnitAffectingCombat("player") then
		-- Set the clickable frame size
		if generalConfig.nameplateStacking.overlappingCastbars then
			self:SetSize(frame, healthBarConfig.position.xSize + generalConfig.nameplateStacking.xMargin * 2, healthBarConfig.position.ySize + generalConfig.nameplateStacking.yMargin * 2)
		else
			self:SetSize(frame, healthBarConfig.position.xSize + generalConfig.nameplateStacking.xMargin * 2, healthBarConfig.position.ySize + castBarConfig.position.ySize + generalConfig.nameplateStacking.yMargin * 2)
		end
	end
end

function NotPlater:ConstructStacking(frame)
	local generalConfig = self.db.profile.general
	local healthBarConfig = self.db.profile.healthBar
	local castBarConfig = self.db.profile.castBar
    if generalConfig.nameplateStacking.enabled then
        self:HookScript(frame, "OnShow", function(frame)
            if not UnitAffectingCombat("player") then
                if generalConfig.nameplateStacking.overlappingCastbars then
                    self:SetSize(frame, healthBarConfig.position.xSize + generalConfig.nameplateStacking.xMargin * 2, healthBarConfig.position.ySize + generalConfig.nameplateStacking.yMargin * 2)
                else
                    self:SetSize(frame, healthBarConfig.position.xSize + generalConfig.nameplateStacking.xMargin * 2, healthBarConfig.position.ySize + castBarConfig.position.ySize + generalConfig.nameplateStacking.yMargin * 2)
                end
            end
        end)
    end
end