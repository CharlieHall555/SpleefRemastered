local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local REINSTATEMENT_THRESHOLD = 0.5

-- maps blockId to the Part instance awaiting server confirmation
local _awaitingConfirmation: { [number]: Part } = {}

local ClientDestructionHandler = {}

function ClientDestructionHandler.destroyBlock(block: Part)
    local blockId = block:GetAttribute("Id")
    if not blockId then
        return
    end
    block.Transparency = 1
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
    RemoteEventHandler.newEventConnection("BLOCK_DESTROY_CONFIRMATION", function(blockId: number)
        ClientDestructionHandler.receiveDestroyedBlock(blockId)
    end)
end

function ClientDestructionHandler.receiveDestroyedBlock(blockId: number)
    _awaitingConfirmation[blockId] = nil
end

return ClientDestructionHandler