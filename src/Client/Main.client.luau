local Root = script.Parent
local QueryLoaded = game:GetService("ReplicatedStorage"):WaitForChild("QueryLoaded")
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Player = game.Players.LocalPlayer
local loadingScreen = Player.PlayerGui:WaitForChild("Loading")
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local VectorUtil = require(ClientModuleDirectory.VectorUtil)

local isServerLoaded = false
while isServerLoaded == false do
	isServerLoaded = QueryLoaded:InvokeServer()
	print(isServerLoaded)
	task.wait(0.1)
end

local ClientLoader = require(Root.Core.ClientLoader)
ClientLoader.init()
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local ProfileLoaded = false
while ProfileLoaded == false do
	ProfileLoaded = RemoteEventHandler.InvokeOnServer("QUERY_PROFILE_LOAD")
	print("profileload" , ProfileLoaded)
	task.wait(0.1)
end

ClientLoader.profileLoaded()

pcall(function()
	loadingScreen.removeEvent:Fire()
end)

RemoteEventHandler.FireOnServer("PLAYER_LOADED")

local ClientThrowableTracker = require(ClientModuleDirectory.ClientThrowableTracker)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local InputHandler = require(ClientModuleDirectory.InputHandler)
local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local binding1 = InputHandler.bindAction(Enum.UserInputType.MouseButton1, function(action)

	if action.context == "GAME" then
		local character = player.Character or player.CharacterAdded:Wait()
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local headPart = character:FindFirstChild("Head")
		if not rootPart then
			return
		end

		if character:FindFirstChild("Shovel") == nil then
			return
		end

		if ClientAmmoTracker.getAmmo() <= 0 then
			return
		end

		if ClientStateTracker.getServerState() ~= "ACTIVE" then
			return
		end

		local selectedBlock = ClientBlockSelector.getSelected() 

		if selectedBlock then
			local id = selectedBlock:GetAttribute("Id")
			RemoteEventHandler.FireOnServer("REQUEST_DESTROY_BLOCK", id)
			ClientDestructionHandler.predictBlockDestroy(selectedBlock)
			return
		end

		local playerPosition = headPart.Position

		local direction = (mouse.Hit.Position - headPart.Position).Unit

		--ClientAmmoTracker.predictIncrement(-1)
		RemoteEventHandler.FireOnServer("CREATE_SNOWBALL", playerPosition, direction)

	end
end)

print(binding1)

HitBoxManager.setUpCallback("SNOWBALL_AMMO" , function(otherPart : Part)
	
	local increment = otherPart:GetAttribute("Increment") or 1
	--ClientAmmoTracker.predictIncrement(increment)
	otherPart.Transparency = 1

end)

local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)

ClientThrowableTracker.registerOnHit("snowball" , function(throwable : ClientThrowableTracker.Throwable , hit)
	if hit.Instance and hit.Instance:IsA("Part") then
		--redudant client side destruction prediciton became to hard to sync so stopped work for now.
		--ClientDestructionHandler.destroyBlock(hit.Instance)

	end
end)



local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)

local AlertSystem = require(ClientModuleDirectory.GUI.AlertSystem)

local n = 0

local SystemMessage = require(ClientModuleDirectory.SystemMessage)

local MouseIcon = require(ClientModuleDirectory.MouseIcon)

