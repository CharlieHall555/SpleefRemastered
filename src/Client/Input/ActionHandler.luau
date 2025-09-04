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
local SpectateController = require(ClientModuleDirectory.Spectate.Controller)
local ClientTutorial = require(ClientModuleDirectory.ClientTutorial)



local camera: Camera? = nil

local ActionHandler = {}

function ActionHandler.init()
	local binding1 = InputHandler.bindActionStart(Enum.UserInputType.MouseButton1, ActionHandler.mainAttack)
end

local lastClickTime = 0
local HIT_COOLDOWN = 0.1
local RAY_MAX = 1000

local out_count = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.CollisionGroup = "CG_GAMEPLAY"

local function ensureCamera(): Camera?
	if not camera or camera.Parent == nil then
		camera = workspace.CurrentCamera
	end
	return camera
end

function ActionHandler.canAttack()
	if time() - lastClickTime < HIT_COOLDOWN then
		return false
	end
	lastClickTime = time()

	if SpectateController.getEnabled() then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local headPart = character:FindFirstChild("Head")
	if (not rootPart) or not headPart then
		return false
	end

	if ClientStateTracker.getState() == "ACTIVE" and ClientStateTracker.getServerState() == "PREPARING" then
		return
	end

	return true
end

-- Computes a direction from a screen point (shared helper).
local function directionFromScreenPoint(cam: Camera, spawnPart: BasePart, screenX: number, screenY: number): Vector3
	-- Avoid hitting our own character
	if spawnPart and spawnPart.Parent then
		rayParams.FilterDescendantsInstances = { spawnPart.Parent }
	else
		rayParams.FilterDescendantsInstances = {}
	end

	local unitRay = cam:ViewportPointToRay(screenX, screenY)
	local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * RAY_MAX, rayParams)
	local target: Vector3 = hit and hit.Position or (unitRay.Origin + unitRay.Direction * RAY_MAX)

	local fromSpawn = target - spawnPart.Position
	if fromSpawn.Magnitude < 1e-6 then
		return cam.CFrame.LookVector.Unit
	end
	return fromSpawn.Unit
end

-- PC: uses the mouse position; falls back to center if unavailable.
function ActionHandler.getDirectionPC(): Vector3
	local cam = ensureCamera()
	if not cam then
		return Vector3.new(0, 0, -1)
	end

	if not Player.Character then
		return
	end

	local headPart = player.Character:FindFirstAncestor("Head") or player.Character.PrimaryPart

	if mouse and mouse.Hit then
		local target = mouse.Hit.Position
		local v = target - headPart.Position
		if v.Magnitude <= 1e-6 then
			return cam.CFrame.LookVector.Unit
		end
		return v.Unit
	end

	local center = cam.ViewportSize * 0.5
	local unitRay = cam:ViewportPointToRay(center.X, center.Y)
	local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * RAY_MAX, rayParams)
	local target = hit and hit.Position or (unitRay.Origin + unitRay.Direction * RAY_MAX)
	local v2 = target - headPart.Position
	if v2.Magnitude <= 1e-6 then
		return cam.CFrame.LookVector.Unit
	end
	return v2.Unit
end

-- Phone: uses the reticle GUI position if provided; otherwise center screen.
function ActionHandler.getDirectionMobile(spawnPart: BasePart, reticleGui: GuiObject?): Vector3
	local cam = ensureCamera()
	if not cam then
		return Vector3.new(0, 0, -1)
	end

	local screenX: number, screenY: number
	if reticleGui then
		local absPos = reticleGui.AbsolutePosition
		local absSize = reticleGui.AbsoluteSize
		screenX = absPos.X + absSize.X * 0.5
		screenY = absPos.Y + absSize.Y * 0.5
	else
		local center = cam.ViewportSize * 0.5
		screenX, screenY = center.X, center.Y
	end

	return directionFromScreenPoint(cam, spawnPart, screenX, screenY)
end

-- Optional: keep your original entry point as a dispatcher so existing code doesn’t break.
function ActionHandler.getDirection(_action, spawnPart: BasePart, reticleGui: GuiObject?): Vector3
	if PlatformDetector.getPlatform() == "PC" then
		return ActionHandler.getDirectionPC()
	else
		return ActionHandler.getDirectionMobile(spawnPart, reticleGui)
	end
end

function ActionHandler.mainAttack(action)
	if ActionHandler.canAttack() then
		local character = player.Character
		local headPart = character:FindFirstChild("Head")

		if not character:FindFirstChild("Shovel") then
			local shovel = player.Backpack:FindFirstChild("Shovel")
			if shovel and shovel:IsA("Tool") then
				character.Humanoid:EquipTool(shovel)
			else
				return
			end
		end

		

		print(ClientAmmoTracker.getIsInfinite())
		print(ClientAmmoTracker.getAmmo() <= 0 and ClientAmmoTracker.getIsInfinite() == false)

		local selectedBlock = ClientBlockSelector.getSelected()
		print(selectedBlock)

		if selectedBlock then -- destroy with spade
			local id = selectedBlock:GetAttribute("Id")
			print("woop")
			RemoteEventHandler.FireOnServer("REQUEST_DESTROY_BLOCK", id)
			ClientTutorial.onAction("BREAK")
			ClientDestructionHandler.predictBlockDestroy(selectedBlock)
			return
		else -- shoot
			if ClientAmmoTracker.getAmmo() <= 0 and ClientAmmoTracker.getIsInfinite() == false and ClientStateTracker.getState() == "ACTIVE" then
				out_count += 1
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
		ClientTutorial.onAction("SHOOT")

	end
end

return ActionHandler
