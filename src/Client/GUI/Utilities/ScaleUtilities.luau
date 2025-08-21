local ScaleUtilities = {}

function ScaleUtilities.scaleForTargetOffset(currentOffsetPx: number, targetOffsetPx: number, currentScale: number): number
    local cam = workspace.CurrentCamera
    if not cam then
        return currentScale
    end

    -- Parent pixel dimension we're scaling against (Y by default).
    local parentPixels = cam.ViewportSize.Y
    if parentPixels <= 0 then
        return currentScale
    end

    local newScale = (targetOffsetPx - currentOffsetPx) / parentPixels

    -- Guard against NaN/inf
    if newScale ~= newScale or newScale == math.huge or newScale == -math.huge then
        return currentScale
    end

    return newScale
end

return ScaleUtilities