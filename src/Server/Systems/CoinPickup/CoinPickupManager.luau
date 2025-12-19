local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local CoinPickup = require(ModuleDirectory.Coins.CoinPickup)
local Map = require(ModuleDirectory.Map.Map)
local Layer = require(ModuleDirectory.Map.Layer)
local Block = require(ModuleDirectory.Map.Block)
local Set = require(ModuleDirectory.Set)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local SnowballPickupManager = require(ModuleDirectory.Ammo.AmmoPickupManager)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local CoinPickupFolder: Folder? = nil
local heartbeatConnection: RBXScriptConnection? = nil
local spawnAccumulator: number = 0
local aliveTimeCache: { [number]: number } = {}
local activeMap: Map.Map? = nil

local spawnableLayers: { Layer.Layer } = {}
local uidToLayer: { [number]: Layer.Layer } = {}
local uidToPosition: { [number]: Vector3 } = {}
local positionSet = Set.new()
local layerCounts: { [Layer.Layer]: number } = {}
local totalAlive: number = 0
local callbackBound: boolean = false

local CoinPickupManager = {}

local function getCoinPickupFolder(): Folder
    if CoinPickupFolder and CoinPickupFolder.Parent then
        return CoinPickupFolder
    end

    local existing = workspace:FindFirstChild("CoinPickups")
    if existing and existing:IsA("Folder") then
        CoinPickupFolder = existing
    else
        CoinPickupFolder = Instance.new("Folder")
        CoinPickupFolder.Name = "CoinPickups"
        CoinPickupFolder.Parent = workspace
    end

    return CoinPickupFolder
end

local function resetPickedUpCoins()
    local players = game:GetService("Players"):GetPlayers()
    for _, player in ipairs(players) do
        SessionVariables.setValue(player, "coinsCollected", 0)
    end
end

local function bindRemovalCallback()
    if callbackBound then
        return
    end

    CoinPickup.setOnRemoveCallback(function(removedId: number)
        if aliveTimeCache[removedId] ~= nil then
            aliveTimeCache[removedId] = nil
        end

        if uidToPosition[removedId] ~= nil then
            local position = uidToPosition[removedId]
            uidToPosition[removedId] = nil
            positionSet:remove(VectorUtil.SerializeVector3(position))
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
        if count < Config.MIN_COIN_PICKUP_PER_FLOOR then
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

function CoinPickupManager.isPositionFree(position : Vector3)
    return positionSet:contains(VectorUtil.SerializeVector3(position)) == false
end

local function trySpawnOne(): boolean
    if not activeMap then
        return false
    end

    if #spawnableLayers == 0 then
        return false
    end

    if totalAlive >= Config.MAX_COIN_PICKUPS then
        return false
    end

    local layer = chooseLayerForSpawn()
    if not layer then
        return false
    end

    local tries = 0
    while tries < 6 do
        tries += 1
        local block : Block.Block = layer:getRandomBlock()
        local spawnGridPos = Vector3.new(
                block.LayerPosition.X,
                layer._id,
                block.LayerPosition.Y
            )
        if block and block.Part and block.Part:IsA("BasePart") and SnowballPickupManager.isPositionFree(spawnGridPos) and CoinPickupManager.isPositionFree(spawnGridPos) then
            local pos = block.Part.Position + Vector3.new(0, Config.AMMO_SPAWN_HEIGHT_OFFSET, 0)
            local uid = CoinPickup.new(pos)

            if uid then
                uidToPosition[uid] = spawnGridPos
                positionSet:add(VectorUtil.SerializeVector3(spawnGridPos))
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

    --[[local toRemove: { number } = {}
    for id, t in pairs(aliveTimeCache) do
        if t >= Config.AMMO_PICKUP_LIFETIME then
            table.insert(toRemove, id)
        end
    end
    for _, id in ipairs(toRemove) do
        CoinPickupManager.remove(id)
    end]]

    spawnAccumulator += dt
    local interval = Config.COIN_SPAWN_INTERVAL

    while spawnAccumulator >= interval do
        if totalAlive >= Config.MAX_COIN_PICKUPS then
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
    CoinPickupFolder = getCoinPickupFolder()
    bindRemovalCallback()

    ServerHitBoxManager.setUpCallback("COIN_PICKUP", function(player : Player, part: BasePart)
        local parent = part.Parent
        if not parent then
            return
        end

        local coinsCollected = SessionVariables.getValue(player, "coinsCollected") or 0
        SessionVariables.setValue(player, "coinsCollected", coinsCollected + 1)

        local uid = part:GetAttribute("Id")
        CoinPickup.remove(uid)
        print("remove")
    end)

end

function CoinPickupManager.start(map: Map.Map)
    activeMap = map
    spawnableLayers = {}
    layerCounts = {}
    uidToLayer = {}
    aliveTimeCache = {}
    totalAlive = 0
    spawnAccumulator = 0

    for _, layer in ipairs(activeMap.layers) do
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

    resetPickedUpCoins()

    CoinPickup.reset()

    aliveTimeCache = {}
    uidToLayer = {}
    uidToPosition = {}
    layerCounts = {}
    spawnableLayers = {}
    positionSet:clear()
    totalAlive = 0
    spawnAccumulator = 0
    activeMap = nil
end

return CoinPickupManager
