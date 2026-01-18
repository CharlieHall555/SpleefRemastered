local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local Agent , Block , Map , Layer, VectorUtil


local Pathfinding = require(ModuleDirectory.Systems.Agent.Pathfinding)
local CharacterGeneration  = require(ModuleDirectory.Systems.Agent.CharacterGeneration)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)

local AgentMovement = {}

local function chooseDestination(agent : Agent.Agent) : Vector2

    local snappedToGrid = agent:snapToGrid()

    local currentLayer = agent:getLayerCurrentlyOn()

    if not currentLayer then
        warn("no layer")
        return
    end

    local bestScoringBlock : Block.Block = nil
    local bestScore = -math.huge
    
    local relevantScores = TileScoring.getScoresAround(
        snappedToGrid.layerIndex,
        snappedToGrid.layerPosition,
        agent.config.wanderRadius
    )

    for sOffsetPos , score in relevantScores.tiles do
        
        local fallingPenalty = 1
        local offsetPos = VectorUtil.deserializeVector2(sOffsetPos)
        local scoreLayerPos = snappedToGrid.layerPosition + offsetPos
        local eachBlock = currentLayer:getBlock(scoreLayerPos)

        if eachBlock and eachBlock.falling then
            fallingPenalty = 0.05    
        end
    
        local proxScore = score.prox
        local connectedScore = score.connected

        if agent.threatend then
            proxScore *= agent.config.underThreatProxMultiplier
        end

        local totalScore = (proxScore + connectedScore) * fallingPenalty

        if totalScore > bestScore then
            bestScore = totalScore
            bestScoringBlock = scoreLayerPos
        end

    end

    return bestScoringBlock.layerPosition

end

local function onInvalidPath(agent : Agent.Agent)
    
end

function AgentMovement.agentStartWander(agent : Agent.Agent)
    AgentMovement.newSubgoal(agent)
end

function AgentMovement.agentCompletedWanderStep(agent : Agent.Agent , reached : boolean)
    --choose goal and start wander to it
end

function AgentMovement.agentCompletedFullWander(agent : Agent.Agent)
    
end

function AgentMovement.newSubgoal(agent : Agent.Agent)
    

end


function AgentMovement.init()
    Agent = require(ModuleDirectory.Systems.Agent.Agent)
    Block = require(ModuleDirectory.Systems.Map.Block)
    Layer = require(ModuleDirectory.Systems.Map.Layer)
	Map = require(ModuleDirectory.Systems.Map.Map)
    VectorUtil = require(ModuleDirectory.VectorUtil)
end

return AgentMovement