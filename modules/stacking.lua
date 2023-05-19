if( not NotPlater ) then return end

local UnitAffectingCombat = UnitAffectingCombat

function NotPlater:SetTargetFrameStrata(frame)
	local stackingConfig = self.db.profile.stacking
	if stackingConfig.general.enable and not UnitAffectingCombat("player") then
		if frame:GetFrameStrata() ~= stackingConfig.frameStrata.targetFrame then
			frame:SetFrameStrata(stackingConfig.frameStrata.targetFrame)
		end
	end
end

function NotPlater:SetNormalFrameStrata(frame)
	local stackingConfig = self.db.profile.stacking
	if stackingConfig.general.enable and not UnitAffectingCombat("player") then
		if frame:GetFrameStrata() ~= stackingConfig.frameStrata.normalFrame then
			frame:SetFrameStrata(stackingConfig.frameStrata.normalFrame)
		end
	end
end

function NotPlater:ConfigureStacking(frame)
	self:StackingCheck(frame)
end

function NotPlater:StackingCheck(frame)
	local stackingConfig = self.db.profile.stacking
	local healthBarConfig = self.db.profile.healthBar.statusBar
	local castBarConfig = self.db.profile.castBar.statusBar
	if stackingConfig.general.enable and not UnitAffectingCombat("player") then
		-- Set the clickable frame size
		if stackingConfig.general.overlappingCastbars then
			self:SetSize(frame, healthBarConfig.size.width + stackingConfig.margin.xStacking * 2, healthBarConfig.size.height + stackingConfig.margin.yStacking * 2)
		else
			self:SetSize(frame, healthBarConfig.size.width + stackingConfig.margin.xStacking * 2, healthBarConfig.size.height + castBarConfig.size.height + stackingConfig.margin.yStacking * 2)
		end
	end
end