local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local CrossHair = require(ClientModuleDirectory.Gui.CrossHair)
local AimAssistController = require(ClientModuleDirectory.Input.AimAssistController)

local LocalPlayer = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local gameSettings = UserSettings().GameSettings

local MobileCamera = {}

-- camera state
local _defaultCameraMode: Enum.CameraType?
local _globalCamera: Camera?
local enabled = false

-- tweakables
local BASE_DIST = 7
local MIN_ZOOM = 3
local MAX_ZOOM = 14
local SHOULDER_X = 4
local HEIGHT = 2
local SMOOTHNESS = 35
local PITCH_MIN = math.rad(-75)
local PITCH_MAX = math.rad(75)

-- aim assist
local AIM_ASSIST_ENABLED = true
local AIM_ASSIST_GAIN = 3 -- scales suggested deltas per second

-- runtime state
local _pitch = 0
local _distance = BASE_DIST
local _lastCF: CFrame? = nil
local _sensitivityX = 0
local _sensitivityY = 0
local _pendingYawDelta = 0

local function ensureCamera(): Camera
    if _globalCamera == nil then
        _globalCamera = workspace.CurrentCamera
    end
    return _globalCamera
end

local function getHumanoid(character: Model?): Humanoid?
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function applyYawToCharacter(yawDelta: number)
    if yawDelta == 0 then
        return
    end
    local character = LocalPlayer.Character
    if not (character and character.PrimaryPart) then
        return
    end

    local humanoid = getHumanoid(character)
    if humanoid then
        humanoid.AutoRotate = false
    end

    local current = character:GetPivot()
    character:PivotTo(current * CFrame.Angles(0, yawDelta, 0))
end

local function cameraStep(dt: number)
    local cam = ensureCamera()
    local character = LocalPlayer.Character
    if not (character and character.PrimaryPart) then
        return
    end

    local currentCamCF = _lastCF or cam.CFrame

    if AIM_ASSIST_ENABLED then
        local suggestion = AimAssistController.aimSuggestion(currentCamCF)
        if suggestion then
            local gain = AIM_ASSIST_GAIN * math.clamp(suggestion.strength or 0, 0, 1) * dt
            _pendingYawDelta += (suggestion.deltaYaw or 0) * gain
            _pitch = math.clamp(_pitch + (suggestion.deltaPitch or 0) * gain, PITCH_MIN, PITCH_MAX)
        end
    end

    if _pendingYawDelta ~= 0 then
        applyYawToCharacter(_pendingYawDelta)
        _pendingYawDelta = 0
    end

    local rootCF = character:GetPivot()
    local focusCF = rootCF * CFrame.new(0, HEIGHT, 0) * CFrame.Angles(_pitch, 0, 0)
    local desired = focusCF * CFrame.new(SHOULDER_X, 0, _distance)

    if _lastCF then
        local alpha = 1 - math.exp(-SMOOTHNESS * dt)
        cam.CFrame = _lastCF:Lerp(desired, alpha)
    else
        cam.CFrame = desired
    end

    _lastCF = cam.CFrame
end

function MobileCamera.init()
    _sensitivityX = 0.017
    _sensitivityY = 0.011

    gameSettings["RotationType"] = Enum.RotationType.MovementRelative

    if AIM_ASSIST_ENABLED then
        AimAssistController.init()
    end

    LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 2)
        if humanoid and enabled then
            humanoid.AutoRotate = false
        end
    end)
end

function MobileCamera.onLoaded()
    _globalCamera = ensureCamera()
end

function MobileCamera.enable()
    if enabled then
        return
    end
    if PlatformDetector.getPlatform() ~= "MOBILE" then
        return
    end
    enabled = true
    CrossHair.show()

    local camera = ensureCamera()
    _defaultCameraMode = camera.CameraType
    camera.CameraType = Enum.CameraType.Scriptable

    RunService:BindToRenderStep("MobileShoulderCamera", Enum.RenderPriority.Camera.Value, cameraStep)
end

function MobileCamera.disable()
    if not enabled then
        return
    end
    enabled = false
    CrossHair.hide()

    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = true
        end
    end

    RunService:UnbindFromRenderStep("MobileShoulderCamera")
    local camera = ensureCamera()
    camera.CameraType = _defaultCameraMode or Enum.CameraType.Follow
    _lastCF = nil
end

-- controls

function MobileCamera.look(deltaX: number, deltaY: number)
    _pendingYawDelta += deltaX * _sensitivityX
    _pitch = math.clamp(_pitch + deltaY * _sensitivityY, PITCH_MIN, PITCH_MAX)
end

function MobileCamera.zoomBy(delta: number)
    _distance = math.clamp(_distance + delta, MIN_ZOOM, MAX_ZOOM)
end

function MobileCamera.setZoom(target: number)
    _distance = math.clamp(target, MIN_ZOOM, MAX_ZOOM)
end

function MobileCamera.resetOrientation()
    _pitch = 0
end

function MobileCamera.getState()
    return {
        enabled = enabled,
        pitch = _pitch,
        distance = _distance,
        sensitivityX = _sensitivityX,
        sensitivityY = _sensitivityY
    }
end

function MobileCamera.setSensitivity(newX: number, newY: number?)
    _sensitivityX = newX
    _sensitivityY = newY or newX
end

return MobileCamera
