--!strict

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local VISION_UPDATE_INTERVAL = 0.5

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local CharacterGeneration  = require(ModuleDirectory.Systems.Agent.CharacterGeneration)

local AgentMovement = require(ModuleDirectory.Systems.Agent.Movement)
local AgentCombat = require(ModuleDirectory.Systems.Agent.Combat)

local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)

local onDiedCallback : ((any, Player?) -> nil)?
local onWanderCompleteCallback : ((any) -> nil)?

local Agent = {}
Agent.__index = Agent

export type AgentType = "PASSIVE" | "AGGRESSIVE"

export type Agent = {
	model: Model,
	health: number,
	id: string,
	spawnLocation: Vector3,
	maxHealth: number,
	wanderRadius: number,
	humanoid: Humanoid,
	waypoints: { Vector3 },
	waypointIndex: number,
	playersArround: { [number]: Player },
	tickLastDamaged: number,
	tickLastAttacked: number,
	tickVisionUpdate: number,
	wanderTime: number,
	moveConnection: RBXScriptConnection?,
}

export type AgentCreationParams = {
	spawnLocation: Vector3,
	maxHealth: number?,
	wanderRadius: number?,
	wanderTime: number?,
}

local loadedAgents: { [string]: Agent } = {}

function Agent.setUpCallback(onDied: (Agent, Player?) -> nil, onWanderComplete: (Agent) -> nil): nil
	onDiedCallback = onDied
	onWanderCompleteCallback = onWanderComplete

	return nil
end

function Agent.getAll()
	return loadedAgents
end

function Agent.getById(id: string)
	return loadedAgents[id]
end

function Agent.getByModel(model: Model): Agent?
	local agentId = model:GetAttribute("AgentId")
	if not agentId then
		return nil
	end
	return loadedAgents[agentId]
end

function Agent.init()
	AgentMovement.getScoresAt = TileScoring.getScoresAt
	AgentMovement.getLayerFromAgentPos = TileScoring.getLayerFromAgentPos
	AgentMovement.snapTile2 = TileScoring.snapTile2
end

function Agent.new(params: AgentCreationParams): Agent
	local self: Agent = setmetatable({}, Agent)

	self.health = params.maxHealth or 100
	self.maxHealth = params.maxHealth or 100
	self.spawnLocation = params.spawnLocation

	self.onDiedCallback = onDiedCallback
	self.onWanderCompleteCallback = onWanderCompleteCallback

	self.model = CharacterGeneration.generateDummy("Lvl1 Dummy")
	self.humanoid = self.model:FindFirstChildOfClass("Humanoid") :: Humanoid

	self.wanderTime = params.wanderTime or 1

	self.playersArround = {}

	self.id = HttpService:GenerateGUID(false)
	self.wanderRadius = params.wanderRadius or 20

	self.model:SetAttribute("AgentId", self.id)
	self.model:AddTag("AGENT")

	self.waypoints = {}
	self.waypointIndex = 1
	self.moveConnection = nil

	self.tickLastDamaged = 0
	self.tickLastAttacked = 0
	self.tickVisionUpdate = 0

	loadedAgents[self.id] = self
	print("hiiiii")
	print(self.id)
	return self
end

function Agent:respawn()
	-- stop movement + cleanup old model
	AgentMovement.stop(self)

	if self.model then
		Debris:AddItem(self.model, 1)
	end

	self.health = self.maxHealth
	self.model = CharacterGeneration.generateDummy("Lvl1 Dummy")
	self.humanoid = self.model:FindFirstChildOfClass("Humanoid") :: Humanoid

	self.model:SetAttribute("AgentId", self.id)
	self.model:AddTag("AGENT")

	if self.model.PrimaryPart then
		self.model.PrimaryPart.CFrame = CFrame.new(self.spawnLocation)
	end

end

function Agent:wander(): nil
	return AgentMovement.wander(self)
end

function Agent:takeDamage(value: number, damagingPlayer: Player?): nil
	return AgentCombat.takeDamage(self, value, damagingPlayer)
end

function Agent:Die(): nil
	return AgentCombat.die(self)
end

function Agent:Destroy(): nil
	AgentMovement.stop(self)

	if self.model then
		self.model:Destroy()
	end

	loadedAgents[self.id] = nil
	return nil
end

function Agent:tick(deltaTime)
	-- update vision on interval (placeholder; keep your logic here later)
	self.tickVisionUpdate += deltaTime
	if self.tickVisionUpdate >= VISION_UPDATE_INTERVAL then
		self.tickVisionUpdate = 0
		-- vision / aggro update could go here
	end

	if self.agentType == "PASSIVE" then
		return
	end

	-- aggressive behaviour placeholder
end

return Agent
