local ClientThrowableTracker = {}

export type Throwable = {
    uid: string,
    startPosition: Vector3,
    initialVelocity: Vector3,
    type: string,
    launchTime: number,
    displayTime: number,
    targetTime: number,
    part: Part,
}

local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PartPool = require(ClientModuleDirectory.PartPool)
local SnowballPool = require(ClientModuleDirectory.SnowballPool)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ThrowableData = require(ClientModuleDirectory.ThrowableData)
local VectorUtil = require(ClientModuleDirectory.VectorUtil)
local ThrowableDefinitions = require(ClientModuleDirectory.ThrowableDefinitions)
local localPlayer = game.Players.LocalPlayer

local rayParams = RaycastParams.new()

local function computePosition(startPos: Vector3, vel: Vector3, gravity: Vector3, t: number, result: Vector3?)
    local pos = startPos + vel * t + 0.5 * gravity * t * t
    if result then
        result = Vector3.new(pos.X, pos.Y, pos.Z)
        return result
    end
    return pos
end

local gravityTable: { [string]: Vector3 } = {}
local typeHitFunctions: { [string]: (Throwable, RaycastResult) -> () } = {}

local newTable: { [string]: () -> Part } = {}
newTable.snowball = SnowballPool.take

local _nextId = 0
local function generateUID(): string
    _nextId += 1
    return "c_" .. tostring(_nextId)
end

local INTERPOLATION_OFFSET = 0.2

local throwables: { [number]: Throwable } = {}
local indexByUid: { [string]: number } = {}

local function cleanupPart(entry: Throwable)
    local p = entry.part
    if not p then
        return
    end
    if entry.type == "snowball" and SnowballPool and SnowballPool.add then
        SnowballPool.add(p)
    elseif PartPool and PartPool.add then
        PartPool.add(p)
    else
        p:Destroy()
    end
end

local function removeAt(index: number)
    local last = #throwables
    if index > last then
        return
    end

    local removed = throwables[index]
    local lastItem = throwables[last]

    if index ~= last then
        throwables[index] = lastItem
        indexByUid[lastItem.uid] = index
    end

    throwables[last] = nil
    indexByUid[removed.uid] = nil

    cleanupPart(removed)
end

function ClientThrowableTracker.init()
    for eachType, def in ThrowableDefinitions do
        gravityTable[eachType] = Vector3.new(0, -def.gravity, 0)
    end
    RunService.PostSimulation:Connect(ClientThrowableTracker.mainLoop)
    RemoteEventHandler.newEventConnection("NEW_THROWABLE", ClientThrowableTracker.receiveFromServer)
    RemoteEventHandler.newEventConnection("DELETE_THROWABLE", ClientThrowableTracker.removeThrowable)
    ClientThrowableTracker.pollPing()
end

function ClientThrowableTracker.onLoaded()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.CollisionGroup = "CG_GAMEPLAY"
    rayParams.FilterDescendantsInstances = { localPlayer.Character }

    localPlayer.CharacterAdded:Connect(function(new_character)
        rayParams.FilterDescendantsInstances = { new_character }
    end)
end

local function average(t: { number })
    local sum = 0
    for _, v in ipairs(t) do
        sum += v
    end
    return sum / (#t)
end

function ClientThrowableTracker.pollPing()
    task.spawn(function()
        local pingSamples = {}
        local sampleSize = 5

        while localPlayer and localPlayer.Parent do
            local success, err = pcall(function()
                local ping = math.max(0, localPlayer:GetNetworkPing())
                ping = math.min(ping, 0.5)

                table.insert(pingSamples, ping)
                if #pingSamples > sampleSize then
                    table.remove(pingSamples, 1)
                end

                if RunService:IsStudio() then
                    INTERPOLATION_OFFSET = 0.08
                else
                    INTERPOLATION_OFFSET = average(pingSamples) / 2
                end
            end)

            if not success then
                warn("[ClientThrowableTracker.pollPing] Error:", err)
            end

            task.wait(0.5)
        end
    end)
end

function ClientThrowableTracker.receiveFromServer(data: ThrowableData.ThrowableData)
    local startPosition = VectorUtil.DeserializeVector3(data.sP)
    local velocity = VectorUtil.DeserializeVector3(data.v)
    local typeName = data.t
    local launchTime = data.s
    local uid = data.uid
    ClientThrowableTracker.newThrowable(startPosition, velocity, typeName, launchTime, uid)
end

function ClientThrowableTracker.mainLoop(dt: number)
    local now = workspace:GetServerTimeNow()
    local i = 1
    while i <= #throwables do
        local throwable = throwables[i]

        throwable.targetTime = now

        local oldDisplay = throwable.displayTime
        local newDisplay = math.min(throwable.targetTime, oldDisplay + dt)
        throwable.displayTime = newDisplay

        local gravity = gravityTable[throwable.type]
        local dtPrev = oldDisplay - throwable.launchTime
        local dtNow = newDisplay - throwable.launchTime

        local prevPos = computePosition(throwable.startPosition, throwable.initialVelocity, gravity, dtPrev)
        local newPos = computePosition(throwable.startPosition, throwable.initialVelocity, gravity, dtNow)
        local direction = newPos - prevPos
        local result = workspace:Raycast(prevPos, direction, rayParams)

        local removed = false
        if newPos.Y < -100 then
            removeAt(i)
            removed = true
        elseif result then
            local hitFunc = typeHitFunctions[throwable.type]
            if hitFunc then
                hitFunc(throwable, result)
            end
            removeAt(i)
            removed = true
        else
            throwable.part.Position = newPos
        end

        if not removed then
            i += 1
        end
    end
end

function ClientThrowableTracker.newThrowable(
    startPosition: Vector3,
    initialVelocity: Vector3,
    typeName: string,
    launchTime: number,
    given_uid: any?
): string
    local g = newTable[typeName]
    local part
    if g then
        part = g()
    end

    if not part then
        part = Instance.new("Part")
        local def = ThrowableDefinitions[typeName]
        part.Size = def.size
        part.Color = def.color
        part.Material = def.material
        part.Shape = Enum.PartType.Ball
        part.Anchored = true
        part.CanCollide = false
        part.Parent = workspace
        warn("Had to generate new part")
    end

    local now = workspace:GetServerTimeNow()
    local displayTime = math.max(launchTime, now - INTERPOLATION_OFFSET)
    local targetTime = now

    local gravity = gravityTable[typeName]
    local dtDisplay = displayTime - launchTime
    local currentPos = startPosition + initialVelocity * dtDisplay + 0.5 * gravity * dtDisplay * dtDisplay
    part.Position = currentPos

    local uid = tostring(given_uid or generateUID())
    local entry: Throwable = {
        uid = uid,
        startPosition = startPosition,
        initialVelocity = initialVelocity,
        type = typeName,
        launchTime = launchTime,
        displayTime = displayTime,
        targetTime = targetTime,
        part = part
    }

    local idx = #throwables + 1
    throwables[idx] = entry
    indexByUid[uid] = idx

    return uid
end

local function normalize(id: any): string
    return tostring(id):match("^%s*(.-)%s*$")
end

function ClientThrowableTracker.removeThrowable(uid: string)
    uid = normalize(uid)
    local idx = indexByUid[uid]
    if idx == nil then
        return
    end
    removeAt(idx)
end

function ClientThrowableTracker.registerOnHit(typeName: string, func: (Throwable, RaycastResult) -> ())
    typeHitFunctions[typeName] = func
end

return ClientThrowableTracker
