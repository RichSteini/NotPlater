local Swirl = {}
NotPlater.AuraCooldownSwirl = Swirl

local function HolderOnUpdate(holder)
    if not holder.active then
        return
    end
    local icon = holder.icon
    if not icon or not icon:IsShown() or not icon:IsVisible() then
        holder.active = nil
        holder:SetScript("OnUpdate", nil)
        holder:Hide()
        return
    end
    local left, bottom = icon:GetLeft(), icon:GetBottom()
    local iconScale = icon:GetEffectiveScale() or 1
    local uiScale = UIParent:GetEffectiveScale() or 1
    if left and bottom then
        left = left * iconScale / uiScale
        bottom = bottom * iconScale / uiScale
        if holder.lastLeft ~= left or holder.lastBottom ~= bottom then
            holder:ClearAllPoints()
            holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
            holder.lastLeft = left
            holder.lastBottom = bottom
        end
    end
    local width = icon:GetWidth() * iconScale / uiScale
    local height = icon:GetHeight() * iconScale / uiScale
    if width and height then
        if holder.lastWidth ~= width or holder.lastHeight ~= height then
            holder:SetSize(width, height)
            if holder.cooldown then
                holder.cooldown:UpdateSizes(width, height)
            end
            holder.lastWidth = width
            holder.lastHeight = height
        end
    end
    local ikonLevel = (icon:GetFrameLevel() or 0) + 3
    if holder.lastLevel ~= ikonLevel then
        holder:SetFrameLevel(ikonLevel)
        if holder.cooldown then
            holder.cooldown:SetFrameLevel(ikonLevel)
        end
        holder.lastLevel = ikonLevel
    end
    local strata = icon:GetFrameStrata() or "MEDIUM"
    if holder.lastStrata ~= strata then
        holder:SetFrameStrata(strata)
        if holder.cooldown then
            holder.cooldown:SetFrameStrata(strata)
        end
        holder.lastStrata = strata
    end
    -- Custom edge update
    if holder.start and holder.duration then
        local progress = (GetTime() - holder.start) / holder.duration
        if progress >= 1 then
            Swirl:Reset(icon)
            return
        end
        local angle = progress * 360
        if holder.reverse then
            angle = -angle
        end
        angle = angle - 90
        holder.edgeTexture:SetRotation(math.rad(angle))
    end
    holder:Show()
end

function Swirl:Attach(icon)
    if icon.swirlCooldownHolder then
        return
    end
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetFrameStrata(icon:GetFrameStrata())
    holder:SetFrameLevel(icon:GetFrameLevel() + 3)
    holder:Hide()
    local cooldown = CreateFrame("Frame", nil, holder)
    cooldown:SetAllPoints()
    cooldown:SetFrameLevel(holder:GetFrameLevel() + 1)
    cooldown:Hide()
    -- Left half
    cooldown.left_half = CreateFrame("Frame", nil, cooldown)
    cooldown.left_half:SetPoint("TOPLEFT")
    cooldown.left_half:SetPoint("BOTTOMLEFT")
    if cooldown.left_half.SetClipsChildren then
        cooldown.left_half:SetClipsChildren(true)
    end
    cooldown.left_rotator = cooldown.left_half:CreateTexture(nil, "BACKGROUND")
    cooldown.left_rotator:SetBlendMode("BLEND")
    cooldown.left_ag = cooldown.left_rotator:CreateAnimationGroup()
    cooldown.left_rot = cooldown.left_ag:CreateAnimation("Rotation")
    cooldown.left_rot:SetOrigin("RIGHT", 0, 0)
    cooldown.left_ag:SetScript("OnFinished", function()
        cooldown.left_rotator:SetRotation(0)
    end)
    -- Right half
    cooldown.right_half = CreateFrame("Frame", nil, cooldown)
    cooldown.right_half:SetPoint("TOPRIGHT")
    cooldown.right_half:SetPoint("BOTTOMRIGHT")
    if cooldown.right_half.SetClipsChildren then
        cooldown.right_half:SetClipsChildren(true)
    end
    cooldown.right_rotator = cooldown.right_half:CreateTexture(nil, "BACKGROUND")
    cooldown.right_rotator:SetBlendMode("BLEND")
    cooldown.right_ag = cooldown.right_rotator:CreateAnimationGroup()
    cooldown.right_rot = cooldown.right_ag:CreateAnimation("Rotation")
    cooldown.right_rot:SetOrigin("LEFT", 0, 0)
    cooldown.right_ag:SetScript("OnFinished", function()
        cooldown.right_rotator:SetRotation(0)
        cooldown:SetAlpha(0)
    end)
    -- Edge texture
    holder.edgeTexture = holder:CreateTexture(nil, "OVERLAY")
    holder.edgeTexture:SetTexture("Interface\\Cooldown\\edge")
    holder.edgeTexture:SetBlendMode("ADD")
    holder.edgeTexture:SetPoint("TOPLEFT", holder, "TOPLEFT", -3, 3)
    holder.edgeTexture:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 3, -3)
    -- Update sizes function
    function cooldown:UpdateSizes(w, h)
        local half_w = w / 2
        local rot_w = w
        local rot_h = h * 2
        self.left_half:SetWidth(half_w)
        self.left_half:SetHeight(h)
        self.left_rotator:SetSize(rot_w, rot_h)
        self.left_rotator:ClearAllPoints()
        self.left_rotator:SetPoint("RIGHT", self.left_half, "RIGHT", 0, 0)
        self.left_rotator:SetPoint("TOP", self.left_half, "TOP", 0, -h)
        self.right_half:SetWidth(half_w)
        self.right_half:SetHeight(h)
        self.right_rotator:SetSize(rot_w, rot_h)
        self.right_rotator:ClearAllPoints()
        self.right_rotator:SetPoint("LEFT", self.right_half, "LEFT", 0, 0)
        self.right_rotator:SetPoint("TOP", self.right_half, "TOP", 0, -h)
    end
    holder.cooldown = cooldown
    icon.swirlCooldownHolder = holder
end

function Swirl:Setup(icon, aura, config, module)
    if not aura or not aura.duration or aura.duration <= 0 then
        self:Reset(icon)
        return
    end
    self:Attach(icon)
    local holder = icon.swirlCooldownHolder
    if not holder then
        return
    end
    local cooldown = holder.cooldown
    if not cooldown then
        return
    end
    holder.icon = icon
    holder:SetFrameStrata(icon:GetFrameStrata())
    holder:SetFrameLevel(icon:GetFrameLevel() + 3)
    holder.lastLeft = nil
    holder.lastBottom = nil
    holder.lastWidth = nil
    holder.lastHeight = nil
    holder.active = true
    holder:SetScript("OnUpdate", HolderOnUpdate)
    local reverse = config and config.invertSwipe or false
    holder.reverse = reverse
    local hideExternal = module and module.auraTimer and module.auraTimer.general and module.auraTimer.general.hideExternalTimer
    -- noCooldownCount for external timers like OmniCC
    icon.noCooldownCount = hideExternal or nil
    local texture
    if NotPlater.auraSwipeTextures then
        texture = (config and config.texture and NotPlater.auraSwipeTextures[config.texture]) or NotPlater.auraSwipeTextures["Texture 3"]
    end
    if texture then
        cooldown.left_rotator:SetTexture(texture)
        cooldown.right_rotator:SetTexture(texture)
        cooldown.left_rotator:SetVertexColor(0, 0, 0, 0.6)
        cooldown.right_rotator:SetVertexColor(0, 0, 0, 0.6)
    else
        cooldown.left_rotator:SetTexture("Interface\\Buttons\\WHITE8x8")
        cooldown.right_rotator:SetTexture("Interface\\Buttons\\WHITE8x8")
        cooldown.left_rotator:SetVertexColor(0, 0, 0, 0.6)
        cooldown.right_rotator:SetVertexColor(0, 0, 0, 0.6)
    end
    local duration = aura.duration or 0
    local start = (aura.expirationTime or 0) - duration
    holder.start = start
    holder.duration = duration
    -- Setup animations
    local initial_angle = reverse and 180 or 0
    local degrees = reverse and -180 or 180
    local first_rot, second_rot, first_ag, second_ag
    if not reverse then
        first_rot = cooldown.right_rot
        second_rot = cooldown.left_rot
        first_ag = cooldown.right_ag
        second_ag = cooldown.left_ag
    else
        first_rot = cooldown.left_rot
        second_rot = cooldown.right_rot
        first_ag = cooldown.left_ag
        second_ag = cooldown.right_ag
    end
    first_rot:SetDegrees(degrees)
    first_rot:SetDuration(duration / 2)
    first_rot:SetStartDelay(0)
    first_rot:SetSmoothing("NONE")
    second_rot:SetDegrees(degrees)
    second_rot:SetDuration(duration / 2)
    second_rot:SetStartDelay(duration / 2)
    second_rot:SetSmoothing("NONE")
    -- Reset rotations
    cooldown.left_rotator:SetRotation(math.rad(initial_angle))
    cooldown.right_rotator:SetRotation(math.rad(initial_angle))
    cooldown:SetAlpha(1)
    holder.edgeTexture:Show()
    -- Play animations
    first_ag:Play()
    second_ag:Play()
    holder:Show()
    cooldown:Show()
    icon.swirlCooldownActive = true
end

function Swirl:Update()
    -- Custom animation is handled in OnUpdate
end

function Swirl:Reset(icon)
    if icon.swirlCooldownHolder then
        local holder = icon.swirlCooldownHolder
        holder.active = nil
        holder:SetScript("OnUpdate", nil)
        holder:Hide()
        holder.start = nil
        holder.duration = nil
        holder.reverse = nil
        if holder.cooldown then
            holder.cooldown:SetAlpha(0)
            holder.cooldown.left_ag:Stop()
            holder.cooldown.right_ag:Stop()
            holder.cooldown.left_rotator:SetRotation(0)
            holder.cooldown.right_rotator:SetRotation(0)
            holder.cooldown:Hide()
        end
        if holder.edgeTexture then
            holder.edgeTexture:Hide()
        end
    end
    icon.swirlCooldownActive = nil
end

function Swirl:Detach(icon)
    if icon.swirlCooldownHolder then
        icon.swirlCooldownHolder.active = nil
        icon.swirlCooldownHolder:SetScript("OnUpdate", nil)
        if icon.swirlCooldownHolder.cooldown then
            icon.swirlCooldownHolder.cooldown:Hide()
            icon.swirlCooldownHolder.cooldown:SetParent(nil)
            icon.swirlCooldownHolder.cooldown = nil
        end
        if icon.swirlCooldownHolder.edgeTexture then
            icon.swirlCooldownHolder.edgeTexture:SetParent(nil)
            icon.swirlCooldownHolder.edgeTexture = nil
        end
        icon.swirlCooldownHolder.icon = nil
        icon.swirlCooldownHolder:Hide()
        icon.swirlCooldownHolder:SetParent(nil)
        icon.swirlCooldownHolder = nil
    end
    icon.swirlCooldownActive = nil
end