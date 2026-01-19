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

    return bestScoringBlock

end

local function onInvalidPath(agent : Agent.Agent)
    warn("Agent ", agent.id, " failed to find path, stopping wander")
    agent.wanderActive = false
    agent.movementState.currentPath = nil
    agent.movementState.waypointN = 0
end

function AgentMovement.resetWander(agent : Agent.Agent)
    -- Cancel current movement
    if agent.movementState.currentPath then
        Pathfinding.discardPath(agent.movementState.currentPath.pathId)
    end
    
    agent.movementState.currentPath = nil
    agent.movementState.waypointN = 0
    
    -- Start new wander if still active
    if agent.wanderActive then
        AgentMovement.agentStartWander(agent)
    end
end

function AgentMovement.agentStartWander(agent : Agent.Agent)
    local currentLayer = agent:getLayerCurrentlyOn()
    if not currentLayer then
        warn("[AgentMovement] Agent has no current layer")
        return
    end
    
    local snappedToGrid = agent:snapToGrid()
    if not snappedToGrid then
        warn("Agent failed to snap to grid")
        return
    end
    
    -- Choose destination
    local targetPos = chooseDestination(agent)
    if not targetPos then
        warn("Agent failed to choose destination")
        return
    end
    
    -- Find path
    local path = Pathfinding.findPath(currentLayer, snappedToGrid.layerPosition, targetPos)
    if not path then
        onInvalidPath(agent)
        return
    end
    
    -- Store path and start moving
    agent.movementState.currentPath = path
    agent.movementState.waypointN = 1
    
    -- Move to first waypoint
    if path.waypoints[1] then
        agent.humanoid:MoveTo(path.waypoints[1]:getWorldPosition())
    end
end

function AgentMovement.agentCompletedWanderStep(agent : Agent.Agent , reached : boolean)
    if not agent.wanderActive then
        return
    end
    
    -- If failed to reach waypoint, reset wander
    if not reached then
        AgentMovement.resetWander(agent)
        return
    end
    
    local currentPath = agent.movementState.currentPath
    if not currentPath then
        return
    end
    
    -- Advance to next waypoint
    agent.movementState.waypointN += 1
    local nextWaypoint = currentPath.waypoints[agent.movementState.waypointN]
    
    if nextWaypoint then
        -- Move to next waypoint
        agent.humanoid:MoveTo(nextWaypoint:getWorldPosition())
    else
        -- Path complete
        AgentMovement.agentCompletedFullWander(agent)
    end
end

function AgentMovement.agentCompletedFullWander(agent : Agent.Agent)
    -- Discard completed path
    if agent.movementState.currentPath then
        Pathfinding.discardPath(agent.movementState.currentPath.pathId)
    end
    
    agent.movementState.currentPath = nil
    agent.movementState.waypointN = 0
    
    if not agent.wanderActive then
        return
    end
    
    -- If threatened, restart immediately. Otherwise wait wanderTime
    if agent.threatened then
        AgentMovement.agentStartWander(agent)
    else
        task.wait(agent.config.wanderTime)
        if agent.wanderActive then
            AgentMovement.agentStartWander(agent)
        end
    end
end

function AgentMovement.init()
    Agent = require(ModuleDirectory.Systems.Agent.Agent)
    Block = require(ModuleDirectory.Systems.Map.Block)
    Layer = require(ModuleDirectory.Systems.Map.Layer)
	Map = require(ModuleDirectory.Systems.Map.Map)
    VectorUtil = require(ModuleDirectory.VectorUtil)
end

return AgentMovement