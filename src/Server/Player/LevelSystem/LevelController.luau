local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local LevelController = {} -- public facing api

local MAX_XP = 5000

-- Grants XP, carrying overflow across levels.
-- On each level up, XP for the new level starts from 0, and any remaining overflow continues.
function LevelController.giveXp(player: Player, xpAmount: number): nil

    xpAmount = math.min(MAX_XP , xpAmount)

    if not player or type(xpAmount) ~= "number" or xpAmount <= 0 then
        return
    end

    local level = PlayerData.getLevel(player) or 1
    local xp = PlayerData.getXP(player) or 0

    local overflow = xp + xpAmount
    local newLevel = level
    local safety = 0

    while true do
        local needed = LevelUtilities.xpToNextLevel(newLevel)
        if overflow >= needed then
            overflow -= needed
            newLevel += 1
            safety += 1
            if safety > 100 then
                break
            end
        else
            break
        end
    end

    if newLevel ~= level then
        PlayerData.setLevel(player, newLevel) -- fires client once
    end
    PlayerData.setXP(player, overflow)
end

return LevelController
