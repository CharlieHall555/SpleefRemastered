local RunService = game:GetService("RunService")
local ChatService = game:GetService("TextChatService")
local SystemMessage = {}

local EventHandler
local ModuleDirectory

function SystemMessage.ReceiveMessage(Message: string, MessageColor: Color3): nil
	assert(RunService:IsClient(), "Cannot be run from server.")

	local TextChannel: TextChannel = ChatService.TextChannels.RBXGeneral
	assert(TextChannel, "text channel missing.")
	TextChannel:DisplaySystemMessage(Message)
end

function SystemMessage.init()
	if RunService:IsServer() then
		ModuleDirectory = require(game:GetService("ServerScriptService"):WaitForChild("ModuleDirectory") , 5)
        EventHandler = require(ModuleDirectory.RemoteEventHandler)

	else
		ModuleDirectory = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("ClientModuleDirectory") , 5)
        EventHandler = require(ModuleDirectory.RemoteEventHandler)
        EventHandler.newEventConnection("SendMessage", SystemMessage.ReceiveMessage)
	end
    EventHandler = require(ModuleDirectory.RemoteEventHandler)

    assert(EventHandler , "EventHandler missing.")
    assert(ModuleDirectory , "ModuleDirectory missing.")

end

function SystemMessage.SendMessageToClient(Client: Player, Message: string, MessageColor: Color3): nil
	assert(RunService:IsServer(), "Cannot be run from client.")
	EventHandler.FireOnClient("SendMessage", Message, MessageColor)
end

function SystemMessage.SendMessageToAllClients(Message: string, MessageColor: Color3): nil
	assert(RunService:IsServer(), "Cannot be run from client.")
	EventHandler.FireOnAllClients("SendMessage", Message, MessageColor)
end

return SystemMessage
