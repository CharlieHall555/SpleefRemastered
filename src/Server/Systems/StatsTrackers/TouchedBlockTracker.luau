local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Systems.Gameplay.ServerHitBoxManager)

local TouchedBlockTracker = {}

export type TouchRecord = {
    blockId: number,
    time: number
}

local lastTouchedBlocks: { [Player]: { TouchRecord } } = {}
local MAX_TRACKED = 5

function TouchedBlockTracker.init()
    ServerHitBoxManager.setUpCallback("Block", function(player: Player, otherPart: Instance)
        local touchedBlockId = otherPart:GetAttribute("Id")
        if typeof(touchedBlockId) ~= "number" then
            return
        end

        if not lastTouchedBlocks[player] then
            lastTouchedBlocks[player] = {}
        end

        table.insert(lastTouchedBlocks[player], 1, {
            blockId = touchedBlockId :: number,
            time = time()
        })

        if #lastTouchedBlocks[player] > MAX_TRACKED then
            table.remove(lastTouchedBlocks[player], #lastTouchedBlocks[player])
        end
    end)
end

function TouchedBlockTracker.getLastTouchedBlocks(player: Player): { TouchRecord }
    return lastTouchedBlocks[player] or {}
end

function TouchedBlockTracker.reset()
    lastTouchedBlocks = {}
end

return TouchedBlockTracker
