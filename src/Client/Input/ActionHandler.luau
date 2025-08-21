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

local camera : Camera? = nil

local ActionHandler = {}

function ActionHandler.init()
	local binding1 = InputHandler.bindActionStart(Enum.UserInputType.MouseButton1, ActionHandler.mainAttack)
	--local binding2 = InputHandler.bindActionEnd(Enum.UserInputType.Touch, ActionHandler.mainAttack)
end

local lastClickTime = 0
local HIT_COOLDOWN = 0.1
local RAY_MAX = 1000

local out_count = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.CollisionGroup = "CG_BLOCK_SELECTION"

local function ensureCamera(): Camera?
    if not camera or camera.Parent == nil then
        camera = workspace.CurrentCamera
    end
    return camera
end

function ActionHandler.canAttack()

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

function ActionHandler.getDirection(_action, headPart: Part): Vector3
	local cam = ensureCamera()
	if not cam then
		return Vector3.new(0, 0, -1)
	end

	local aimPoint: Vector3?

	if PlatformDetector.getPlatform() == "PC" then
		if mouse and mouse.Hit then
			aimPoint = mouse.Hit.Position
		end
	end

	if not aimPoint then
		-- Use center-screen ray (works for MOBILE and PC fallback)
		local viewport = cam.ViewportSize
		local center = viewport * 0.5
		local unitRay = cam:ViewportPointToRay(center.X, center.Y)
		local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * RAY_MAX, rayParams)
		if result then
			aimPoint = result.Position
		else
			aimPoint = unitRay.Origin + unitRay.Direction * RAY_MAX
		end
	end

	local fromHead = (aimPoint - headPart.Position)
	if fromHead.Magnitude <= 1e-6 then
		return cam.CFrame.LookVector.Unit
	end
	return fromHead.Unit
end

function ActionHandler.mainAttack(action)
	if ActionHandler.canAttack() then
		local character = player.Character
		local headPart = character:FindFirstChild("Head")

		local selectedBlock =ClientBlockSelector.getSelected()

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
