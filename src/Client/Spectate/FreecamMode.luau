-- FreecamMode.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local MouseIcon = require(ClientModuleDirectory.Gui.MouseIcon)

local FreecamMode = {}

local enabled: boolean = false
local camera: Camera

local pitch = 0
local yaw = 0
local sensitivity = 0.0025

local speed = 64
local SPEED_MIN = 4
local SPEED_MAX = 128
local SPEED_STEP = 8

local lookActive = false

local moveKeys: { [Enum.KeyCode]: boolean } = {}
local conns: { RBXScriptConnection } = {}
local keyBindIds: { string } = {}
local kbEndId: string? = nil
local rmbStartId: string? = nil
local rmbEndId: string? = nil

local prev = {
    cameraType = nil :: Enum.CameraType?,
    cameraSubject = nil :: Instance?,
    fov = nil :: number?,
    mouseBehavior = nil :: Enum.MouseBehavior?
}

local function getCamera(): Camera
    return workspace.CurrentCamera
end

local function clampAngle(x: number, minVal: number, maxVal: number): number
    if x < minVal then return minVal end
    if x > maxVal then return maxVal end
    return x
end

local function computeMoveVector(): Vector3
    local forward = 0
    local right = 0
    local up = 0

    if moveKeys[Enum.KeyCode.W] or moveKeys[Enum.KeyCode.Up] then forward += 1 end
    if moveKeys[Enum.KeyCode.S] or moveKeys[Enum.KeyCode.Down] then forward -= 1 end
    if moveKeys[Enum.KeyCode.D] or moveKeys[Enum.KeyCode.Right] then right += 1 end
    if moveKeys[Enum.KeyCode.A] or moveKeys[Enum.KeyCode.Left] then right -= 1 end
    if moveKeys[Enum.KeyCode.Space] then up += 1 end
    if moveKeys[Enum.KeyCode.C] then up -= 1 end

    local v = Vector3.new(right, up, forward)
    if v.Magnitude > 1e-3 then
        v = v.Unit
    end
    return v
end

local function unbindAll()
    for _, c in conns do
        c:Disconnect()
    end
    table.clear(conns)

    for _, id in keyBindIds do
        InputHandler.unbind(id)
    end
    table.clear(keyBindIds)

    if kbEndId then
        InputHandler.unbind(kbEndId)
        kbEndId = nil
    end
    if rmbStartId then
        InputHandler.unbind(rmbStartId)
        rmbStartId = nil
    end
    if rmbEndId then
        InputHandler.unbind(rmbEndId)
        rmbEndId = nil
    end
end

function FreecamMode.onLoaded()
    camera = getCamera()
    table.clear(moveKeys)
end

function FreecamMode.enable()
    if enabled then return end
    if PlatformDetector.getPlatform() ~= "PC" then return end
    if not UserInputService.KeyboardEnabled or not UserInputService.MouseEnabled then return end

    camera = getCamera()

    prev.cameraType = camera.CameraType
    prev.cameraSubject = camera.CameraSubject
    prev.fov = camera.FieldOfView
    prev.mouseBehavior = UserInputService.MouseBehavior

    camera.CameraType = Enum.CameraType.Scriptable
    camera.CameraSubject = nil

    local cf = camera.CFrame
    local look = cf.LookVector
    yaw = math.atan2(-look.X, -look.Z)
    pitch = math.asin(look.Y)

    local function bindKeyDown(k: Enum.KeyCode)
        local id = InputHandler.bindKey(k, function()
            moveKeys[k] = true
        end)
        table.insert(keyBindIds, id)
    end

    bindKeyDown(Enum.KeyCode.W)
    bindKeyDown(Enum.KeyCode.A)
    bindKeyDown(Enum.KeyCode.S)
    bindKeyDown(Enum.KeyCode.D)
    bindKeyDown(Enum.KeyCode.Up)
    bindKeyDown(Enum.KeyCode.Down)
    bindKeyDown(Enum.KeyCode.Left)
    bindKeyDown(Enum.KeyCode.Right)
    bindKeyDown(Enum.KeyCode.Space)
    bindKeyDown(Enum.KeyCode.C)

    kbEndId = InputHandler.bindActionEnd(Enum.UserInputType.Keyboard, function(action)
        local kc = action.keyCode
        if kc and moveKeys[kc] ~= nil then
            moveKeys[kc] = false
        end
    end)

    rmbStartId = InputHandler.bindActionStart(Enum.UserInputType.MouseButton2, function(_action)
        lookActive = true
        if MouseIcon and MouseIcon.setHidden then
            MouseIcon.setHidden(true)
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end)

    rmbEndId = InputHandler.bindActionEnd(Enum.UserInputType.MouseButton2, function(_action)
        lookActive = false
        if MouseIcon and MouseIcon.setHidden then
            MouseIcon.setHidden(false)
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end)

    table.insert(conns, UserInputService.InputChanged:Connect(function(input: InputObject)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local step = input.Position.Z or 0
            if step ~= 0 then
                speed = math.clamp(speed + step * SPEED_STEP, SPEED_MIN, SPEED_MAX)
            end
        end
    end))

    table.insert(conns, RunService.RenderStepped:Connect(function(dt)
        if not enabled then return end

        if lookActive then
            local delta = UserInputService:GetMouseDelta()
            yaw -= delta.X * sensitivity
            pitch -= delta.Y * sensitivity
            pitch = clampAngle(pitch, -math.rad(89), math.rad(89))
        end

        local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
        local pos = camera.CFrame.Position

        local mv = computeMoveVector()
        if mv.Magnitude > 0 then
            local worldMove = rot.RightVector * mv.X + Vector3.yAxis * mv.Y + rot.LookVector * mv.Z
            pos += worldMove * (speed * dt)
        end

        camera.CFrame = CFrame.new(pos) * rot
    end))

    enabled = true
end

function FreecamMode.disable()
    if not enabled then return end
    enabled = false

    unbindAll()

    if prev.cameraType then
        camera.CameraType = prev.cameraType
    end
    if prev.cameraSubject ~= nil then
        camera.CameraSubject = prev.cameraSubject
    end
    if prev.fov then
        camera.FieldOfView = prev.fov
    end

    if MouseIcon and MouseIcon.setHidden then
        MouseIcon.setHidden(false)
    end
    if prev.mouseBehavior then
        UserInputService.MouseBehavior = prev.mouseBehavior
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end

    lookActive = false
    table.clear(moveKeys)
end

function FreecamMode.setCFrame(newCFrame: CFrame)
    if not enabled then return end
    if not camera then return end
    camera.CFrame = newCFrame

    -- also update yaw/pitch so mouse look continues smoothly
    local look = newCFrame.LookVector
    yaw = math.atan2(-look.X, -look.Z)
    pitch = math.asin(look.Y)
end

return FreecamMode
