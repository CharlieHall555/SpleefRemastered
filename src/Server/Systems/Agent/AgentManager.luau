local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Agent = require(ModuleDirectory.Systems.Agent.Agent)
local CharacterGeneration = require(ModuleDirectory.Systems.Agent.CharacterGeneration)
local AgentsInGame = require(ModuleDirectory.Systems.Round.AgentsInGame)

local AgentManager = {}

local charAgent: { [Model]: Agent.Agent } = {}

function AgentManager.tick(a: Agent.Agent, deltaTime: number)
	-- Currently no per-tick behaviour
end

local function onAgentDied(a: Agent.Agent, killingPlayer: Player?) end

function AgentManager.preDestroy(a: Agent.Agent)
	a:destroy()
end

local function onAgentCompletedWander(a: Agent.Agent)
	if a == nil or a.alive == false then
		return
	end

	task.spawn(function()
		if a.threatState == 0 then
			task.wait((a.wanderTime or 1) + (math.random(-25 , 25) / 100))
		end

		a:wander()
	end)
end

function AgentManager.onLoaded()
	Agent.setUpCallback(onAgentDied, onAgentCompletedWander)

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
	for _, agent in Agent.getAll() do
		agent:wander()
	end
end

function AgentManager.getAgentFromCharacter(char: Model): Agent.Agent?
	return charAgent[char]
end

function AgentManager.sendAgentModels(players: { Player })
	local agentModels = {}

	for _, eachAgent in Agent.getAll() do
		table.insert(agentModels , eachAgent.model)
	end

	RemoteEventHandler.FireOnClients(players, "SEND_STARTING_AGENTS", agentModels)
end

function AgentManager.createAgentsFor(currentMap: {}, n: number)
	local topLayer = currentMap:getTopLayer()

	for i = 1, n do
		local randomBlock = topLayer:getRandomBlock()
		local Position = Vector3.new(0, 150, 0)
		if randomBlock then
			Position = randomBlock.Part.Position + Vector3.new(0, 15, 0)
		end

		local newAgent = AgentManager.generateAgent({
			spawnLocation = Position,
			wanderRadius = 7, -- blocks
		})

		charAgent[newAgent.model] = newAgent
	end
end

return AgentManager
