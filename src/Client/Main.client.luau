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
		local headPart = character:FindFirstChild("Head")
		if not rootPart then
			warn("Cannot throw snowball: missing HumanoidRootPart for", player)
			return
		end

		local playerPosition = headPart.Position

		local targetPosition = mouse.Hit.p
		local direction = (targetPosition - playerPosition).Unit

		RemoteEventHandler.FireOnServer("CREATE_SNOWBALL", playerPosition, direction)
	end
end)

print(binding1)

local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)

ClientThrowableTracker.registerOnHit("snowball" , function(throwable : ClientThrowableTracker.Throwable , hit)
	if hit.Instance and hit.Instance:IsA("Part") then
		
		--ClientDestructionHandler.destroyBlock(hit.Instance)

	end
end)

local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)

local AlertSystem = require(ClientModuleDirectory.GUI.AlertSystem)

local n = 0

