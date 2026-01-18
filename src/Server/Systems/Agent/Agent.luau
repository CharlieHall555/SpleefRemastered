--!strict

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local VISION_UPDATE_INTERVAL = 0.25

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local CharacterGeneration  = require(ModuleDirectory.Systems.Agent.CharacterGeneration)

local AgentUtil = require(ModuleDirectory.Systems.Agent.AgentUtil)
local AgentMovement = require(ModuleDirectory.Systems.Agent.Movement)
local AgentCombat = require(ModuleDirectory.Systems.Agent.Combat)
local AgentHitbox = require(ModuleDirectory.Systems.Agent.AgentHitbox)

local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)

local onDiedCallback : ((any, Player?) -> nil)?
local onWanderCompleteCallback : ((any) -> nil)?

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
	aggression: number,
	scoreNoiseAmp: number,
}

export type Agent = {
	model: Model,
	health: number,
	id: string,
	spawnLocation: Vector3,
	maxHealth: number,
	humanoid: Humanoid,
	waypoints: { Vector3 },
	waypointIndex: number,
	playersAround: { [number]: Player },
	tickLastDamaged: number,
	tickLastAttacked: number,
	tickVisionUpdate: number,
	threatState: number,
	moveConnection: RBXScriptConnection?,
	subGoalWorld: Vector3?,
	subGoalExpiresAt: number?,
	alive: boolean,
	AgentConfig: AgentConfig,
}

export type AgentCreationParams = {
	spawnLocation: Vector3,
	maxHealth: number?,
	AgentConfig: AgentConfig?,
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
	local selfId = model:GetAttribute("AgentId")
	if not selfId then
		return nil
	end
	return loadedAgents[selfId]
end

function Agent.init()
	AgentMovement.getScoresAt = TileScoring.getScoresAt
	AgentMovement.getLayerFromAgentPos = TileScoring.getLayerFromAgentPos
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

	local defaultAgentConfig: AgentConfig = {
		wanderRadius = 20,
		wanderTime = 0.1,
		subGoalWeight = 0.9 + (math.random(-5, 5) / 100),
		forwardBiasWeight = 0.25,
		forwardBiasPower = 0.5,
		threatRadius = 12.5,
		aggression = math.random(0, 1),
		scoreNoiseAmp = 0.10
	}

	-- Merge with supplied params (override defaults)
	if params.AgentConfig then
		for key, value in pairs(params.AgentConfig) do
			defaultAgentConfig[key] = value
		end
	end

	self.AgentConfig = defaultAgentConfig

	self.playersAround = {}
	
	self.threatState = 0
	self.id = HttpService:GenerateGUID(false)

	self.model:SetAttribute("AgentId", self.id)
	self.model:AddTag("AGENT")

	self.waypoints = {}
	self.waypointIndex = 1	
	self.moveConnection = nil
	self.alive = true

	self.tickLastDamaged = 0
	self.tickLastAttacked = 0
	self.tickVisionUpdate = 0

	self.humanoid.Died:Connect(function()
		self:die()
	end)

	self.humanoid.Destroying:Connect(function()
		self:die()
	end)

	AgentHitbox.setup(self)

	loadedAgents[self.id] = self
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

function Agent:die(): nil
	AgentMovement.stop(self)

	if not self.model then
		return nil
	end

	self.alive = false

	if self.onDiedCallback then
		self.onDiedCallback(self)
	end

	if self._moveConnection then
		self._moveConnection:Disconnect()
		self._moveConnection = nil
	end

	for _, child in pairs(self.model:GetDescendants()) do
		if child.Name == "NameTagTemplate" then
			child:Destroy()
		end

		if child:IsA("Motor6D") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			Debris:AddItem(child, 2)
		end
	end

	Debris:AddItem(self.model, 5)

	return nil
end

function Agent:Destroy(): nil
	if self.model then
		self.model:Destroy()
	end

	loadedAgents[self.id] = nil
	return nil
end

function Agent.tick(self: Agent, deltaTime: number)
	-- Update vision on interval
	self.tickVisionUpdate += deltaTime
	if self.tickVisionUpdate >= VISION_UPDATE_INTERVAL and self.alive then
		self.tickVisionUpdate = 0

		local playersAgentsAround = AgentUtil.getPlayersInRadius(self, self.AgentConfig.threatRadius)
		if #playersAgentsAround > 1 then -- assuming the self is always within its own radius
			self.threatState = 1
		else
			self.threatState = 0
		end

	end

	if self.selfType == "PASSIVE" then
		return
	end

	-- aggressive behaviour placeholder
end

return Agent
