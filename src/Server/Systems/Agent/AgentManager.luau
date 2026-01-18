local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Agent = require(ModuleDirectory.Systems.Agent.Agent)
local AgentPersonalities = require(ModuleDirectory.Systems.Agent.AgentPersonalities)
local CharacterGeneration = require(ModuleDirectory.Systems.Agent.CharacterGeneration)
local AgentsInGame = require(ModuleDirectory.Systems.Round.AgentsInGame)

local AgentManager = {}

local charAgent: { [Model]: Agent.Agent } = {}
local agentDeathCallback

function AgentManager.tick(a: Agent.Agent, deltaTime: number)
	-- Currently no per-tick behaviour
end

function AgentManager.setOnAgentDeath(fn: (a: Agent.Agent) -> nil)
	agentDeathCallback = fn
end

local function onAgentDied(a: Agent.Agent, killingPlayer: Player?)
	if agentDeathCallback then
		agentDeathCallback(a)
	end

	AgentsInGame.removeAgent(a)
	
	task.spawn(function()
		task.wait()
		if a then
			a:Destroy()
		end
	end)

end

function AgentManager.preDestroy(a: Agent.Agent)
	a:destroy()
end

local function onAgentCompletedWander(a: Agent.Agent)
	if a == nil or a.alive == false then
		return
	end

	task.spawn(function()
		if a.threatState == 0 then
			task.wait(a.AgentConfig.wanderTime)
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
		table.insert(agentModels, eachAgent.model)
	end

	RemoteEventHandler.FireOnClients(players, "SEND_STARTING_AGENTS", agentModels)
end



function AgentManager.createAgentsFor(currentMap: {}, n: number)
	local topLayer = currentMap:getTopLayer()

	for i = 1, n do
		local randomBlock = topLayer:getRandomBlock()
		local position = Vector3.new(0, 150, 0)
		if randomBlock then
			position = randomBlock.Part.Position + Vector3.new(0, 15, 0)
		end

		local agentParams = AgentPersonalities.createRandom(position)
		local newAgent = AgentManager.generateAgent(agentParams)

		charAgent[newAgent.model] = newAgent
	end
end

return AgentManager
