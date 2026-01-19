--!strict

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local VISION_UPDATE_INTERVAL = 0.25
local BLOCK_DESTROY_INTERVAL = 1

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local Layer, Map

local Pathfinding = require(ModuleDirectory.Systems.Agent.Pathfinding)
local CharacterGeneration = require(ModuleDirectory.Systems.Agent.CharacterGeneration)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)

local AgentMovement = require(ModuleDirectory.Systems.Agent.AgentMovement)
local AgentCombat = require(ModuleDirectory.Systems.Agent.AgentCombat)
local AgentAnimations = require(ModuleDirectory.Systems.Agent.AgentAnimations)

local currentMap: Map.Map? = nil

local Agent = {}
Agent.__index = Agent

export type AgentType = "PASSIVE" | "AGGRESSIVE"

export type AgentConfig = {
	wanderRadius: number,
	wanderTime: number,
	subGoalWeight: number,
	forwardBiasWeight: number,
	forwardBiasPower: number,
	threatRadius: number,
	underThreatProxMultiplier: number,
	scoreNoiseAmp: number,
	movementConnectionWeight: number,
	movementProximityWeight: number,
	noiseMagnitude: number,

	combatConnectionWeight: number,
	combatProximityWeight: number,

	breakScoreThreshold: number,
	shootScoreThreshold: number,
	breakCooldownMin: number,
	breakCooldownMax: number,
	shootCooldownMin: number,
	shootCooldownMax: number,
	idleUrgencyGain: number,

	distanceWeight: number,
	threatOnBlockWeight: number,
	threatDistancePower: number,


}

export type Agent = {
	model: Model,
	id: string,
	config: AgentConfig,
	wanderActive: boolean,
	humanoid: Humanoid,
	idleUrgency : number,
	threatened: boolean,
	visionTimer: number,
	wanderActive: boolean,
	connections: { [string]: RBXScriptConnection },

	movementState: MovementState,
	combatState: CombatState,

	respawn: (self: Agent) -> nil,
	startWander: (self: Agent) -> nil,
	stopWander: (self: Agent) -> nil,
	resetWander: (self: Agent) -> nil,
	die: (self: Agent) -> nil,
	destroy: (self: Agent) -> nil,
	getLayerCurrentlyOn: (self: Agent) -> Layer.Layer?,
	snapToGrid: (self: Agent) -> { layerIndex: number, layerPosition: Vector2 }?,
}

export type AgentCreationParams = {
	spawnLocation: Vector3,
	AgentConfig: AgentConfig?,
}

export type MovementState = {
	currentPath: Pathfinding.path?,
	waypointN: number?,
}

export type CombatState = {

	ammo : number,
	threats:  {[number]: Agent | Player }?,
	combatTimer : number
}

local loadedAgents: { [string]: Agent } = {}

function Agent.setCurrentMap(n: Map.Map)
	print("[Agent] setCurrentMap called - Map:", n and n.id or "NIL", "Layers:", n and #n:getLayers() or 0)
	currentMap = n
end

function Agent.getAll()
	return loadedAgents
end

function Agent.getById(id: string)
	return loadedAgents[id]
end

function Agent.getByModel(model: Model): Agent?
	local selfId = model:GetAttribute("AgentId")
	if not selfId then
		return nil
	end
	return loadedAgents[selfId]
end

function Agent.new(params: AgentCreationParams): Agent
	local self: Agent = setmetatable({}, Agent)
	self.id = HttpService:GenerateGUID(false)
	self.config = params.AgentConfig or {
			wanderRadius = 10,
			wanderTime = 5,
			subGoalWeight = 1,
			forwardBiasWeight = 1,
			forwardBiasPower = 2,

			threatRadius = 10,
			underThreatProxMultiplier = 2,
			scoreNoiseAmp = 0.1,
		movementConnectionWeight = 1,
		movementProximityWeight = 1,
		noiseMagnitude = 0.25,

		combatConnectionWeight = 2.0,
		combatProximityWeight = 1.25,

		breakScoreThreshold = 1.5,
			breakCooldownMax = 1.2,

			shootCooldownMin = 0.2,
			shootCooldownMax = 0.9,

			idleUrgencyGain = 0.15,

			distanceWeight = 2.5,
			threatOnBlockWeight = 5.0,
			threatDistancePower = 1.0,
		}
	self.wanderActive = false
	self.connections = {} -- should be cleaned up on destroy
	self.model = CharacterGeneration.generateDummy()
	self.model:PivotTo(CFrame.new(params.spawnLocation))
	self.model:SetAttribute("AgentId", self.id)
	self.humanoid = self.model:FindFirstChild("Humanoid")
	self.threatened = false
	self.visionTimer = 0
	self.alive = true
	self.idleUrgency = 0

	self.movementState = {
		currentPath = nil,
		waypointN = 0,
	}

	self.combatState = {
		threats = {},
		combatTimer = 0
	}

	self.connections["MoveToFinished"] = self.humanoid.MoveToFinished:Connect(function(reached)
		AgentMovement.agentCompletedWanderStep(self, reached)
	end)

	self.connections["DeathConnection"] = self.humanoid.Died:Connect(function()
		self:die()
	end)

	self:setOwnsershipToServer()

	loadedAgents[self.id] = self
	return self
end

function Agent.startWander(self: Agent): nil
	self.wanderActive = true
	AgentMovement.agentStartWander(self)
end

function Agent.setOwnsershipToServer(self: Agent)
	local s, r = pcall(function()
		for _, each: BasePart in self.model:GetChildren() do
			if each:IsA("BasePart") then
				each:SetNetworkOwner(nil)
			end
		end
	end)
end

function Agent.stopWander(self: Agent): nil
	self.wanderActive = false
end

function Agent.resetWander(self: Agent)
	AgentMovement.resetWander(self)
end

function Agent.die(self: Agent): nil 
	self.alive = false
	self:destroy()
end

function Agent.destroy(self: Agent): nil
	loadedAgents[self.id] = nil
	if self.model then
		self.model:Destroy()
	end
	self.eventQueue = {}
end

function Agent.getLayerCurrentlyOn(self: Agent): Layer.Layer?
	if not currentMap then
		print("[Agent.getLayerCurrentlyOn] currentMap is NIL for agent:", self.id)
		return nil
	else
		local rootPart = self.model:FindFirstChild("HumanoidRootPart") or self.model.PrimaryPart
		if not rootPart then
			print("[Agent.getLayerCurrentlyOn] No rootPart for agent:", self.id)
			return nil
		end
		local layer = currentMap:getClosestLayerTo(rootPart.Position.Y)
		return layer
	end
end

function Agent.snapToGrid(self: Agent): { layerIndex: number, layerPosition: Vector2 }
	if not currentMap then
		return nil
	end
	local rootPart = self.model:FindFirstChild("HumanoidRootPart") or self.model.PrimaryPart
	if not rootPart then
		return nil
	end
	return currentMap:snapPositionToGrid(rootPart.Position)
end

function Agent.init()
	Layer = require(ModuleDirectory.Systems.Map.Layer)
	Map = require(ModuleDirectory.Systems.Map.Map)
end

function Agent.visionUpdate(self: Agent)
	local threats, threatCount = AgentCombat.getPlayersInRadius(self, self.config.threatRadius)
	self.combatState.threats = threats

	if threatCount > 1 then
		self.threatened = true
		-- BOOST urgency dramatically when threats detected
		self.idleUrgency = math.min(1, self.idleUrgency + (0.3 * threatCount))
	else
		self.threatened = false
	end
end

function Agent.tick(self: Agent, dt: number)
	self.visionTimer += dt

	if self.visionTimer >= VISION_UPDATE_INTERVAL then
		self.visionTimer = 0
		self:visionUpdate()
	end

	AgentCombat.tick(self , dt)

end

return Agent
