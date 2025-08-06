local Root = script.Parent
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientLoader = require(Root.Core.ClientLoader)
ClientLoader.init()

local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
RemoteEventHandler.FireOnServer("PLAYER_LOADED")

local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)

local ClientThrowableTracker = require(ClientModuleDirectory.ClientThrowableTracker)

local InputHandler = require(ClientModuleDirectory.InputHandler)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local binding1 = InputHandler.bindAction(Enum.UserInputType.MouseButton1, function(action)

	if action.context == "GAME" then
		local character = player.Character or player.CharacterAdded:Wait()
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			warn("Cannot throw snowball: missing HumanoidRootPart for", player)
			return
		end

		local playerPosition = rootPart.Position

		local targetPosition = mouse.Hit.p
		local direction = (targetPosition - playerPosition).Unit

		RemoteEventHandler.FireOnServer("CREATE_SNOWBALL", playerPosition, direction)
	end
end)

print(binding1)
