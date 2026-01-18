local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Systems.Gameplay.ServerHitBoxManager)
local Agent

local TouchedBlockTracker = {}

export type TouchRecord = {
	blockId: number,
	time: number,
}

local lastTouchedBlocks: { [Player]: { TouchRecord } } = {}
local lastTouchedAgentBlocks: { [string]: { TouchRecord } } = {}
local MAX_TRACKED = 5

function TouchedBlockTracker.agentTouchedBlock(agent: Agent.Agent, block: Instance)
	local agentId = agent.id
	local touchedBlockId = block:GetAttribute("Id")
	if typeof(touchedBlockId) ~= "number" then
		return
	end

	if not lastTouchedAgentBlocks[agentId] then
		lastTouchedAgentBlocks[agentId] = {}
	end

	table.insert(lastTouchedAgentBlocks[agentId], 1, {
		blockId = touchedBlockId :: number,
		time = time(),
	})

	if #lastTouchedAgentBlocks[agentId] > MAX_TRACKED then
		table.remove(lastTouchedAgentBlocks[agentId], #lastTouchedAgentBlocks[agentId])
	end
end

local function playerTouchedBlock(player: Player, otherPart: Instance)
	local touchedBlockId = otherPart:GetAttribute("Id")
	if typeof(touchedBlockId) ~= "number" then
		return
	end

	if not lastTouchedBlocks[player.UserId] then
		lastTouchedBlocks[player.UserId] = {}
	end

	table.insert(lastTouchedBlocks[player.UserId], 1, {
		blockId = touchedBlockId :: number,
		time = time(),
	})

	if #lastTouchedBlocks[player.UserId] > MAX_TRACKED then
		table.remove(lastTouchedBlocks[player.UserId], #lastTouchedBlocks[player.UserId])
	end
end

function TouchedBlockTracker.init()
	Agent = require(ModuleDirectory.Systems.Agent.Agent)

	ServerHitBoxManager.setUpCallback("Block", playerTouchedBlock)
end

function TouchedBlockTracker.getLastTouchedBlocks(input: Player | Agent.Agent ): { TouchRecord }
    if typeof(input) == "Player" then
        return lastTouchedBlocks[input] or {}
    else
        return lastTouchedAgentBlocks[input.id] 
    end

end

function TouchedBlockTracker.reset()
	lastTouchedBlocks = {}
end

return TouchedBlockTracker
