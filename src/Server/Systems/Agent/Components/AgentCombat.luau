local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local TouchedBlockTracker = require(ModuleDirectory.Systems.Stats.TouchedBlockTracker)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)
local BlockDestruction = require(ModuleDirectory.Systems.Map.BlockDestruction)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local config = require(game:GetService("ServerScriptService").ServerConfigurations)

local Agent, Block

local AgentCombat = {}

local blockBreakingRange = 20 -- check this with cleint too

local COMBAT_TICK_INTERVAL = 0.1

local agentOverlap = OverlapParams.new()
agentOverlap.CollisionGroup = "CG_AGENT_OR_PLAYER"

local blockOverlap = OverlapParams.new()
blockOverlap.FilterType = Enum.RaycastFilterType.Include
blockOverlap.CollisionGroup = "Default"

type Agent = Agent.Agent

local function getbreakingTargetBlock(agent: Agent) : {bestBlock : Block.Block , bestScore : number}
	print("[AgentCombat] getbreakingTargetBlock called for:", agent.model.Name)

	local agentWorldOrigin = agent.model.PrimaryPart.Position
	local snappedToGrid = agent:snapToGrid()

	if not snappedToGrid then
		warn("[AgentCombat] Grid position missing")
		return nil
	end

	local currentLayer = agent:getLayerCurrentlyOn()
	local currentLayerPos = snappedToGrid.layerPosition

	print(
		"[AgentCombat] Agent position:",
		agentWorldOrigin,
		"Layer:",
		snappedToGrid.layerIndex
	)

	if not currentLayer then
		print("[AgentCombat] No current layer found")
		return nil
	end

	-- =========================
	-- Build score lookups
	-- =========================
	local idToProxScore = {}
	local idToConnectionScore = {}

	local relevantScores = TileScoring.getScoresAround(
		snappedToGrid.layerIndex,
		currentLayerPos,
		math.floor(blockBreakingRange / config.BLOCK_SIZE)
	)

	for sOffsetPos, score in relevantScores.tiles do
		local layerPos = score.layerPos
		if not layerPos then
			local offset = VectorUtil.deserializeVector2(sOffsetPos)
			layerPos = currentLayerPos + offset
		end

		local blockAtPos = currentLayer:getBlock(layerPos)
		if blockAtPos then
			idToProxScore[blockAtPos.id] = score.prox or 0
			idToConnectionScore[blockAtPos.id] = score.connected or 0
		end
	end


	-- Get threat positions for proximity scoring
	local threatPositions = {}
	
	if agent.combatState.threats then
		for _, eachThreat in agent.combatState.threats do
			local threatPos

			if typeof(eachThreat) == "Instance" then
				local char = eachThreat.Character
				threatPos = char and char.PrimaryPart and char.PrimaryPart.Position
			else
				threatPos = eachThreat.model
					and eachThreat.model.PrimaryPart
					and eachThreat.model.PrimaryPart.Position
			end

			if threatPos then
				table.insert(threatPositions, threatPos)
			end
		end
	end
	
	-- Helper function to find closest threat to a position
	local function getClosestThreatDistance(position: Vector3): number?
		if #threatPositions == 0 then
			return nil
		end
		
		local minDist = math.huge
		for _, threatPos in threatPositions do
			local dist = (position - threatPos).Magnitude
			if dist < minDist then
				minDist = dist
			end
		end
		return minDist
	end


	local candidateParts =
		workspace:GetPartBoundsInRadius(agentWorldOrigin, blockBreakingRange, blockOverlap)

	local bestBlock: Block.Block? = nil
	local bestScore = -math.huge

	for _, eachPart in candidateParts do
		local id = eachPart:GetAttribute("id")
		if typeof(id) ~= "number" and typeof(id) ~= "string" then
			continue
		end

		local eachBlock = Block.get(id)
		if not eachBlock then
			continue
		end

		-- Same layer only
		local parentLayer = eachBlock:getParentLayer()
		if not parentLayer or parentLayer.layerIndex ~= snappedToGrid.layerIndex then
			continue
		end

		local blockWorldPos = eachBlock:getWorldPosition()
		local distanceFromMe = (agentWorldOrigin - blockWorldPos).Magnitude
		if distanceFromMe > blockBreakingRange then
			continue
		end

		local prox = idToProxScore[eachBlock.id] or 0
		local connected = idToConnectionScore[eachBlock.id] or 0

		-- Threat bonus and distance calculation
		local threatBonus = 0
		local distReward = 0
		
		local closestThreatDist = getClosestThreatDistance(blockWorldPos)
		
		if closestThreatDist and agent.threatened then
			-- When threatened, prioritize blocks CLOSE to threats
			-- Closer to threat = higher bonus
			local threatProximity = math.max(0, 1 - (closestThreatDist / blockBreakingRange))
			threatBonus = agent.config.threatOnBlockWeight * (threatProximity ^ 0.5)
			
			-- For threatened state, prefer blocks closer to agent (easier to break)
			local distPastMin = math.max(0, distanceFromMe - (config.BLOCK_SIZE * 2))
			local distNorm = distPastMin / math.max(1, (blockBreakingRange - (config.BLOCK_SIZE * 2)))
			-- Invert: 1 - distNorm makes close blocks to agent score higher
			distReward = ((1 - distNorm) ^ agent.config.threatDistancePower) * agent.config.distanceWeight
		else
			-- Not threatened - prefer FAR blocks from agent (original behavior)
			local distPastMin = math.max(0, distanceFromMe - (config.BLOCK_SIZE * 2))
			local distNorm = distPastMin / math.max(1, (blockBreakingRange - (config.BLOCK_SIZE * 2)))
			distReward = (distNorm ^ agent.config.threatDistancePower) * agent.config.distanceWeight
		end

		local score =
			threatBonus
			+ (prox * agent.config.combatProximityWeight)
			- (connected * agent.config.combatConnectionWeight)
			+ distReward

		if score > bestScore then
			bestScore = score
			bestBlock = eachBlock
			print(
				"[AgentCombat] New best block:",
				eachBlock.id,
				"Score:",
				score,
				"Dist:",
				distanceFromMe
			)
		end
	end

	if bestBlock then
		print("[AgentCombat] Final best block:", bestBlock.id, "Score:", bestScore)
	else
		print("[AgentCombat] No suitable block found to break")
	end

	return {bestBlock = bestBlock , bestScore = bestScore}
end



function AgentCombat.getPlayersInRadius(
	agent: Agent.Agent,
	radius: number
): ({ [number]: Agent.Agent | Player }, number)
	print("[AgentCombat] getPlayersInRadius called, radius:", radius)
	local inRadius = {}
	local seenChars = {}
	local origin = agent.model.PrimaryPart.Position
	local contactCount = 0

	local parts = workspace:GetPartBoundsInRadius(origin, radius, agentOverlap)
	print("[AgentCombat] Parts in radius:", #parts)

	for _, eachPart: Instance in parts do
		local model = eachPart.Parent
		if seenChars[model] then
			continue
		end

		local entity
		local entityType

		if model:HasTag("AGENT") then
			entity = Agent.getByModel(model)
			entityType = "AGENT"
		else
			entity = Players:GetPlayerFromCharacter(model)
			entityType = "PLAYER"
		end

		if entity then
			local characterPrimary = model.PrimaryPart
			local distance = (characterPrimary.Position - origin).Magnitude
			inRadius[distance] = entity
			contactCount += 1
			print("[AgentCombat] Entity found at distance:", distance, "Type:", entityType)
		end

		seenChars[model] = true
	end

	print("[AgentCombat] Total contacts found:", contactCount)
	return inRadius, contactCount
end

local agentStamps: { [any]: { [string]: BasePart } } = {}

local STAMP_TEMPLATE: BasePart = Instance.new("Part")
STAMP_TEMPLATE.Size = Vector3.new(1, 1, 1)
STAMP_TEMPLATE.Anchored = true
STAMP_TEMPLATE.Shape = Enum.PartType.Ball
STAMP_TEMPLATE.CanCollide = false
STAMP_TEMPLATE.Material = Enum.Material.Neon
STAMP_TEMPLATE.Name = "AgentStamp"

function AgentCombat.placeStamp(agent: Agent.Agent, stampName: string, position: Vector3, color: Color3)
	print("[AgentCombat] placeStamp called -", "Name:", stampName, "Position:", position, "Color:", color)
	-- Ensure agent entry exists
	if agentStamps[agent] == nil then
		agentStamps[agent] = {}
	end

	local stampsForAgent = agentStamps[agent]

	-- If stamp already exists for this name, remove it
	local existingStamp = stampsForAgent[stampName]
	if existingStamp then
		existingStamp:Destroy()
		stampsForAgent[stampName] = nil
	end

	-- Create new stamp
	local stamp = STAMP_TEMPLATE:Clone()
	stamp.Name = stampName
	stamp.Color = color
	stamp.Position = position
	stamp.Parent = workspace -- or a dedicated folder

	-- Store reference
	stampsForAgent[stampName] = stamp
end

-- Helper: clamp 0..1
local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

-- Helper: linear interpolate
local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function computeUrgency(agent: Agent): number
	return clamp01(agent.idleUrgency)
end

local function computeBreakCooldown(agent: Agent): number
	local u = computeUrgency(agent)
	
	-- If threatened, reduce cooldown even further
	local threatMultiplier = 1
	if agent.threatened then
		threatMultiplier = 0.5  -- 50% faster when threatened
	end
	
	return lerp(agent.config.breakCooldownMax, agent.config.breakCooldownMin, u) * threatMultiplier
end

local function shouldBreak(agent: Agent, bestBlock: any, bestScore: number): boolean
	if not bestBlock then
		return false
	end

	if bestScore < agent.config.breakScoreThreshold then
		return false
	end

	return true
end

function AgentCombat.tick(agent: Agent, dt: number)
	if agent.combatState.combatTimer == nil then
		agent.combatState.combatTimer = 0
	end
	if agent.combatState.breakTimer == nil then
		agent.combatState.breakTimer = 0
	end
	agent.idleUrgency += (agent.config.idleUrgencyGain * dt)

	-- =========================
	agent.combatState.combatTimer += dt
	agent.combatState.breakTimer += dt

	if agent.combatState.combatTimer < COMBAT_TICK_INTERVAL then
		return
	end
	agent.combatState.combatTimer -= COMBAT_TICK_INTERVAL

	local breakCooldown = computeBreakCooldown(agent)
	if agent.combatState.breakTimer < breakCooldown then
		return
	end

	local best = getbreakingTargetBlock(agent)
	if not best then
		return
	end

	local bestBlock = best.bestBlock
	local bestScore = best.bestScore

	if shouldBreak(agent, bestBlock, bestScore) then
		-- reset break timer
		agent.combatState.breakTimer = 0

		agent.idleUrgency *= 0.35

		print(
			"[AgentCombat] Breaking block:",
			bestBlock.id,
			"Score:",
			bestScore,
			"Cooldown:",
			breakCooldown
		)

		BlockDestruction.destroyBlockFromAgent(bestBlock)
	else
		-- Only decay urgency if NOT threatened
		if not agent.threatened then
			agent.idleUrgency *= 0.98
		end
	end
end


function AgentCombat.init()
	Agent = require(ModuleDirectory.Systems.Agent.Agent)
	Block = require(ModuleDirectory.Systems.Map.Block)
	blockOverlap.FilterDescendantsInstances = {Block.getBlockFolder()}
end

return AgentCombat
