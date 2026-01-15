local AgentHitbox = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local TouchedBlockTracker = require(ModuleDirectory.Systems.Stats.TouchedBlockTracker)

local Agent

function AgentHitbox.init()
	Agent = ModuleDirectory.Systems.Agent.Agent
end

function AgentHitbox.setup(agent: Agent.Agent)
	local hitbox: Part = agent.model:FindFirstChild("CentralHitbox")
	if hitbox then
		agent.hitboxTouchedConnection = hitbox.Touched:Connect(function(otherPart) --MEMORY LEAK HERE NEED FIX SOMETIME!
			if otherPart:HasTag("Block") then
				TouchedBlockTracker.agentTouchedBlock(agent, otherPart)
			end
		end)
	end
end

return AgentHitbox
