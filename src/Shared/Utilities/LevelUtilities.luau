local LevelUtilities = {}

-- Config for the curve
local LEVEL_BASE = 80
local LEVEL_EXP  = 1.45
local LEVEL_STEP = 10
local MAX_LEVEL  = 100

function LevelUtilities.xpToNextLevel(level: number): number
    return math.floor(LEVEL_BASE * (level ^ LEVEL_EXP) + LEVEL_STEP * level)
end

return LevelUtilities
