if not NotPlater then
	return
end

local Vertical = {}
NotPlater.AuraCooldownVertical = Vertical

local GetTime = GetTime
local math_max = math.max

local MIN_HEIGHT = 0.00001

local function ApplyAnchor(icon, invert)
	if not icon.verticalCooldownFill then
		return
	end
	local target = invert and "BOTTOM" or "TOP"
	if icon.verticalCooldownAnchor == target then
		return
	end
	icon.verticalCooldownAnchor = target
	icon.verticalCooldownFill:ClearAllPoints()
	if target == "BOTTOM" then
		icon.verticalCooldownFill:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
		icon.verticalCooldownFill:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
	else
		icon.verticalCooldownFill:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
		icon.verticalCooldownFill:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
	end
end

function Vertical:Attach(icon)
	if icon.verticalCooldownFill then
		return
	end
	local fill = icon:CreateTexture(nil, "OVERLAY")
	fill:SetDrawLayer("OVERLAY", 1)
	fill:SetTexture("Interface\\Buttons\\WHITE8X8")
	fill:SetVertexColor(0, 0, 0, 0.65)
	fill:SetHeight(MIN_HEIGHT)
	fill:Hide()
	icon.verticalCooldownFill = fill
end

function Vertical:Setup(icon, aura, config)
	if not aura or not aura.duration or aura.duration <= 0 then
		self:Reset(icon)
		return
	end
	self:Attach(icon)
	ApplyAnchor(icon, config and config.invertSwipe)
	icon.verticalCooldownDuration = aura.duration
	icon.verticalCooldownEnd = aura.expirationTime or 0
	icon.verticalCooldownActive = true
	self:Update(icon, config)
end

function Vertical:Reset(icon)
	if icon.verticalCooldownFill then
		icon.verticalCooldownFill:SetHeight(MIN_HEIGHT)
		icon.verticalCooldownFill:Hide()
	end
	icon.verticalCooldownActive = nil
	icon.verticalCooldownDuration = nil
	icon.verticalCooldownEnd = nil
	icon.verticalCooldownAnchor = nil
end

function Vertical:Detach(icon)
	if icon.verticalCooldownFill then
		icon.verticalCooldownFill:Hide()
		icon.verticalCooldownFill:SetTexture(nil)
		icon.verticalCooldownFill = nil
	end
	self:Reset(icon)
end

function Vertical:Update(icon, config)
	if not icon.verticalCooldownActive or not icon.verticalCooldownDuration or icon.verticalCooldownDuration <= 0 then
		self:Reset(icon)
		return
	end
	local fill = icon.verticalCooldownFill
	if not fill then
		self:Reset(icon)
		return
	end
	ApplyAnchor(icon, config and config.invertSwipe)
	local remaining = (icon.verticalCooldownEnd or 0) - GetTime()
	if remaining <= 0 then
		self:Reset(icon)
		return
	end
	local progress = 1 - (remaining / icon.verticalCooldownDuration)
	if progress < 0 then
		progress = 0
	elseif progress > 1 then
		progress = 1
	end
	local height = math_max(MIN_HEIGHT, icon:GetHeight() * progress)
	fill:SetHeight(height)
	fill:Show()
end
