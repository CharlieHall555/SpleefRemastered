local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Agent = require(ModuleDirectory.Systems.Agent.Agent)
local CharacterGeneration = require(ModuleDirectory.Systems.Agent.CharacterGeneration)

local AgentManager = {}

local charAgent : {[Model]:Agent.Agent} = {}

function AgentManager.tick(a: Agent.Agent, deltaTime: number)
	-- Currently no per-tick behaviour
end

local function onAgentDied(a: Agent.Agent, killingPlayer: Player?) end

function AgentManager.preDestroy(a: Agent.Agent)
	a:destroy()
end

local function onAgentCompletedWander(a: Agent.Agent)
	print("wandercomplete")

	task.spawn(function()
		task.wait(a.wanderTime or 1)
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
	local agent = Agent.new(params)
	agent.model.PrimaryPart.CFrame = CFrame.new(params.spawnLocation)

	return agent
end

function AgentManager.activateAgents()


    for _, agent in Agent.getAll() do
        agent:wander()
    end
 
end

function AgentManager.getAgentFromCharacter(char : Model) : Agent.Agent?
	return charAgent[char]
end

function AgentManager.spawnNAgentsOnMap(currentMap: {}, n: number)
	local topLayer = currentMap:getTopLayer()

	for i = 1, n do
		local randomBlock = topLayer:getRandomBlock()
		local Position = Vector3.new(0, 150, 0)
		if randomBlock then
			Position = randomBlock.Part.Position + Vector3.new(0, 15, 0)
		end

		local newAgent = AgentManager.generateAgent({
			spawnLocation = Position,
			wanderRadius = 7   , -- blocks
		})

		charAgent[newAgent.model] = newAgent

	end
end

return AgentManager
