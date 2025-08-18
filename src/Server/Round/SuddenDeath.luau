local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Map = require(ModuleDirectory.Map.Map)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)

local SuddenDeath = {}

function SuddenDeath.start(map: Map.Map): nil
    local delay = Config.START_SUDDEN_DEATH_DELAY or Config.SUDDEN_DEATH_DELAY
    local minDelay = Config.MIN_SUDDEN_DEATH_DELAY or 1
    local delayDecrease = Config.SUDDEN_DEATH_DELAY_DECREASE or 0

    local blocksChosen = Config.START_SUDDEN_DEATH_BLOCKS_CHOSEN or Config.SUDDEN_DEATH_BLOCKS_CHOSEN or 1
    local maxBlocks = Config.MAX_SUDDEN_DEATH_BLOCKS_CHOSEN or blocksChosen
    local blocksIncrease = Config.SUDDEN_DEATH_BLOCKS_CHOSEN_INCREASE or 0

    task.spawn(function()
        while RoundSystem.getState() == "ACTIVE" do
            task.wait(delay)

            for _ = 1, blocksChosen do
                SuddenDeath.destroyRandomBlock(map)
            end

            -- Gradually speed up and increase destruction, bounded by config
            if delayDecrease > 0 then
                delay = math.max(minDelay, delay - delayDecrease)
            end
            if blocksIncrease > 0 then
                blocksChosen = math.min(maxBlocks, blocksChosen + blocksIncrease)
            end
        end
    end)
end

function SuddenDeath.destroyRandomBlock(map: Map.Map): nil
    local randomLayer = map:getRandomLayer()
    if not randomLayer then
        return
    end
    local randomBlock = randomLayer:getRandomBlock()
    if randomBlock then
        BlockFactory.slowDestroy(randomBlock)
    end
end

-- Suggestions:
-- - Consider moving random selection logic into Map for testability (e.g., map:destroyRandomBlocks(n)).
-- - If multiple maps exist, accept a MapManager to pick the active map rather than passing map around.

return SuddenDeath