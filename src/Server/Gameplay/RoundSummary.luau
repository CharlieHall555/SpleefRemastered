local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockDestructionTracker = require(ModuleDirectory.Gameplay.BlockDestructionTracker)
local PlayerDeathDetector = require(ModuleDirectory.Round.PlayerDeathDetector)

local RoundSummary = {}

export type endSummary = {
    timeAlive : number,
    blocksDestroyed : number,
    place : number
}

function RoundSummary.onRoundEnd()
    
end


return RoundSummary