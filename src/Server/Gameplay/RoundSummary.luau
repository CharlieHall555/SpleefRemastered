local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockDestructionTracker = require(ModuleDirectory.Gameplay.BlockDestructionTracker)
local PlayerDeathDetector = require(ModuleDirectory.Round.PlayerDeathDetector)
local EliminationTracker = require(ModuleDirectory.Gameplay.EliminationTracker)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local RoundSummary = {}

export type endSummary = {
	timeAlive: number,
	blocksDestroyed: number,
	elininations: number,
}

function RoundSummary.onRoundEnd(round: RoundSystem.Round)
	for _, eachPlayer in round.startingPlayers do
		if eachPlayer and eachPlayer.Parent then
			local newRecord : endSummary = {}
            local s
			s , newRecord.timeAlive = pcall(function()
                return PlayerDeathDetector.getDeathTime(eachPlayer) - round.startTime
            end)
            if s == false then
                newRecord.timeAlive = 0
            end
            
            newRecord.blocksDestroyed = (#BlockDestructionTracker.getBlocksDestroyedByPlayer(eachPlayer)) or 0
            newRecord.elininations = (#EliminationTracker.getElimationsFor(eachPlayer)) or 0 

            RemoteEventHandler.FireOnClient(eachPlayer , "ROUND_SUMMARY" , newRecord)

		end
	end
end

return RoundSummary
