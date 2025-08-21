local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer
local ContextService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local defaultCameraMode: Enum?
local globalCamera: Camera?
local enabled = false

local MobileCamera = {}

local function ensureCamera(): Camera
	if globalCamera == nil then
		globalCamera = workspace.CurrentCamera
	end

	return globalCamera
end

-- tweakables
local DIST_BACK = 7 -- how far behind the player (bigger = further back)
local SHOULDER_X = 3 -- right shoulder offset (negative for left shoulder)
local HEIGHT = 2 -- how high above root
local LOOK_AHEAD = 12 -- how far ahead to look past the player
local HEAD_OFFSET = 1.5 -- extra height to aim toward (head)
local SMOOTHNESS = 35 -- camera snap -> bigger = snappier

local lastCFrame: CFrame? = nil

local lastCF: CFrame? = nil

local function cameraStep(dt)
	local cam = ensureCamera()
	local char = Player.Character
	if not (char and char.PrimaryPart) then
		return
	end

	local root = char.PrimaryPart

	-- Use head if available (better match to where character "looks")
	local forward = root.CFrame.LookVector

	-- Position: offset to the shoulder, behind the character
	local camPos = (root.CFrame * CFrame.new(SHOULDER_X, HEIGHT, DIST_BACK)).Position

	-- Orient camera *parallel to the head’s facing direction*
	local desiredCF = CFrame.new(camPos, camPos + forward)

	-- Smooth lerp
	if lastCF then
		local alpha = 1 - math.exp(-SMOOTHNESS * dt)
		cam.CFrame = lastCF:Lerp(desiredCF, alpha)
	else
		cam.CFrame = desiredCF
	end

	lastCF = cam.CFrame
end

function MobileCamera.onLoaded()
	globalCamera = ensureCamera()
	if PlatformDetector.getPlatform() == "MOBILE" then
	end
end

function MobileCamera.enable() -- while enabled camera mode will be oversholder
	enabled = true

	local camera = ensureCamera()
	defaultCameraMode = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	RunService:BindToRenderStep("cameraStep", Enum.RenderPriority.Camera.Value, cameraStep)
end

function MobileCamera.disable()
	enabled = false

	RunService:UnbindFromRenderStep("cameraStep")
	local camera = ensureCamera()
	camera.CameraType = defaultCameraMode or Enum.CameraType.Follow
end

return MobileCamera
