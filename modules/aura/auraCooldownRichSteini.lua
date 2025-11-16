if not NotPlater then
    return
end

local Rich = {}
NotPlater.AuraCooldownRichSteini = Rich
local CreateFrame = CreateFrame
local GetTime = GetTime
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local QUADRANT_VERTICAL = {true, false, true, false}

local function EnsureOverlayLayout(holder)
    local icon = holder.icon
    if not icon then
        return
    end
    local width = icon:GetWidth()
    local height = icon:GetHeight()
    if not width or not height or width <= 0 or height <= 0 then
        return
    end
    if holder.lastWidth == width and holder.lastHeight == height and holder.lastFillMode == holder.fillMode then
        return
    end
    holder.lastWidth = width
    holder.lastHeight = height
    holder.lastFillMode = holder.fillMode
    holder.halfWidth = width / 2
    holder.halfHeight = height / 2
    local anchors = holder.fillMode and {
        {"TOPRIGHT", "CENTER", holder.halfWidth, holder.halfHeight},
        {"BOTTOMRIGHT", "CENTER", holder.halfWidth, -holder.halfHeight},
        {"BOTTOMLEFT", "CENTER", -holder.halfWidth, -holder.halfHeight},
        {"TOPLEFT", "CENTER", -holder.halfWidth, holder.halfHeight},
    } or {
        {"BOTTOMLEFT", "CENTER", 0, 0},
        {"TOPLEFT", "CENTER", 0, 0},
        {"TOPRIGHT", "CENTER", 0, 0},
        {"BOTTOMRIGHT", "CENTER", 0, 0},
    }
    for index, overlay in ipairs(holder.overlays) do
        overlay:ClearAllPoints()
        local anchor = anchors[index]
        overlay:SetPoint(anchor[1], holder, anchor[2], anchor[3], anchor[4])
        overlay:SetWidth(holder.halfWidth)
        overlay:SetHeight(holder.halfHeight)
    end
end

local function ApplyOverlayState(holder, progress, fillMode)
    local overlays = holder.overlays
    if not overlays then
        return
    end
    local clamped = math_min(math_max(progress, 0), 0.999999)
    local scaled = clamped * 4
    local base = math_floor(scaled)
    local quad = base + 1
    if quad > 4 then
        quad = 4
    end
    local sub = scaled - base
    local halfWidth = holder.halfWidth or 0
    local halfHeight = holder.halfHeight or 0
    for index, overlay in ipairs(overlays) do
        local showOverlay = false
        local fraction = 1
        local partial = false
        if fillMode then
            if index < quad then
                showOverlay = true
                fraction = 1
            elseif index == quad then
                showOverlay = sub > 0
                fraction = sub
                partial = true
            else
                showOverlay = false
            end
        else
            if index > quad then
                showOverlay = true
                fraction = 1
            elseif index == quad then
                showOverlay = (1 - sub) > 0
                fraction = 1 - sub
                partial = true
            else
                showOverlay = false
            end
        end
        if showOverlay and fraction > 0 then
            overlay:SetAlpha(1)
            overlay:Show()
            if QUADRANT_VERTICAL[index] then
                overlay:SetWidth(halfWidth)
                local targetHeight = halfHeight * fraction
                if not partial then
                    targetHeight = halfHeight
                end
                if targetHeight <= 0.0001 then
                    overlay:Hide()
                else
                    overlay:SetHeight(targetHeight)
                end
            else
                overlay:SetHeight(halfHeight)
                local targetWidth = halfWidth * fraction
                if not partial then
                    targetWidth = halfWidth
                end
                if targetWidth <= 0.0001 then
                    overlay:Hide()
                else
                    overlay:SetWidth(targetWidth)
                end
            end
        else
            overlay:Hide()
        end
    end
end

local function HolderOnUpdate(holder)
    if not holder.active then
        return
    end
    local icon = holder.icon
    if not icon or not icon:IsShown() or not icon:IsVisible() then
        Rich:Reset(icon)
        return
    end
    EnsureOverlayLayout(holder)
    local start = holder.start
    local duration = holder.duration
    if not start or not duration or duration <= 0 then
        Rich:Reset(icon)
        return
    end
    local elapsed = GetTime() - start
    if elapsed >= duration then
        Rich:Reset(icon)
        return
    end
    local progress = elapsed / duration
    ApplyOverlayState(holder, progress, holder.fillMode)
    holder:Show()
end

function Rich:Attach(icon)
    if icon.richSteiniCooldownHolder then
        local holder = icon.richSteiniCooldownHolder
        holder:SetFrameStrata(icon:GetFrameStrata())
        holder:SetFrameLevel((icon:GetFrameLevel() or 0) + 3)
        holder.icon = icon
        return holder
    end
    local holder = CreateFrame("Frame", nil, icon)
    holder:SetAllPoints(icon)
    holder:SetFrameStrata(icon:GetFrameStrata())
    holder:SetFrameLevel((icon:GetFrameLevel() or 0) + 3)
    holder:Hide()
    holder.icon = icon
    holder.overlays = {}
    for index = 1, 4 do
        local overlay = holder:CreateTexture(nil, "OVERLAY")
        overlay:SetTexture("Interface\\Buttons\\WHITE8x8")
        overlay:SetVertexColor(0, 0, 0, 0.65)
        overlay:Hide()
        holder.overlays[index] = overlay
    end
    icon.richSteiniCooldownHolder = holder
    return holder
end

function Rich:Setup(icon, aura, config, module)
    if not aura or not aura.duration or aura.duration <= 0 then
        self:Reset(icon)
        return
    end
    local holder = self:Attach(icon)
    if not holder then
        return
    end
    holder.icon = icon
    holder.start = (aura.expirationTime or 0) - (aura.duration or 0)
    holder.duration = aura.duration
    holder.fillMode = (config and config.invertSwipe) or false
    holder.lastWidth = nil
    holder.lastHeight = nil
    holder.active = true
    holder:SetFrameStrata(icon:GetFrameStrata())
    holder:SetFrameLevel((icon:GetFrameLevel() or 0) + 3)
    holder:SetScript("OnUpdate", HolderOnUpdate)
    holder:Show()
    HolderOnUpdate(holder)
    local hideExternal = module and module.auraTimer and module.auraTimer.general and module.auraTimer.general.hideExternalTimer
    icon.noCooldownCount = hideExternal or nil
    icon.richSteiniCooldownActive = true
end

function Rich:Update(icon, config)
    local holder = icon and icon.richSteiniCooldownHolder
    if not holder then
        return
    end
    holder.fillMode = (config and config.invertSwipe) or false
    holder:SetFrameStrata(icon:GetFrameStrata())
    holder:SetFrameLevel((icon:GetFrameLevel() or 0) + 3)
    if holder.active then
        HolderOnUpdate(holder)
    end
end

function Rich:Reset(icon)
    if not icon then
        return
    end
    local holder = icon.richSteiniCooldownHolder
    if holder then
        holder.active = nil
        holder.start = nil
        holder.duration = nil
        holder.fillMode = nil
        holder:SetScript("OnUpdate", nil)
        holder:Hide()
        if holder.overlays then
            for _, overlay in ipairs(holder.overlays) do
                overlay:Hide()
                overlay:SetAlpha(1)
            end
        end
    end
    icon.richSteiniCooldownActive = nil
end

function Rich:Detach(icon)
    if not icon then
        return
    end
    if icon.richSteiniCooldownHolder then
        self:Reset(icon)
        icon.richSteiniCooldownHolder:SetParent(nil)
        icon.richSteiniCooldownHolder = nil
    end
end