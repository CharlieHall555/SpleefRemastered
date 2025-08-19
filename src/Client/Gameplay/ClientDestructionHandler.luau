local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local LocalPlayer = game.Players.LocalPlayer
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)


local REINSTATEMENT_THRESHOLD = 0.5

-- maps blockId to the Part instance awaiting server confirmation
local _awaitingConfirmation: { [number]: Part } = {}

local ClientDestructionHandler = {}

function ClientDestructionHandler.predictBlockDestroy(block: Part)
	local blockId = block:GetAttribute("Id")
	if not blockId then
		return
	end
	block.Transparency = 1
	SoundPlayer.queuePositionalSound("rbxassetid://90611947337807", block.Position, { volume = 0.5 })
	local blockType = block:GetAttribute("Type") or "grass"
	ParticlePlayer.queueEmission(blockType , block.Position , 12)

	_awaitingConfirmation[blockId] = block

	task.delay(REINSTATEMENT_THRESHOLD, function()
		local pendingBlock = _awaitingConfirmation[blockId]
		if pendingBlock and pendingBlock.Parent then
			pendingBlock.Transparency = 0
		end
		_awaitingConfirmation[blockId] = nil
	end)
end

function ClientDestructionHandler:init()
	RemoteEventHandler.newEventConnection("BLOCK_DESTROY_CONFIRMATION",ClientDestructionHandler.receiveDestroyedBlock)
end

function ClientDestructionHandler.receiveDestroyedBlock(
	blockId: number,
	type: string,
	blockWorldPosition: Vector3,
	player: Player?,
	method: string?
)
    print(player , LocalPlayer)
    _awaitingConfirmation[blockId] = nil
    if player == LocalPlayer and method == "spade" then
		--SoundPlayer.queuePositionalSound("rbxassetid://90611947337807", blockWorldPosition, { volume = 0.5 })
	elseif method == "snowball" then
		ParticlePlayer.queueEmission("PARTICLE_SNOWBALL" , blockWorldPosition + Vector3.new(0 , 3 , 0) , 12)
		SoundPlayer.queuePositionalSound("rbxassetid://9119310655", blockWorldPosition, { volume = 0.75  , playbackSpeed = 1.2})
    end
	
end

return ClientDestructionHandler
