local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Player = game.Players.LocalPlayer
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local player = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local mouse = player:GetMouse()
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserInputService

local ActionHandler = {}

function ActionHandler.init()
	local binding1 = InputHandler.bindActionStart(Enum.UserInputType.MouseButton1, ActionHandler.mainAttack)
	local binding2 = InputHandler.bindActionEnd(Enum.UserInputType.Touch, ActionHandler.mainAttack)
end

local lastClickTime = 0
local HIT_COOLDOWN = 0.1
local out_count = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.CollisionGroup = "CG_BLOCK_SELECTION"

function ActionHandler.canAttack(action)
	local data = action.data

	if tick() - lastClickTime < HIT_COOLDOWN then
		return false
	end
	lastClickTime = tick()

	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local headPart = character:FindFirstChild("Head")
	if (not rootPart) or not headPart then
		return false
	end
	if ClientStateTracker.getState() ~= "ACTIVE" then
		return false
	end

	if ClientStateTracker.getServerState() ~= "ACTIVE" then
		return false
	end

	if not character:FindFirstChild("Shovel") then
		return false
	end

	return true
end

function ActionHandler.getSelected(action)
	if PlatformDetector.getPlatform() == "PC" then
		return ClientBlockSelector.getSelected()
	else
		local tapPosition = Vector2.new(action.input.Position.X, action.input.Position.Y)
		return ClientBlockSelector.getMobileSelected(tapPosition)
	end
end

function ActionHandler.getDirection(action, headPart: Part)
	if PlatformDetector.getPlatform() == "PC" then
		return (mouse.Hit.Position - headPart.Position).Unit
	elseif PlatformDetector.getPlatform() == "MOBILE" then
		local tapPos = Vector2.new(action.input.Position.X, action.input.Position.Y)
		local unitRay = game.Workspace.CurrentCamera:ViewportPointToRay(tapPos.X, tapPos.Y)
		local targetPos = unitRay.Origin + unitRay.Direction * 1000
		return (targetPos - headPart.Position).Unit
	end
end

function ActionHandler.mainAttack(action)
	if ActionHandler.canAttack(action) then
		local character = player.Character
		local headPart = character:FindFirstChild("Head")

		local selectedBlock = ActionHandler.getSelected(action)

		if selectedBlock then -- destroy with spade
			local id = selectedBlock:GetAttribute("Id")
			RemoteEventHandler.FireOnServer("REQUEST_DESTROY_BLOCK", id)
			ClientDestructionHandler.predictBlockDestroy(selectedBlock)
			return
		else -- shoot
			if ClientAmmoTracker.getAmmo() <= 0 then
				out_count += 1
				if out_count >= 7 then
					--InGameHUD.showHint()
				end
				
				SoundPlayer.playSound("rbxassetid://9125655693")
				return
			else
				out_count = 0
			end
		end

		local direction = ActionHandler.getDirection(action, headPart)
		local playerPosition = headPart.Position
		--ClientAmmoTracker.predictIncrement(-1)
		RemoteEventHandler.FireOnServer("CREATE_SNOWBALL", playerPosition, direction)
	end
end

return ActionHandler
