local TextUtilities = {}

local SUFFIXES = {
    "K",
    "M",
    "B",
    "T",
    "Q"
}

function TextUtilities.formatCurrency(value: number | string): string
    local num = tonumber(value)
    if not num then
        return tostring(value)
    end

    if math.abs(num) < 1000 then
        return tostring(num)
    end

    local magnitude = math.floor((math.log(math.abs(num)) / math.log(1000)))
    local suffix = SUFFIXES[magnitude] or ("e" .. (magnitude * 3))

    local scaled = num / (1000 ^ magnitude)

    -- floor to 1 decimal place
    local floored = math.floor(scaled * 10) / 10

    return string.format("%.1f%s", floored, suffix)
end

return TextUtilities