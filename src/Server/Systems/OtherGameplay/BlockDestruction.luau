local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockFactory = require(ModuleDirectory.Systems.Map.BlockFactory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local LoadedBlocks = require(ModuleDirectory.Systems.Map.LoadedBlocks)
local Config =require(game:GetService("ServerScriptService").ServerConfigurations)
local Block = require(ModuleDirectory.Systems.Map.Block)
local AmmoManager = require(ModuleDirectory.Systems.Ammo.AmmoManager)
local Onboarding = require(ModuleDirectory.Services.Analytics.Onboarding)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)

local BlockDestruction = {}

local Agent

function BlockDestruction.init()
    
    RemoteEventHandler.newEventConnection("REQUEST_DESTROY_BLOCK", BlockDestruction.destroyBlockFor)
	Agent = require(ModuleDirectory.Systems.Agent.Agent)

end

function BlockDestruction.destroyBlockFor(player : Player , blockId : number)

	print("destory request")

    local blockToDestroy : Block.Block? = LoadedBlocks[blockId]

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

    local blockPosition = blockToDestroy.Part.Position
	local distance = (blockPosition - rootPart.Position).Magnitude
	if distance > Config.BLOCK_DESTROY_THRESHOLD then
		warn("Destruction creation failed: spawn too far from player:", player)
		return
    end

    BlockFactory.destroyById(blockId , player)
	AmmoManager.incrementAmmo(player , Config.AMMO_GAINED_FROM_FLOOR)
	RemoteEventHandler.FireOnClient(player ,"AMMO_GAINED",  Config.AMMO_GAINED_FROM_FLOOR)


	if player and PlayersInGame.isAlive(player) then
		Onboarding.action(player , "SPADE_BROKEN_BLOCK")
	end
    RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION" , blockId , blockToDestroy , blockPosition , player , "spade")
    
end

function BlockDestruction.destroyBlockAgent(blockId : number) -- will only be called on server 
	local blockToDestroy : Block.Block? = LoadedBlocks[blockId]

	if blockToDestroy == nil then
		warn("Agent destruction failed: block is nil")
		return
	end

	if RoundSystem.getState() ~= "ACTIVE" and blockToDestroy.TutorialBlock == false then
		return
	end

	local blockPosition = blockToDestroy.Part.Position
	BlockFactory.destroyById(blockId, Agent)
	
	RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION", blockId, blockToDestroy, blockPosition, nil, "spade")
end



return BlockDestruction