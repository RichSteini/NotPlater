if not NotPlater then
	return
end

local Swirl = {}
NotPlater.AuraCooldownSwirl = Swirl

local CreateFrame = CreateFrame
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local CooldownFrame_SetReverse = CooldownFrame_SetReverse
local CooldownFrame_SetDrawEdge = CooldownFrame_SetDrawEdge

local DEFAULT_EDGE_TEXTURE = "Texture 3"

local function ResolveEdgeTexture(config)
	local textures = NotPlater.auraSwipeTextures
	if not textures then
		return nil
	end
	local key = config and config.texture
	return (key and textures[key]) or textures[DEFAULT_EDGE_TEXTURE]
end

local function ApplyEdgeTexture(cooldown, config)
	if not cooldown then
		return
	end
	local texture = ResolveEdgeTexture(config)
	if texture then
		if cooldown.SetEdgeTexture then
			cooldown:SetEdgeTexture(texture)
		elseif cooldown.SetSwipeTexture then
			cooldown:SetSwipeTexture(texture)
		end
	end
	if cooldown.SetDrawEdge then
		cooldown:SetDrawEdge(true)
	elseif CooldownFrame_SetDrawEdge then
		CooldownFrame_SetDrawEdge(cooldown, true)
	end
end

local function ApplyReverse(cooldown, config)
	if not cooldown then
		return
	end
	local reverse = true
	if config and config.invertSwipe then
		reverse = false
	end
	if cooldown.SetReverse then
		cooldown:SetReverse(reverse)
		elseif CooldownFrame_SetReverse then
		CooldownFrame_SetReverse(cooldown, reverse)
	end
end

local function ApplyCooldownConfig(icon, config)
	local cooldown = icon and icon.swirlCooldown
	if not icon or not cooldown then
		return
	end
	cooldown:ClearAllPoints()
	cooldown:SetAllPoints(icon)
	cooldown:SetFrameStrata(icon:GetFrameStrata())
	cooldown:SetFrameLevel((icon:GetFrameLevel() or 0) + 3)
	ApplyReverse(cooldown, config)
	ApplyEdgeTexture(cooldown, config)
	if cooldown.SetSwipeColor then
		cooldown:SetSwipeColor(0, 0, 0, 0.6)
	end
	if cooldown.SetDrawBling then
		cooldown:SetDrawBling(false)
	end
end

local function StartCooldown(cooldown, start, duration)
	if not cooldown then
		return
	end
	if cooldown.SetCooldown then
		cooldown:SetCooldown(start, duration)
	elseif CooldownFrame_SetTimer then
		CooldownFrame_SetTimer(cooldown, start, duration, duration > 0 and 1 or 0)
	end
end

local function ClearCooldown(cooldown)
	if not cooldown then
		return
	end
	if cooldown.Clear then
		cooldown:Clear()
	elseif cooldown.SetCooldown then
		cooldown:SetCooldown(0, 0)
	elseif CooldownFrame_SetTimer then
		CooldownFrame_SetTimer(cooldown, 0, 0, 0)
	end
end

function Swirl:Attach(icon, module, config)
	if icon.swirlCooldown then
		ApplyCooldownConfig(icon, config)
		return icon.swirlCooldown
	end
	local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	cooldown:SetAllPoints(icon)
	cooldown:Hide()
	icon.swirlCooldown = cooldown
	ApplyCooldownConfig(icon, config)
	return cooldown
end

function Swirl:Setup(icon, aura, config, module)
	if not aura or not aura.duration or aura.duration <= 0 then
		self:Reset(icon)
		return
	end
	local cooldown = self:Attach(icon, module, config)
	if not cooldown then
		return
	end

	local duration = aura.duration or 0
	if duration <= 0 then
		self:Reset(icon)
		return
	end

	local hideExternal = module and module.auraTimer and module.auraTimer.general and module.auraTimer.general.hideExternalTimer
	icon.noCooldownCount = hideExternal or nil

	ApplyCooldownConfig(icon, config)
	local start = (aura.expirationTime or 0) - duration
	StartCooldown(cooldown, start, duration)
	cooldown:Show()
	icon.swirlCooldownActive = true
end

function Swirl:Update(icon, config)
	ApplyCooldownConfig(icon, config)
end

function Swirl:Reset(icon)
	if not icon then
		return
	end
	local cooldown = icon.swirlCooldown
	if cooldown then
		ClearCooldown(cooldown)
		cooldown:Hide()
	end
	icon.swirlCooldownActive = nil
end

function Swirl:Detach(icon)
	if not icon or not icon.swirlCooldown then
		icon.swirlCooldownActive = nil
		return
	end
	self:Reset(icon)
	icon.swirlCooldown:SetParent(nil)
	icon.swirlCooldown = nil
end
