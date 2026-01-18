local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Agent

local LayerUtilities = require(ModuleDirectory.LayerUtilities)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local LoadedBlocks = require(ModuleDirectory.Systems.Map.LoadedBlocks)
local MapUtilities = require(ModuleDirectory.Systems.Map.MapUtilities)
local AgentAnimations = require(ModuleDirectory.Systems.Agent.AgentAnimations)
local AgentUtil = require(ModuleDirectory.Systems.Agent.AgentUtil)
local ServerConfigurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local Pathfinding = require(ModuleDirectory.Systems.Agent.Pathfinding)
local Block = require(ModuleDirectory.Systems.Map.Block)
local LayerUtilities = require(ModuleDirectory.LayerUtilities)

local PathfindingService = game:GetService("PathfindingService")

local Movement = {}

function Movement.init()
	Agent = require(ModuleDirectory.Systems.Agent.Agent)
end

-- This will be set to TileScoring.getScoresAt during Agent.init()
Movement.getScoresAt = nil

local function worldToGrid2(world: Vector3): Vector2
	-- snapTile2 returns whatever your grid coord is (looks like Vector2)
	return MapUtilities.snapTile2(world)
end

local function blockToWaypointWorld(block: Block.Block): Vector3?
	if not block or not block.Part then
		return nil
	end
	return block:getWorldPosition() + Vector3.new(0, 5, 0)
end

local function getLayerObjectFromAgent(agent: Agent.Agent, originWorld: Vector3)
	local layerY = MapUtilities.getLayerFromAgentPos(originWorld)
	local map = MapUtilities.getCurrentMap()
	if not map then warn("no map set"); return nil end
	print(layerY , "LayerY")

	local groupedLayers = LayerUtilities.groupLayers(map.layers)
	return LayerUtilities.getLayer(groupedLayers, layerY)
end
local function worldToGrid2(world: Vector3): Vector2
	-- snapTile2 returns whatever your grid coord is (looks like Vector2)
	return MapUtilities.snapTile2(world)
end

local function blockToWaypointWorld(block: Block.Block): Vector3?
	if not block or not block.Part then
		return nil
	end
	return block:getWorldPosition() + Vector3.new(0, 5, 0)
end

-- Safely disconnect movement and set idle animation
local function disconnectMove(agent)
	if agent.moveConnection then
		agent.moveConnection:Disconnect()
		agent.moveConnection = nil
	end
	AgentAnimations.idle(agent)
end

local function applyScoreNoise(agent: Agent.Agent, baseScore: number): number
	local amp = agent.AgentConfig.scoreNoiseAmp
	if amp == nil or amp <= 0 then
		return baseScore
	end

	-- symmetric noise in [-amp, +amp]
	local noise = (math.random() * 2 - 1) * amp
	return baseScore + noise
end

-- Fire wander complete callback if present
local function fireWanderComplete(agent: Agent.Agent)
	AgentAnimations.idle(agent)
	if agent.onWanderCompleteCallback and agent.alive then
		-- Temporarily clear callback to prevent re-entrancy
		local callback = agent.onWanderCompleteCallback
		agent.onWanderCompleteCallback = nil
		task.defer(function()
			callback(agent)
		end)
	end
end

-- Handle waypoint reached event
local function reachedWaypoint(agent: Agent.Agent, reached: boolean)
	-- If we don't have a humanoid or agent is dead, stop
	if agent == nil or agent.alive == false or agent.humanoid == nil then
		disconnectMove(agent)
		return
	end

	if not reached then
		-- Path failed midway – consider wander complete
		disconnectMove(agent)
		fireWanderComplete(agent)
		return
	end

	-- Advance waypoint index
	agent.waypointIndex += 1

	if agent.waypointIndex > #agent.waypoints then
		-- Reached final waypoint – wander complete
		disconnectMove(agent)
		fireWanderComplete(agent)
		return
	end

	-- Move to next waypoint
	local nextPos = agent.waypoints[agent.waypointIndex]
	agent.humanoid:MoveTo(nextPos)
end

function Movement.stop(agent: Agent.Agent)
	disconnectMove(agent)
end

function Movement.resetWander(agent: Agent.Agent)
	if not agent then
		return
	end

	disconnectMove(agent)

	agent.waypoints = {}
	agent.waypointIndex = 0

	-- Clear intent too (optional, but usually what "reset" implies)
	agent.subGoalWorld = nil
	agent.subGoalExpiresAt = 0

	Movement.wander(agent)
end

local function chooseSubGoal(agent, originWorld, layerY, originTile)
	-- bigger than your immediate step radius
	local subRadius = 20

	-- sample random offsets a few times until we find a valid tile
	for _ = 1, 12 do
		local ox = math.random(-subRadius, subRadius)
		local oy = math.random(-subRadius, subRadius)

		if not (ox == 0 and oy == 0) then
			-- If you have a way to query a tile/block at an offset, use it.
			-- Since you already get scores via getScoresAt, we can reuse that:
			local scores = Movement.getScoresAt(layerY, originTile, subRadius)
			if scores then
				local key = VectorUtil.SerializeVector2(Vector2.new(ox, oy))
				local tileScore = scores[key]
				if tileScore and tileScore.blockId then
					local blk = LoadedBlocks[tileScore.blockId]
					if blk and blk.Part then
						local subgoalPos = blk:getWorldPosition() + Vector3.new(0, 5, 0)
						AgentUtil.placeStamp(agent, "subgoal", subgoalPos, Color3.new(0.011764, 0.231372, 0.741176))
						return subgoalPos
					end
				end
			end
		end
	end

	return nil
end

local function subGoalScore(agent, tileScore)
	if not agent.subGoalWorld then
		return 0
	end

	-- tileScore.position looks like Vector2 grid pos in your debug print
	-- Convert tile position -> world position via LoadedBlocks if possible
	if not tileScore.blockId then
		return 0
	end

	local blk = LoadedBlocks[tileScore.blockId]
	if not blk or not blk.Part then
		return 0
	end

	local tileWorld = blk:getWorldPosition()
	local d = (tileWorld - agent.subGoalWorld).Magnitude

	-- turn distance into a 0..1-ish attraction (tweak 20 to taste)
	local attraction = 1 / (1 + (d / 20))

	return attraction * agent.AgentConfig.subGoalWeight
end

local function getForwardDir(agent: Agent.Agent): Vector3
	local pp = agent.model and agent.model.PrimaryPart
	if not pp then
		return Vector3.new(0, 0, -1)
	end

	local look = pp.CFrame.LookVector
	return Vector3.new(look.X, 0, look.Z).Unit
end

local function forwardBiasScore(agent: Agent.Agent, originWorld: Vector3, tileScore): number
	local blk = tileScore.blockId and LoadedBlocks[tileScore.blockId]
	if not blk or not blk.Part then
		return 0
	end

	local targetWorld = blk:getWorldPosition()
	local toTarget = targetWorld - originWorld
	toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)

	-- if candidate is basically same position, no bias
	if toTarget.Magnitude < 1e-3 then
		return 0
	end

	local moveDir = toTarget.Unit
	local forwardDir = getForwardDir(agent)

	local dot = forwardDir:Dot(moveDir) -- [-1, 1]

	-- Map to [0, 1] where:
	-- behind (-1) => 0
	-- side (0)    => 0.5
	-- ahead (1)   => 1
	local mapped = (dot + 1) * 0.5

	-- Optional: make it "mostly forward" by squashing sideways
	-- Raising to a power > 1 favours high values more.
	mapped = mapped ^ agent.AgentConfig.forwardBiasPower

	return mapped * agent.AgentConfig.forwardBiasWeight
end

function Movement.wander(agent: Agent.Agent)
	if not agent.model or not agent.model.PrimaryPart or not agent.humanoid then
		return nil
	end
	if not Movement.getScoresAt then
		warn("[Movement.wander] TileScoring hooks not set (getScoresAt).")
		fireWanderComplete(agent)
		return nil
	end

	disconnectMove(agent)

	-- choose best scoring tile within radius (block distance = grid offsets)
	local originWorld = agent.model.PrimaryPart.Position

	local s, originTile, layerY = pcall(function()
		return MapUtilities.snapTile2(originWorld), MapUtilities.getLayerFromAgentPos(originWorld)
	end)

	if not s then
		warn("something went wrong here")
		return
	end
	local radius = math.ceil(agent.AgentConfig.wanderRadius / ServerConfigurations.BLOCK_SIZE)
	local offsetScores = Movement.getScoresAt(layerY, originTile, radius) -- keyed by offset Vector2

	-- If nothing returned, bail
	if not offsetScores then
		fireWanderComplete(agent)
		return nil
	end

	local now = os.clock()

	if
		not agent.subGoalWorld
		or (agent.subGoalExpiresAt and now >= agent.subGoalExpiresAt)
		or ((agent.model.PrimaryPart.Position - agent.subGoalWorld).Magnitude < 8)
	then
		agent.subGoalWorld = chooseSubGoal(agent, originWorld, layerY, originTile)
		agent.subGoalExpiresAt = now + math.random(2, 10)
	end

	-- Pick the best tile:
	-- - ignore nil tiles (destroyed)
	-- - optionally ignore the center tile (so they actually move)
	-- - add small randomness to break ties
	local bestTileScore = -math.huge
	local bestTileData: {} = nil

	for offset: string, tileScore in pairs(offsetScores) do
		local offsetVector = VectorUtil.DeserializeVector2(offset)
		if tileScore ~= nil then
			-- ignore the center tile (optional)
			if not (offsetVector.X == 0 and offsetVector.Y == 0) then
				if not tileScore then
					continue
				end

				local prox = tileScore.ProxScore

				if agent.threatState == 1 then
					prox = prox * (2 * agent.AgentConfig.aggression - 1)
				end

				local base = tileScore.NeighborScore + prox

				local goal = subGoalScore(agent, tileScore)

				local fwd = forwardBiasScore(agent, originWorld, tileScore)
				local s = base + goal + fwd
				s = applyScoreNoise(agent, s)

				if s > bestTileScore + 1e-6 then
					bestTileScore = s
					bestTileData = tileScore
				elseif math.abs(s - bestTileScore) <= 1e-6 then
					if math.random() < 0.5 then
						bestTileData = tileScore
					end
				end
			end
		end
	end

	if not bestTileData then
		-- no valid tiles in radius
		print("[Movement.wander] no valid tiles found in radius")
		fireWanderComplete(agent)
		return nil
	end

	local bestTargetBlockId = bestTileData.blockId
	if bestTargetBlockId == nil then
		fireWanderComplete(agent)
		print("[Movement.wander] best tile has no blockId")
		return nil
	end

	local targetBlock = LoadedBlocks[bestTargetBlockId]
	if not targetBlock or not targetBlock.Part then
		print("[Movement.wander] best target block not found or has no part")
		fireWanderComplete(agent)
		return nil
	end

	local targetWorld = targetBlock:getWorldPosition() + Vector3.new(0, 5, 0)

	-- Compute path (same as before)
	-- === Custom grid pathfinding ===
	local startGrid = worldToGrid2(originWorld)
	local goalGrid = worldToGrid2(targetWorld)

	-- get the Layer.Layer object your pathfinder expects
	local layerObj = getLayerObjectFromAgent(agent, originWorld)
	if not layerObj then
		print("[Movement.wander] no layer object")
		fireWanderComplete(agent)
		return nil
	end

	local foundPath = Pathfinding.findPath(layerObj, startGrid, goalGrid)

	-- foundPath should be your Pathfinding.path { pathId, waypoints (Block.Block array), ... }
	if not foundPath or not foundPath.waypoints or #foundPath.waypoints == 0 then
		print("[Movement.wander] custom pathfinding failed")
		fireWanderComplete(agent)
		return nil
	end

	agent.waypoints = {}

	-- Convert blocks -> world positions
	for _, blk in ipairs(foundPath.waypoints) do
		local wpWorld = blockToWaypointWorld(blk)
		if wpWorld then
			table.insert(agent.waypoints, wpWorld)
		end
	end

	-- If conversion produced nothing, bail
	if #agent.waypoints == 0 then
		print("[Movement.wander] path had no valid world waypoints")
		fireWanderComplete(agent)
		return nil
	end

	agent.waypointIndex = 1
	AgentAnimations.running(agent)
	agent.humanoid:MoveTo(agent.waypoints[agent.waypointIndex])

	local humanoid = agent.humanoid
	agent.moveConnection = humanoid.MoveToFinished:Connect(function(reached)
		reachedWaypoint(agent, reached)
	end)

	if #agent.waypoints >= 2 then
		agent.waypointIndex = 1
		AgentAnimations.running(agent)
		reachedWaypoint(agent, true)
	else
		disconnectMove(agent)
		fireWanderComplete(agent)
	end

	return nil
end

return Movement
