local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PartPool = require(ModuleDirectory.PartPool)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local SnowballAmmoPickup = require(ModuleDirectory.Gameplay.SnowballAmmoPickup)

local SnowballPickupFolder: Folder?

local heartbeatConnection
local spawnAccumulator = 0
local aliveTimeCache: { [number]: number } = {}
local currentMap = nil

local SPAWN_HEIGHT_OFFSET = 7

local AmmoPickupManager = {}

local function getAlive(): number
    if not SnowballPickupFolder then
        return 0
    end
    return #SnowballPickupFolder:GetChildren()
end

local function tryGetSpawnPosition(): Vector3?
    if not currentMap then
        return nil
    end
    local tries = 0
    while tries < 6 do
        tries += 1
        local layer = currentMap:getRandomLayer()
        if layer then
            local block = layer:getRandomBlock()
            if block and block.Part and block.Part:IsA("BasePart") then
                local p = block.Part.Position + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0)
                return p
            end
        end
    end
    return nil
end

function AmmoPickupManager.onLoaded()
    SnowballPickupFolder = workspace:WaitForChild("SnowballPickups", 5)

    heartbeatConnection = RunService.Stepped:Connect(function(_time, deltaTime)
        -- age existing pickups and remove expired
        for id, age in pairs(aliveTimeCache) do
            local newAge = age + deltaTime
            if newAge >= Config.AMMO_PICKUP_LIFETIME then
                -- remove and clear from cache
                SnowballAmmoPickup.remove(id)
                aliveTimeCache[id] = nil
            else
                aliveTimeCache[id] = newAge
            end
        end

        -- spawn logic
        spawnAccumulator += deltaTime
        if spawnAccumulator >= Config.AMMO_SPAWN_GAP and currentMap and getAlive() < Config.MAX_AMMO_PICKUPS then
            spawnAccumulator = 0

            local pos = tryGetSpawnPosition()
            if pos then
                local id = SnowballAmmoPickup.new(pos)
                if id then
                    aliveTimeCache[id] = 0
                end
            end
        end
    end)
end

function AmmoPickupManager.start(_currentMap)
    currentMap = _currentMap
end

function AmmoPickupManager.cleanup()
    currentMap = nil
    spawnAccumulator = 0
    aliveTimeCache = {}

    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

return AmmoPickupManager
