local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local SnowballAmmoPickup = require(ModuleDirectory.Ammo.SnowballAmmoPickup)
local Map = require(ModuleDirectory.Map.Map)
local Layer = require(ModuleDirectory.Map.Layer)

local CoinPickupFolder: Folder? = nil
local heartbeatConnection: RBXScriptConnection? = nil
local spawnAccumulator: number = 0
local aliveTimeCache: { [number]: number } = {}
local activeMap: Map.Map? = nil

local spawnableLayers: { Layer.Layer } = {}
local uidToLayer: { [number]: Layer.Layer } = {}
local layerCounts: { [Layer.Layer]: number } = {}
local totalAlive: number = 0
local callbackBound: boolean = false

local CoinPickupManager = {}

local function getSnowballPickupFolder(): Folder
    if CoinPickupFolder and CoinPickupFolder.Parent then
        return CoinPickupFolder
    end

    local existing = workspace:FindFirstChild("CoinPickups")
    if existing and existing:IsA("Folder") then
        CoinPickupFolder = existing
    else
        CoinPickupFolder = Instance.new("Folder")
        CoinPickupFolder.Name = "SnowballPickups"
        CoinPickupFolder.Parent = workspace
    end

    return CoinPickupFolder
end

local function bindRemovalCallback()
    if callbackBound then
        return
    end

    SnowballAmmoPickup.setOnRemoveCallback(function(removedId: number)
        if aliveTimeCache[removedId] ~= nil then
            aliveTimeCache[removedId] = nil
        end

        local layer = uidToLayer[removedId]
        if layer then
            uidToLayer[removedId] = nil
            local current = layerCounts[layer] or 0
            if current > 0 then
                layerCounts[layer] = current - 1
            end
        end

        if totalAlive > 0 then
            totalAlive -= 1
        end
    end)

    callbackBound = true
end

local function chooseLayerForSpawn(): Layer.Layer?
    local belowMin: { Layer.Layer } = {}
    for _, layer in ipairs(spawnableLayers) do
        local count = layerCounts[layer] or 0
        if count < Config.MIN_AMMO_PICKUP_PER_FLOOR then
            table.insert(belowMin, layer)
        end
    end

    if #belowMin > 0 then
        return belowMin[math.random(1, #belowMin)]
    end

    if #spawnableLayers == 0 then
        return nil
    end

    return spawnableLayers[math.random(1, #spawnableLayers)]
end

local function trySpawnOne(): boolean
    if not activeMap then
        return false
    end

    if #spawnableLayers == 0 then
        return false
    end

    if totalAlive >= Config.MAX_AMMO_PICKUPS then
        return false
    end

    local layer = chooseLayerForSpawn()
    if not layer then
        return false
    end

    local tries = 0
    while tries < 6 do
        tries += 1
        local block = layer:getRandomBlock()
        if block and block.Part and block.Part:IsA("BasePart") then
            local pos = block.Part.Position + Vector3.new(0, Config.AMMO_SPAWN_HEIGHT_OFFSET, 0)
            local uid = SnowballAmmoPickup.new(pos)
            if uid then
                aliveTimeCache[uid] = 0
                uidToLayer[uid] = layer
                layerCounts[layer] = (layerCounts[layer] or 0) + 1
                totalAlive += 1
                return true
            end
        end
    end

    return false
end

local function onHeartbeat(dt: number)
    for id, t in pairs(aliveTimeCache) do
        aliveTimeCache[id] = t + dt
    end

    local toRemove: { number } = {}
    for id, t in pairs(aliveTimeCache) do
        if t >= Config.AMMO_PICKUP_LIFETIME then
            table.insert(toRemove, id)
        end
    end
    for _, id in ipairs(toRemove) do
        SnowballAmmoPickup.remove(id)
    end

    spawnAccumulator += dt
    local interval = Config.AMMO_SPAWN_INTERVAL

    while spawnAccumulator >= interval do
        if totalAlive >= Config.MAX_AMMO_PICKUPS then
            break
        end
        local spawned = trySpawnOne()
        if not spawned then
            break
        end
        spawnAccumulator -= interval
    end
end

function CoinPickupManager.onLoaded()
    CoinPickupFolder = getSnowballPickupFolder()
    bindRemovalCallback()
end

function CoinPickupManager.start(map: Map.Map)
    activeMap = map
    spawnableLayers = {}
    layerCounts = {}
    uidToLayer = {}
    aliveTimeCache = {}
    totalAlive = 0
    spawnAccumulator = 0

    for _, layer in ipairs(activeMap.Layers) do
        if layer:getSpawnsAmmo() then
            table.insert(spawnableLayers, layer)
            layerCounts[layer] = 0
        end
    end

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)
end

function CoinPickupManager.stop()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end

    SnowballAmmoPickup.reset()

    aliveTimeCache = {}
    uidToLayer = {}
    layerCounts = {}
    spawnableLayers = {}
    totalAlive = 0
    spawnAccumulator = 0
    activeMap = nil
end

return CoinPickupManager
