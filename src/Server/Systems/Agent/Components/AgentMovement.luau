local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local Agent , Block , Map , Layer, VectorUtil


local Pathfinding = require(ModuleDirectory.Systems.Agent.Pathfinding)
local CharacterGeneration  = require(ModuleDirectory.Systems.Agent.CharacterGeneration)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)
local AgentAnimations = require(ModuleDirectory.Systems.Agent.AgentAnimations)

local AgentMovement = {}

-- Mapping: blockId -> { [agentId] = true }
-- Tracks which agents have this block in their current path
local blockToAgents: { [any]: { [string]: boolean } } = {}

local function getForward2D(agent: Agent.Agent): Vector2
    local look = agent.model.PrimaryPart.CFrame.LookVector
    return Vector2.new(look.X, look.Z).Unit
end

local function registerPathBlocks(agent: Agent.Agent, path: Pathfinding.path)
    if not path or not path.waypoints then
        return
    end
    
    for _, block in path.waypoints do
        if block and block.id then
            if not blockToAgents[block.id] then
                blockToAgents[block.id] = {}
            end
            blockToAgents[block.id][agent.id] = true
        end
    end
end

local function unregisterPathBlocks(agent: Agent.Agent, path: Pathfinding.path)
    if not path or not path.waypoints then
        return
    end
    
    for _, block in path.waypoints do
        if block and block.id and blockToAgents[block.id] then
            blockToAgents[block.id][agent.id] = nil
            
            -- Clean up empty tables
            local hasAny = false
            for _ in blockToAgents[block.id] do
                hasAny = true
                break
            end
            if not hasAny then
                blockToAgents[block.id] = nil
            end
        end
    end
end

local function chooseDestination(agent : Agent.Agent) : Vector2

    local snappedToGrid = agent:snapToGrid()
    local currentLayer = agent:getLayerCurrentlyOn()

    if not currentLayer then
        warn("no layer")
        return
    end

    local bestScoringBlock : Vector2? = nil
    local bestScore = -math.huge

    local forwardDir = getForward2D(agent)

    local relevantScores = TileScoring.getScoresAround(
        snappedToGrid.layerIndex,
        snappedToGrid.layerPosition,
        agent.config.wanderRadius
    )

    for sOffsetPos, score in relevantScores.tiles do

        local offsetPos = VectorUtil.deserializeVector2(sOffsetPos)
        local scoreLayerPos = snappedToGrid.layerPosition + offsetPos
        local eachBlock = currentLayer:getBlock(scoreLayerPos)

        -- Falling penalty
        local fallingPenalty = 1
        if eachBlock and eachBlock.falling then
            fallingPenalty = 0.05
        end

        -- Base scores
        local proxScore = score.prox * agent.config.movementProximityWeight
        local connectedScore = score.connected * agent.config.movementConnectionWeight

        if agent.threatend then
            proxScore *= agent.config.underThreatProxMultiplier
        end

        local dirToTile = (offsetPos.Magnitude > 0)
            and offsetPos.Unit
            or Vector2.zero

        local dot = forwardDir:Dot(dirToTile)
        -- dot ∈ [-1, 1] → clamp to [0, 1]
        local forwardFactor = math.clamp(dot, 0, 1)

        local forwardScore =
            (forwardFactor ^ agent.config.forwardBiasPower)
            * agent.config.forwardBiasWeight

        local noise = (math.random() - 0.5) * 2 * agent.config.noiseMagnitude

        local totalScore =
            ((proxScore + connectedScore + forwardScore) * fallingPenalty)
            + noise

        if totalScore > bestScore then
            bestScore = totalScore
            bestScoringBlock = scoreLayerPos
        end
    end

    return bestScoringBlock
end

local function onInvalidPath(agent : Agent.Agent)
    
    warn("Agent ", agent.id, " failed to find path, waiting before retry")
    agent.movementState.currentPath = nil
    agent.movementState.waypointN = 0
    AgentAnimations.idle(agent)
    
    -- Wait idle time before retrying
    task.wait(agent.config.wanderTime)
    if agent.wanderActive then
        AgentMovement.agentStartWander(agent)
    end
end

function AgentMovement.resetWander(agent : Agent.Agent)
    if agent == nil or agent.alive == false then
        return 
    end
    -- Cancel current movement
    if agent.movementState.currentPath then
        unregisterPathBlocks(agent, agent.movementState.currentPath)
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
    if agent == nil or agent.alive == false then
        return 
    end
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
    
    -- Register path blocks
    registerPathBlocks(agent, path)
    
    -- Move to first waypoint
    if path.waypoints[1] then
        AgentAnimations.running(agent)
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
        AgentAnimations.idle(agent)
        AgentMovement.agentCompletedFullWander(agent)
    end
end

function AgentMovement.agentCompletedFullWander(agent : Agent.Agent)
    if agent == nil or agent.alive == false then
        return 
    end
    -- Discard completed path
    if agent.movementState.currentPath then
        unregisterPathBlocks(agent, agent.movementState.currentPath)
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

function AgentMovement.onBlockDestroyed(blockId: any)
    local affectedAgents = blockToAgents[blockId]
    if not affectedAgents then
        return
    end
    
    -- Get Agent module to look up agents
    local AgentModule = Agent or require(ModuleDirectory.Systems.Agent.Agent)
    
    -- Reset wander for all agents using this block
    for agentId in affectedAgents do
        local agent = AgentModule.getById(agentId)
        if agent and agent.alive and agent.wanderActive then
            print("[AgentMovement] Block", blockId, "destroyed - resetting wander for agent", agentId)
            AgentMovement.resetWander(agent)
        end
    end
    
    -- Clean up the mapping
    blockToAgents[blockId] = nil
end

function AgentMovement.init()
    Agent = require(ModuleDirectory.Systems.Agent.Agent)
    Block = require(ModuleDirectory.Systems.Map.Block)
    Layer = require(ModuleDirectory.Systems.Map.Layer)
	Map = require(ModuleDirectory.Systems.Map.Map)
    VectorUtil = require(ModuleDirectory.VectorUtil)
end

return AgentMovement