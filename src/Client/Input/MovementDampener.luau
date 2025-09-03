export type MovementDampener = {
    init: () -> nil,
    destroy: () -> nil
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local BackwardsEdgeDetector = require(ClientModuleDirectory.Input.BackwardsEdgeDetector)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local MovementDampener: MovementDampener = {}

-- tunables
local EDGE_CHECK_INTERVAL = 0.15
local SLOW_EDGE_DIST = 3
local HARD_EDGE_DIST = 1
local BACK_DAMP_FACTOR = 0.2 -- keep 20% of backward component

local _running = false
local _edgeSlow = false
local _edgeHard = false
local _rsConn: RBXScriptConnection? = nil
local _charConn: RBXScriptConnection? = nil
local _humanoid: Humanoid? = nil
local _hrp: BasePart? = nil

local function bindCharacter(character: Model)
    _humanoid = character:WaitForChild("Humanoid") :: Humanoid
    _hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
end

local function ensureCharacter()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    bindCharacter(character)
    if _charConn then
        _charConn:Disconnect()
    end
    _charConn = LocalPlayer.CharacterAdded:Connect(bindCharacter)
end

local function isMovingBackwards(hrp: BasePart, moveDir: Vector3): boolean
    if moveDir.Magnitude < 1e-3 then
        return false
    end
    return hrp.CFrame.LookVector:Dot(moveDir.Unit) < -0.5
end

local function isAirborne(hum: Humanoid): boolean
    local s = hum:GetState()
    return s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air
end

local function dampenBackwards(hrp: BasePart, moveDir: Vector3): Vector3
    local look = hrp.CFrame.LookVector
    local back = -look
    local backComp = back:Dot(moveDir)
    local safe = moveDir - (back * backComp)
    local slowedBack = back * (backComp * BACK_DAMP_FACTOR)
    return safe + slowedBack
end

function MovementDampener.init()

    if PlatformDetector.getPlatform() ~= "MOBILE" then
        return
    end

    if _running then
        return
    end
    _running = true
    ensureCharacter()

    -- poll edges at two distances
    task.spawn(function()
        local lastCombined = false
        while _running do
            local behind3 = BackwardsEdgeDetector.getBlockBehind(SLOW_EDGE_DIST)
            local behind1 = BackwardsEdgeDetector.getBlockBehind(HARD_EDGE_DIST)

            _edgeSlow = (behind3 == nil)
            _edgeHard = (behind1 == nil)

            local combined = _edgeSlow or _edgeHard
            if combined and not lastCombined then
                print("Here!")
            end
            lastCombined = combined

            task.wait(EDGE_CHECK_INTERVAL)
        end
    end)

    -- per-frame adjust
    _rsConn = RunService.RenderStepped:Connect(function()
        local hum = _humanoid
        local hrp = _hrp
        if not hum or not hrp or hum.Health <= 0 then
            return
        end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude <= 0 then
            return
        end
        if not isMovingBackwards(hrp, moveDir) then
            return
        end
        if isAirborne(hum) then
            return
        end

        if _edgeHard then
            hum:Move(Vector3.zero, false) -- total stop near 1 stud edge
            return
        end

        if _edgeSlow then
            hum:Move(dampenBackwards(hrp, moveDir), false) -- slow near 3 studs edge
            return
        end
    end)
end

function MovementDampener.destroy()
    _running = false
    if _rsConn then
        _rsConn:Disconnect()
        _rsConn = nil
    end
    if _charConn then
        _charConn:Disconnect()
        _charConn = nil
    end
    _humanoid = nil
    _hrp = nil
end

return MovementDampener
