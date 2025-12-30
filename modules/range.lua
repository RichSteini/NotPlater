if not NotPlater then return end

local ipairs = ipairs
local unpack = unpack
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local rc = LibStub and LibStub("LibRangeCheck-2.0", true)

local UPDATE_RATE = 0.2 

local function FormatRangeText(rangeConfig, bucket, estimatedRange)
	local formatString = (rangeConfig.text and rangeConfig.text.general and rangeConfig.text.general.format) or "{range}"
	local displayRange = (estimatedRange and tostring(estimatedRange)) or (bucket and bucket.text) or ""

	if not formatString or formatString == "" then
		return displayRange
	end

	if formatString:find("{range}", 1, true) then
		return formatString:gsub("{range}", displayRange)
	end

	return formatString .. displayRange
end

function NotPlater:IsRangeTrackableUnit(unit)
    if not unit then
        return false
    end
    return true
end

function NotPlater:GetEstimatedRange(frame)
    local unit = frame.lastUnitMatch
	if not rc or not self:IsRangeTrackableUnit(unit) or not UnitExists(unit) then
		return nil
	end

	local minRange, maxRange = rc:GetRange(unit)
    if not maxRange or maxRange > 40 then
        return 40
    end

	return maxRange
end

function NotPlater:GetRangeBucket(range)
    local buckets = self.db.profile.range.buckets
    local ordered = {"range10", "range20", "range30", "range40"}
    for _, key in ipairs(ordered) do
        local bucket = buckets[key]
        if bucket and range <= (bucket.max or 0) then
            return bucket, key
        end
    end

    return nil
end

function NotPlater:ConstructRange(frame)
    frame.rangeBar = CreateFrame("StatusBar", "$parentRangeBar", frame.healthBar)
    self:ConstructGeneralisedStatusBar(frame.rangeBar)
    frame.rangeBar:SetMinMaxValues(0, 40)
    frame.rangeText = frame.healthBar:CreateFontString(nil, "OVERLAY")
end

function NotPlater:RangeComponentsOnShow(frame)
    frame.rangeBar:Hide()
    frame.rangeText:Hide()
	frame.rangeElapsed = 0
end

function NotPlater:ConfigureRange(frame)
    local rangeConfig = self.db.profile.range

    self:ConfigureGeneralisedPositionedStatusBar(frame.rangeBar, frame.healthBar, rangeConfig.statusBar)
    frame.rangeBar:SetMinMaxValues(0, (rangeConfig.buckets.range40 and rangeConfig.buckets.range40.max) or 40)

    self:ConfigureGeneralisedText(frame.rangeText, frame.healthBar, rangeConfig.text)
    self:RangeComponentsOnShow(frame)
end

function NotPlater:RangeCheck(frame, elapsed)

    local rangeConfig = self.db.profile.range
    local statusBarEnabled = rangeConfig.statusBar.general.enable
    local textEnabled = rangeConfig.text.general.enable
    if not statusBarEnabled and not textEnabled then
        return
    end

    frame.rangeElapsed = (frame.rangeElapsed or 0) + (elapsed or 0)
    if frame.rangeElapsed < UPDATE_RATE then
        return
    end
    frame.rangeElapsed = 0

    local unit = frame.lastUnitMatch
    if not unit or not self:IsRangeTrackableUnit(unit) then
        frame.rangeBar:Hide()
        frame.rangeText:Hide()
        return
    end

    local estimatedRange = self:GetEstimatedRange(frame)
    if not estimatedRange then
        frame.rangeBar:Hide()
        frame.rangeText:Hide()
        return
    end

	local bucket = self:GetRangeBucket(estimatedRange)
	local bucketsConfig = rangeConfig.buckets or {}
	local bucketColorsEnabled = bucketsConfig.enable ~= false

	if statusBarEnabled then
		frame.rangeBar:Show()
		local maxRange = (rangeConfig.buckets.range40 and rangeConfig.buckets.range40.max) or 40
		frame.rangeBar:SetMinMaxValues(0, maxRange)
        local value = maxRange
        if rangeConfig.statusBar.general.showProgress ~= false then
            value = estimatedRange or maxRange
        end
        frame.rangeBar:SetValue(value)
		local bucketBarColor = bucketColorsEnabled and bucket and (bucket.statusBarColor or bucket.color)
		if bucketBarColor then
			frame.rangeBar:SetStatusBarColor(unpack(bucketBarColor))
			if frame.rangeBar.background then
				frame.rangeBar.background:SetVertexColor(self:GetColor(rangeConfig.statusBar.background.color or bucketBarColor))
			end
		else
            frame.rangeBar:SetStatusBarColor(self:GetColor(rangeConfig.statusBar.general.color or {1, 1, 1, 1}))
        end
    else
        frame.rangeBar:Hide()
    end

	if textEnabled then
		local textValue = FormatRangeText(rangeConfig, bucket, estimatedRange)
		frame.rangeText:SetText(textValue)
		if bucketColorsEnabled and bucket and bucket.textColor then
			frame.rangeText:SetTextColor(unpack(bucket.textColor))
		elseif rangeConfig.text.general.color then
			frame.rangeText:SetTextColor(unpack(rangeConfig.text.general.color))
		end
        frame.rangeText:Show()
    else
        frame.rangeText:Hide()
    end
end
