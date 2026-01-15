local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LayerUtilities = require(ModuleDirectory.LayerUtilities)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local LoadedBlocks = require(ModuleDirectory.Systems.Map.LoadedBlocks)
local MapUtilities = require(ModuleDirectory.Systems.Map.MapUtilities)
local AgentAnimations = require(ModuleDirectory.Systems.Agent.AgentAnimations)

--AgentAnimations.running(agent)
--AgentAnimations.idle(agent)

local PathfindingService = game:GetService("PathfindingService")

local Movement = {}

Movement.getScoresAt = nil --this will be set to the TileScoring.getScoresAt function during Agent.init()

-- internal: disconnect safely
local function disconnectMove(agent)
	if agent.moveConnection then
		agent.moveConnection:Disconnect()
		agent.moveConnection = nil
	end
	AgentAnimations.idle(agent)
end

local function randomNoise(baseScore)
	return baseScore + (math.random() - 0.5) * 0.1
end

-- internal: fire wander complete callback if present
local function fireWanderComplete(agent)
	-- callback is stored on the Agent module table (set by Agent.setUpCallback)
	AgentAnimations.idle(agent)
	if agent.onWanderCompleteCallback then
		agent.onWanderCompleteCallback(agent)
	end
end

-- internal: centralised waypoint handler
local function reachedWaypoint(agent, reached: boolean)
	-- If we don't have a humanoid or agent is dead, stop
	if not agent or not agent.humanoid or agent.health <= 0 then
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

function Movement.stop(agent)
	disconnectMove(agent)
end
function Movement.resetWander(agent)
	if not agent then
		return
	end

	-- Stop current movement / disconnect old MoveToFinished listener
	disconnectMove(agent)

	-- Clear any existing path state (optional but keeps things tidy)
	agent.waypoints = {}
	agent.waypointIndex = 0

	-- Start a brand new wander
	Movement.wander(agent)
end

function Movement.wander(agent)
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
	local originTile = MapUtilities.snapTile2(originWorld)
	local layerY = MapUtilities.getLayerFromAgentPos(originWorld) -- should return 15/30/45 etc

	local radius = 3
	local offsetScores = Movement.getScoresAt(layerY, originTile, radius) -- keyed by offset Vector2

	-- If nothing returned, bail
	if not offsetScores then
		fireWanderComplete(agent)
		return nil
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

				local s = tileScore.NeighborScore + tileScore.ProxScore
				s = randomNoise(s)

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

	print(
		"[Movement.wander] best tile score:",
		bestTileScore,
		VectorUtil.SerializeVector2(bestTileData.position),
		bestTileData.NeighborScore,
		bestTileData.ProxScore
	)

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
	local path = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 6,
		AgentCanJump = false,
		WaypointSpacing = 2,
	})
	path:ComputeAsync(originWorld, targetWorld)

	if path.Status ~= Enum.PathStatus.Success then
		fireWanderComplete(agent)
		print("[Movement.wander] pathfinding failed")
		return nil
	end

	local pathWaypoints = path:GetWaypoints()

	agent.waypoints = {}
	for _, wp in ipairs(pathWaypoints) do
		table.insert(agent.waypoints, wp.Position)
	end

	agent.waypointIndex = 1

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
