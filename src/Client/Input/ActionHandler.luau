local LocalizationService = game:GetService("LocalizationService")
local StarterGui = game:GetService("StarterGui")
local TextService = game:GetService("TextService")
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
local TutorialAmmo = require(ClientModuleDirectory.Gui.TutorialAmmo)
local AmmoGui = require(ClientModuleDirectory.Gui.Ammo)
local ClientToolManager = require(ClientModuleDirectory.ClientToolManager)
local AnimationManager = require(ClientModuleDirectory.AnimationManager)
local RoundStatus = require(ClientModuleDirectory.Gui.RoundStatus)
local VibrationService = require(ClientModuleDirectory.VibrationService)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local camera: Camera? = nil

local ActionHandler = {}

function ActionHandler.init()
	local binding1 = InputHandler.bindActionStart(Enum.UserInputType.MouseButton1, ActionHandler.mainAttack)
end

local lastClickTime = 0
local HIT_COOLDOWN = 0.1
local RAY_MAX = 1000

local THROW_SOUND = "rbxassetid://129467477219437"
local OUT_SOUND = "rbxassetid://9125655693"

local out_count = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.CollisionGroup = "default"

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

	return true
end



-- PC: uses the mouse position; falls back to center if unavailable.
local GuiService = game:GetService("GuiService")

local EPSILON = 1e-6
local DEFAULT_DIR = Vector3.new(0, 0, -1)

function ActionHandler.getDirectionPC(): Vector3
	local cam = ensureCamera()
	if not cam then
		return DEFAULT_DIR
	end

	if not player or not player.Character then
		return cam.CFrame.LookVector
	end

	-- Find a sensible head reference
	local headPart = player.Character:FindFirstChild("Head")
	if not headPart then
		headPart = player.Character.PrimaryPart
	end
	if not headPart then
		return cam.CFrame.LookVector
	end

	-- Prefer mouse world hit if available
	if mouse and mouse.Hit then
		local target = mouse.Hit.Position
		local v = target - headPart.Position
		if v.Magnitude <= EPSILON then
			return cam.CFrame.LookVector
		else
			return v.Unit
		end
	end

	-- Fallback: screen-center ray that respects CoreGui safe insets (mobile, notch, etc.)
	local topLeftInset, bottomRightInset = GuiService:GetGuiInset()
	local viewportSize = cam.ViewportSize

	local safeWidth = viewportSize.X - topLeftInset.X - bottomRightInset.X
	local safeHeight = viewportSize.Y - topLeftInset.Y - bottomRightInset.Y

	local centerX = topLeftInset.X + (safeWidth * 0.5)
	local centerY = topLeftInset.Y + (safeHeight * 0.5)

	local unitRay = cam:ViewportPointToRay(centerX, centerY)
	local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * RAY_MAX, rayParams)

	local target
	if hit then
		target = hit.Position
	else
		target = unitRay.Origin + unitRay.Direction * RAY_MAX
	end

	local v2 = target - headPart.Position
	if v2.Magnitude <= EPSILON then
		return cam.CFrame.LookVector
	else
		return v2.Unit
	end
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

-- Phone: uses the reticle GUI position if provided; otherwise center screen.
function ActionHandler.getDirectionMobile(spawnPart: BasePart, reticleGui: GuiObject?): Vector3
	local cam = ensureCamera()
	if not cam then
		return Vector3.new(0, 0, -1)
	end

	local screenSize = Screens:getGeneralSize()
	local center = (screenSize)* 0.5 
	local screenX, screenY = center.X, center.Y

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

		if ClientToolManager.isToolEquipped() == false then
			ClientToolManager.equipTool()
		end

		local selectedBlock = ClientBlockSelector.getSelected()

		if ClientStateTracker.getState() == "ACTIVE" and ClientStateTracker.getServerState() == "PREPARING" then
			local errorBlip = "rbxassetid://70373378044427"
			SoundPlayer.playSound(errorBlip, { volume = 1.5 })
			RoundStatus.shakePrepare()
			VibrationService.light()
			return
		end

		if selectedBlock then -- destroy with spade
			local id = selectedBlock:GetAttribute("Id")
			RemoteEventHandler.FireOnServer("REQUEST_DESTROY_BLOCK", id)
			ClientTutorial.onAction("BREAK")
			ClientDestructionHandler.predictBlockDestroy(selectedBlock)
			return
		else -- shoot
			if
				(ClientStateTracker.getState() == "ACTIVE" or ClientStateTracker.getState() == "TUTORIAL")
				and ClientAmmoTracker.getAmmo() <= 0
				and ClientAmmoTracker.getIsInfinite() == false
			then
				AmmoGui.shake()
				SoundPlayer.playSound(OUT_SOUND)
				VibrationService.light()

				return
			elseif ClientStateTracker.getState() == "TUTORIAL" and TutorialAmmo.getState().current <= 0 then
				SoundPlayer.playSound(OUT_SOUND)
				VibrationService.light()

				return
			else
				out_count = 0
			end
		end

		local direction = ActionHandler.getDirection(action, headPart)
		local playerPosition = headPart.Position

		if ClientStateTracker.getState() == "TUTORIAL" then
			TutorialAmmo.increment(-1)
		end

		--ClientAmmoTracker.predictIncrement(-1)#l
		local tool = ClientToolManager.getTool()
		if tool and tool.Name == "Snowball" then
			local snowballThrowAnim = "rbxassetid://136985168029082"
			AnimationManager.playAnimation(snowballThrowAnim)
		end

		SoundPlayer.playSound(THROW_SOUND)
		RemoteEventHandler.FireOnServer("REQUEST_SNOWBALL", playerPosition, direction)
		ClientTutorial.onAction("SHOOT")
	end
end

return ActionHandler
