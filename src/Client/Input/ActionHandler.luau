local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Player = game.Players.LocalPlayer
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local InputHandler = require(ClientModuleDirectory.InputHandler)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)
local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)
local player = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local mouse = player:GetMouse()
local PlatformDetector = require(ClientModuleDirectory.PlatformDetector)
local UserInputService

local ActionHandler = {}

function ActionHandler.init()
	local binding1 = InputHandler.bindActionStart(Enum.UserInputType.MouseButton1, ActionHandler.mainAttack)
	local binding2 = InputHandler.bindActionEnd(Enum.UserInputType.Touch, ActionHandler.mainAttack)
end

local lastClickTime = 0
local HIT_COOLDOWN = 0.1

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.CollisionGroup = "CG_BLOCK_SELECTION"

function ActionHandler.mainAttack(action)
	local data = action.data

	if tick() - lastClickTime < HIT_COOLDOWN then
		return
	end
	lastClickTime = tick()

	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local headPart = character:FindFirstChild("Head")
	if not rootPart then
		return
	end

	if ClientStateTracker.getState() ~= "ACTIVE" then
		return
	end

	if not character:FindFirstChild("Shovel") then
		return
	end

	local selectedBlock
	if PlatformDetector.getPlatform() == "PC" then
		print("pc")
		selectedBlock = ClientBlockSelector.getSelected()
	else
		local tapPosition = Vector2.new(action.input.Position.X, action.input.Position.Y)
		selectedBlock = ClientBlockSelector.getMobileSelected(tapPosition)
	end

	if selectedBlock then
		local id = selectedBlock:GetAttribute("Id")
		RemoteEventHandler.FireOnServer("REQUEST_DESTROY_BLOCK", id)
		ClientDestructionHandler.predictBlockDestroy(selectedBlock)
		return
	end

	if ClientAmmoTracker.getAmmo() <= 0 then
		SoundPlayer.playSound("rbxassetid://9125655693")
		return
	end

	if ClientStateTracker.getServerState() ~= "ACTIVE" then
		return
	end

	local direction = nil
	-- MOUSE HIT X AND Y = action.input.Position.X , action.input.Position.Y
	if PlatformDetector.getPlatform() == "PC" then
		direction = (mouse.Hit.Position - headPart.Position).Unit
	elseif PlatformDetector.getPlatform() == "MOBILE" then
		local tapPos = Vector2.new(action.input.Position.X, action.input.Position.Y)

		local unitRay = game.Workspace.CurrentCamera:ViewportPointToRay(tapPos.X, tapPos.Y)

		local targetPos = unitRay.Origin + unitRay.Direction * 1000

		direction = (targetPos - headPart.Position).Unit
	end
	local playerPosition = headPart.Position

	--ClientAmmoTracker.predictIncrement(-1)
	RemoteEventHandler.FireOnServer("CREATE_SNOWBALL", playerPosition, direction)
end

return ActionHandler
