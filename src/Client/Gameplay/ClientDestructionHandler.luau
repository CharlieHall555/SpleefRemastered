local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local LocalPlayer = game.Players.LocalPlayer
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local TutorialAmmo = require(ClientModuleDirectory.Gui.TutorialAmmo)


local REINSTATEMENT_THRESHOLD = 0.5

-- maps blockId to the Part instance awaiting server confirmation
local _awaitingConfirmation: { [number]: Part } = {}

local ClientDestructionHandler = {}

function ClientDestructionHandler.predictBlockDestroy(block: Part)
	local blockId = block:GetAttribute("Id")
	if not blockId then
		return
	end
	if block.Transparency ~= 0 then
		return
	end

	--SoundPlayer.queuePositionalSound("rbxassetid://90611947337807", block.Position, { volume = 0.5 })
	local blockType = block:GetAttribute("Type") or "grass"
	ParticlePlayer.queueEmission(blockType, block.Position, 12)
	block.Transparency = 1

	if ClientStateTracker.getState() == "TUTORIAL" and block:HasTag("TutorialBlock") then
		TutorialAmmo.increment(1)
	end

	if (block:GetAttribute("Regenerates") or false) == false then
		_awaitingConfirmation[blockId] = block

		task.delay(REINSTATEMENT_THRESHOLD, function()
			local pendingBlock = _awaitingConfirmation[blockId]
			if pendingBlock and pendingBlock.Parent then
				pendingBlock.Transparency = 0
			end
			_awaitingConfirmation[blockId] = nil
		end)
	end
end

function ClientDestructionHandler:init()
	RemoteEventHandler.newEventConnection("BLOCK_DESTROY_CONFIRMATION", ClientDestructionHandler.receiveDestroyedBlock)
end

function ClientDestructionHandler.receiveDestroyedBlock(
	blockId: number,
	type: string,
	blockWorldPosition: Vector3,
	player: Player?,
	method: string?
)
	_awaitingConfirmation[blockId] = nil
	if player == LocalPlayer and method == "spade" then
		SoundPlayer.queuePositionalSound("block_break",blockWorldPosition, { volume = 0.3 , playbackSpeed = 0.9 })	
	end
end

return ClientDestructionHandler
