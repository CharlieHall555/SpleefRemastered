local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Agent = require(ModuleDirectory.Systems.Agent.Agent)
local AgentPersonalities = require(ModuleDirectory.Systems.Agent.AgentPersonalities)
local CharacterGeneration = require(ModuleDirectory.Systems.Agent.CharacterGeneration)
local AgentsInGame = require(ModuleDirectory.Systems.Round.AgentsInGame)

local AgentManager = {}

local Map

local charAgent: { [Model]: Agent.Agent } = {}
local agentDeathCallback


--used for round manager
function AgentManager.setOnAgentDeath(fn: (a: Agent.Agent) -> nil)
	agentDeathCallback = fn
end

function AgentManager.onAgentDied(a: Agent.Agent)
	if agentDeathCallback then
		agentDeathCallback(a)
	end

	AgentsInGame.removeAgent(a)
end

function AgentManager.preDestroy(a: Agent.Agent)
	a:destroy()
end

function AgentManager.onLoaded()
	Map = require(ModuleDirectory.Systems.Map.Map)

	RunService.Heartbeat:Connect(function(deltaTime)
		for each_id, each in Agent.getAll() do
			each:tick(deltaTime)
		end
	end)
end

function AgentManager.generateAgent(params: Agent.AgentCreationParams): Agent.Agent
	local newAgent = Agent.new(params)
	newAgent.model.PrimaryPart.CFrame = CFrame.new(params.spawnLocation)
	AgentsInGame.addAgent(newAgent)
	return newAgent
end

function AgentManager.activateAgents()
	local agentCount = 0
	for _, agent in Agent.getAll() do
		print("[AgentManager.activateAgents] Starting wander for agent:", agent.id)
		agent:startWander()
		agentCount += 1
	end
	print("[AgentManager.activateAgents] Activated", agentCount, "agents")
end

function AgentManager.getAgentFromCharacter(char: Model): Agent.Agent?
	return charAgent[char]
end

function AgentManager.sendAgentModels(players: { Player })
	local agentModels = {}

	for _, eachAgent in Agent.getAll() do
		table.insert(agentModels, eachAgent.model)
	end

	RemoteEventHandler.FireOnClients(players, "SEND_STARTING_AGENTS", agentModels)
end



function AgentManager.createAgentsFor(currentMap: Map.Map, n: number)
	print("[AgentManager.createAgentsFor] Creating", n, "agents for map:", currentMap.id)
	local topLayer = currentMap:getTopLayer()

	for i = 1, n do
		local randomBlock = topLayer:getRandomBlock()
		local position = randomBlock:getWorldPosition() + Vector3.new(0, 150, 0)
		local agentParams, difficulty = AgentPersonalities.createRandom(position)
		local newAgent = AgentManager.generateAgent(agentParams)
		newAgent.model:SetAttribute("AgentDifficulty", difficulty)
		print("[AgentManager.createAgentsFor] Created agent", i, "ID:", newAgent.id, "Difficulty:", difficulty, "at position:", position)

		charAgent[newAgent.model] = newAgent
	end
	print("[AgentManager.createAgentsFor] Finished creating", n, "agents")
end



return AgentManager
