local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Throwable = require(ModuleDirectory.Throwable)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local ThrowableDefinitions = require(ModuleDirectory.ThrowableDefinitions)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ThrowableManager = {}

-- Internal state
local loadedThrowables: { [string]: Throwable.Throwable } = {}
local _nextId = 0

-- Physics constants
local gravityTable: { [string]: Vector3 } = {}
local velocityTable: { [string]: Vector3 } = {}

local typeHitFunctions: { [string]: (Throwable.Throwable, RaycastResult) -> () } = {}
local rayParams = RaycastParams.new()

-- Debug and cast settings
local DEBUG = false
local CAST_RADIUS = 0.1 -- half-width of the swept box for collision checks

local function generateUID(): string
    _nextId += 1
    return "s_" .. tostring(_nextId)
end

function ThrowableManager.init(): nil
    for eachType, eachTable in pairs(ThrowableDefinitions) do
        gravityTable[eachType] = Vector3.new(0, -eachTable.gravity, 0)
        velocityTable[eachType] = eachTable.velocity
    end
    RunService.Heartbeat:Connect(ThrowableManager.mainLoop)
end

function ThrowableManager.onLoaded(): nil
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { workspace:WaitForChild("Blocks" , 4) }
    rayParams.IgnoreWater = true
end

function ThrowableManager.mainLoop(dt: number): nil
    for uid, th in pairs(loadedThrowables) do
        local oldPos = th.position
        local newVel = th.velocity + gravityTable[th.typeName] * dt
        local newPos = oldPos + newVel * dt

        -- Debug stamp for path
        if DEBUG then
            local stamp = Instance.new("Part")
            stamp.Size = Vector3.new(0.2, 0.2, 0.2)
            stamp.CFrame = CFrame.new(newPos)
            stamp.Anchored = true
            stamp.CanCollide = false
            stamp.Transparency = 0
            stamp.BrickColor = BrickColor.new("Bright red")
            stamp.Parent = workspace
            Debris:AddItem(stamp, 5)
        end

        -- Swept-box collision (Blockcast) between oldPos and newPos
        local direction = newPos - oldPos
        local center = oldPos:Lerp(newPos, 0.5)
        local orient = direction.Magnitude > 0 and direction.Unit or Vector3.new(0, 0, 1)
        local castCFrame = CFrame.new(center, center + orient)
        local castSize = Vector3.new(CAST_RADIUS, CAST_RADIUS, direction.Magnitude)
        local hit: RaycastResult? = workspace:Blockcast(castCFrame, castSize, direction, rayParams)

        if oldPos.Y < -100 then
            ThrowableManager.removeThrowable(uid)
        elseif hit then
            if DEBUG then
                local stamp = Instance.new("Part")
                stamp.Size = Vector3.new(1, 1, 1)
                stamp.CFrame = CFrame.new(hit.Position)
                stamp.Anchored = true
                stamp.CanCollide = false
                stamp.Transparency = 0
                stamp.BrickColor = BrickColor.new("Parsley green")
                stamp.Parent = workspace
                Debris:AddItem(stamp, 5)
            end
            ThrowableManager.onHit(th, hit)
            ThrowableManager.removeThrowable(uid)
        else
            th.velocity = newVel
            th.position = newPos
        end
    end
end

local function updateClients(newThrowable: Throwable.Throwable)
    local dataToSend = {
        sP = VectorUtil.SerializeVector3(newThrowable.position),
        v  = VectorUtil.SerializeVector3(newThrowable.velocity),
        t  = newThrowable.typeName,
        s  = workspace:GetServerTimeNow(),
        uid = newThrowable.uid,
    }
    RemoteEventHandler.FireOnAllClients("NEW_THROWABLE", dataToSend)
end

function ThrowableManager.newThrowable(position: Vector3, direction: Vector3, _type: string): string
    assert(typeof(position) == "Vector3", "ThrowableManager.newThrowable: 'position' must be a Vector3")
    assert(typeof(direction) == "Vector3", "ThrowableManager.newThrowable: 'direction' must be a Vector3")
    assert(typeof(_type) == "string" and _type ~= "", "ThrowableManager.newThrowable: '_type' must be a non-empty string")

    local uid = generateUID()
    local speed = velocityTable[_type] or 80
    local velocity = direction.Unit * speed
    local new = {
        uid = uid,
        direction = direction,
        position = position,
        velocity = velocity,
        typeName = _type,
    }
    loadedThrowables[uid] = new

    updateClients(new)
    return uid
end

function ThrowableManager.onHit(throwable: Throwable.Throwable, hit: RaycastResult?): nil
    local f = typeHitFunctions[throwable.typeName]
    if f and hit then
        f(throwable, hit)
    end
end

function ThrowableManager.registerOnHit(typeName: string, func: (Throwable.Throwable, RaycastResult) -> ()): nil
    typeHitFunctions[typeName] = func
end

function ThrowableManager.removeThrowable(uid: string): nil
    RemoteEventHandler.FireOnAllClients("DELETE_THROWABLE", uid)
    loadedThrowables[uid] = nil
end

return ThrowableManager
