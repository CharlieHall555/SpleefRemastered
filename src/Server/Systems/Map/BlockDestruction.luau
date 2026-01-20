local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Systems.Map.Block)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local Config =require(game:GetService("ServerScriptService").ServerConfigurations)
local AmmoManager = require(ModuleDirectory.Systems.Ammo.AmmoManager)
local Onboarding = require(ModuleDirectory.Services.Analytics.Onboarding)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)
local AgentMovement = require(ModuleDirectory.Systems.Agent.AgentMovement)

export type DestroyRecord = {
    player: Player?,
    time: number,
    blockId: number
}

local BlockDestruction = {}

local Agent

-- Destruction tracking
local destroyCache: { [string]: DestroyRecord } = {} -- blockId -> record
local playerCache: { [number]: { number } } = {} -- userId -> list of blockIds

local function getUserId(p: Player?): number?
    return p and p.UserId or nil
end

function BlockDestruction.reset()
    table.clear(destroyCache)
    table.clear(playerCache)
end

function BlockDestruction.getBlocksDestroyedByPlayer(playerOrUserId: Player | number): { number }
    local userId = typeof(playerOrUserId) == "number" and (playerOrUserId :: number) or getUserId(playerOrUserId :: Player)
    if not userId then
        return {}
    end
    local list = playerCache[userId]
    if not list then
        return {}
    end
    return list
end

function BlockDestruction.getDestroyRecord(blockId: number): DestroyRecord?
    return destroyCache[blockId]
end

local function blockDestroyed(blockId: number, player: Player?)
	if blockId == nil then
		warn("blockId cannot be nil.")
		return
	end

    if destroyCache[blockId] then
        return
    end

    local record: DestroyRecord = {
        player = player,
        time = time(),
        blockId = blockId
    }
    destroyCache[blockId] = record

    local userId = getUserId(player)
    if userId then
        local list = playerCache[userId]
        if not list then
            list = {}
            playerCache[userId] = list
        end
        list[#list + 1] = blockId
    end
end

--this function is only used for a direct block request from a player (aka they've clicked a block at close range and will break)
local function destroyBlockRequest(player : Player , blockId : number)

	print("destory request")

    local blockToDestroy : Block.Block? = Block.get(blockId)

    if blockToDestroy == nil then
        warn("Destruction failed: block is nil:", player)
		return
    end

    if RoundSystem.getState() ~= "ACTIVE" and blockToDestroy.TutorialBlock == false then
		return
	end

	if PlayersInGame.isAlive(player) == false and blockToDestroy.TutorialBlock == false then
		return
	end
	
	local character = player.Character
	if not character then
		warn("Destruction failed: player has no character:", player)
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("Destruction creation failed: missing HumanoidRootPart for", player)
		return
	end

    local blockPosition = blockToDestroy:getWorldPosition()
	local distance = (blockPosition - rootPart.Position).Magnitude
	if distance > Config.BLOCK_DESTROY_THRESHOLD then
		warn("Destruction creation failed: spawn too far from player:", player)
		return
    end

	
	local block = Block.get(blockId)
	if block then
		local parentLayer = block:getParentLayer()
	
		blockDestroyed(block.id , player)
    	TileScoring.onBlockDestroyed(parentLayer.layerIndex , block.layerPosition)
		AgentMovement.onBlockDestroyed(block.id)
		block:destroy()
	end

	AmmoManager.incrementAmmo(player , Config.AMMO_GAINED_FROM_FLOOR)
	RemoteEventHandler.FireOnClient(player ,"AMMO_GAINED",  Config.AMMO_GAINED_FROM_FLOOR)



	if player and PlayersInGame.isAlive(player) then
		Onboarding.action(player , "SPADE_BROKEN_BLOCK")
	end
    RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION" , blockId , blockToDestroy , blockPosition , player , "spade")
    
end

function BlockDestruction.destroyBlockFromAgent(block : number | Block.Block) -- dont need to track from agent
	local blockToDestroy
	if block == nil then
		warn("Block to destroy cannot be nil must be a block instance or block.id.")
		return
	elseif typeof(block) == "string" or typeof(block) == "number" then
		blockToDestroy = Block.get(block)
	else
		blockToDestroy = block
	end

	if blockToDestroy == nil then
		warn("Agent destruction failed: block is nil")
		return
	end

	local parentLayer = blockToDestroy:getParentLayer()
	local blockPosition = blockToDestroy:getWorldPosition()
	
	TileScoring.onBlockDestroyed(parentLayer.layerIndex, blockToDestroy.layerPosition)
	AgentMovement.onBlockDestroyed(block.id)

	blockToDestroy:destroy()

	RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION", blockToDestroy.id, blockToDestroy, blockPosition, nil, "agent")
end

function BlockDestruction.destroyBlock(block : number | Block.Block , fromPlayer : Player?) -- will only be called on server 
	local blockToDestroy
	if block == nil then
		warn("Block to destroy cannot be nil must be a block instance or block.id.")
	elseif typeof(block) == "string" or typeof(block) == "number" then
		blockToDestroy = Block.get(block)
	else
		blockToDestroy = block
	end

	blockDestroyed(blockToDestroy.id , fromPlayer)

	if blockToDestroy == nil then
		warn("Destruction failed: block is nil")
		return
	end

	local parentLayer = blockToDestroy:getParentLayer()
	local blockPosition = blockToDestroy:getWorldPosition()

	TileScoring.onBlockDestroyed(parentLayer.layerIndex, blockToDestroy.layerPosition)
	AgentMovement.onBlockDestroyed(block.id)

	blockToDestroy:destroy()
	RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION", blockToDestroy.id, blockToDestroy, blockPosition, nil, "agent")


end

function BlockDestruction.init()
    
    RemoteEventHandler.newEventConnection("REQUEST_DESTROY_BLOCK", destroyBlockRequest)
	Agent = require(ModuleDirectory.Systems.Agent.Agent)

end

return BlockDestruction