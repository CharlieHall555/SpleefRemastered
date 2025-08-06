local ClientThrowableTracker = {}

export type Throwable = {
    uid: string,
    startPosition: Vector3,
    initialVelocity: Vector3,
    type: string,
    launchTime: number,
    lastTime: number,
    part: Part,
}

local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PartPool = require(ClientModuleDirectory.PartPool)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ThrowableData = require(ClientModuleDirectory.ThrowableData)
local VectorUtil = require(ClientModuleDirectory.VectorUtil)
local ThrowableDefinitions = require(ClientModuleDirectory.ThrowableDefinitions)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = true

local gravityTable: {[string]: Vector3} = {}
local throwables: { [string]: Throwable } = {}
local typeHitFunctions: { [string]: (Throwable, RaycastResult) -> () } = {}

local _nextId = 0
local function generateUID(): string
    _nextId += 1
    return "t_" .. tostring(_nextId)
end

function ClientThrowableTracker.init()
    for eachType, def in ThrowableDefinitions do
        gravityTable[eachType] = Vector3.new(0, -def.gravity, 0)
    end
    RunService.RenderStepped:Connect(ClientThrowableTracker.mainLoop)
    RemoteEventHandler.newEventConnection("NEW_THROWABLE", ClientThrowableTracker.receiveFromServer)
end

function ClientThrowableTracker.onLoaded()
    rayParams.FilterDescendantsInstances = { workspace:WaitForChild("Blocks") }
end

function ClientThrowableTracker.receiveFromServer(data: ThrowableData.ThrowableData)
    local startPosition = VectorUtil.DeserializeVector3(data.sP)
    local velocity = VectorUtil.DeserializeVector3(data.v)
    local typeName = data.t
    local launchTime = data.s
    ClientThrowableTracker.newThrowable(startPosition, velocity, typeName, launchTime)
end

function ClientThrowableTracker.mainLoop()
    local now = workspace:GetServerTimeNow()
    for uid, throwable in pairs(throwables) do
        local gravity = gravityTable[throwable.type]
        -- calculate previous and current positions
        local tPrev = throwable.lastTime
        local tNow = now
        local dtPrev = tPrev - throwable.launchTime
        local dtNow = tNow - throwable.launchTime

        local prevPos = throwable.startPosition
            + throwable.initialVelocity * dtPrev
            + 0.5 * gravity * dtPrev * dtPrev
        local newPos = throwable.startPosition
            + throwable.initialVelocity * dtNow
            + 0.5 * gravity * dtNow * dtNow

        local direction = newPos - prevPos
        local result = workspace:Raycast(prevPos, direction, rayParams)

        if result or newPos.Y < -100 then
            local hitFunc = typeHitFunctions[throwable.type]
            if result and hitFunc then
                hitFunc(throwable, result)
            end
            ClientThrowableTracker.removeThrowable(uid)
        else
            throwable.part.Position = newPos
            throwable.lastTime = tNow
        end
    end
end

function ClientThrowableTracker.newThrowable(startPosition: Vector3, initialVelocity: Vector3, typeName: string, launchTime: number): string
    local part = PartPool.take()
    if not part then
        part = Instance.new("Part")
        warn("Had to generate new part")
    end

    -- apply definition properties
    part.Size = ThrowableDefinitions[typeName].size
    part.Color = ThrowableDefinitions[typeName].color
    part.Material = ThrowableDefinitions[typeName].material
    part.Shape = Enum.PartType.Ball
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0
    part.Parent = workspace

    -- compute and set initial position based on launchTime
    local now = workspace:GetServerTimeNow()
    local gravity = gravityTable[typeName]
    local dt = now - launchTime
    local currentPos = startPosition + initialVelocity * dt + 0.5 * gravity * dt * dt
    part.Position = currentPos

    -- store throwable state
    local uid = generateUID()
    throwables[uid] = {
        uid = uid,
        startPosition = startPosition,
        initialVelocity = initialVelocity,
        type = typeName,
        launchTime = launchTime,
        lastTime = now,
        part = part,
    }

    return uid
end

function ClientThrowableTracker.removeThrowable(uid: string)
    local t = throwables[uid]
    if not t then return end
    PartPool.add(t.part)
    t.part.Transparency = 1
    throwables[uid] = nil
end

function ClientThrowableTracker.registerOnHit(typeName: string, func: (Throwable, RaycastResult) -> ())
    typeHitFunctions[typeName] = func
end

return ClientThrowableTracker