local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local LoadedBlocks = require(ModuleDirectory.LoadedBlocks)
local Config =require(game:GetService("ServerScriptService").ServerConfigurations)
local Block = require(ModuleDirectory.Map.Block)
local AmmoManager = require(ModuleDirectory.Throwable.AmmoManager)

local BlockDestruction = {}

function BlockDestruction.init()
    
    RemoteEventHandler.newEventConnection("REQUEST_DESTROY_BLOCK", BlockDestruction.destroyBlockFor)

end

function BlockDestruction.destroyBlockFor(player : Player , blockId : number)

    local blockToDestroy : Block.Block? = LoadedBlocks[blockId]

    if blockToDestroy == nil then
        warn("Destruction failed: block is nil:", player)
		return
    end

    if RoundSystem.getState() ~= "ACTIVE" then
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
	AmmoManager.incrementAmmo(player , 5)

	if player.owner then
		Onboarding.action(player.owner , "SPADE_BROKEN_BLOCK")
	end

    RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION" , blockId , blockToDestroy , blockPosition , player , "spade")
    
end

return BlockDestruction