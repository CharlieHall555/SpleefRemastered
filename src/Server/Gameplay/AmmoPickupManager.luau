local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local SnowballAmmoPickup = require(ModuleDirectory.Gameplay.SnowballAmmoPickup)

export type AmmoPickupManager = {
    start: (_currentMap: any) -> nil,
    onAmmoPickup: (id: number) -> nil,
    cleanup: () -> nil
}

local AmmoPickupManager: AmmoPickupManager = {}

local currentMap: any = nil
local _running = false
local _activeIds: { [number]: true } = {}
local _subscribed = false

local function _activeCount(): number
    local n = 0
    for _ in pairs(_activeIds) do
        n += 1
    end
    return n
end

local function _tryGetSpawnPosition(): Vector3?
    if not currentMap then
        return nil
    end

    local tries = 0
    while tries < 5 do
        tries += 1
        local layer = currentMap:getRandomLayer()
        if layer then
            local block = layer:getRandomBlock()
            if block and block.Part and block.Part.Parent then
                return block.Part.Position + Vector3.new(0, 5, 0)
            end
        end
        task.wait()
    end

    return nil
end

local function _spawnLoop()
    local gap = tonumber(Config.AMMO_SPAWN_GAP) or 1
    local lifetime = tonumber(Config.AMMO_PICKUP_LIFETIME) or 20
    local maxAlive = tonumber(Config.MAX_AMMO_PICKUPS) or 10

    while _running do

        if _activeCount() < maxAlive then
            local pos = _tryGetSpawnPosition()
            if pos then
                local id = SnowballAmmoPickup.new(pos)
                if id then
                    _activeIds[id] = true

                    task.spawn(function(myId: number)
                        task.wait(lifetime)
                        if not _running then
                            return
                        end
                        if _activeIds[myId] then
                            SnowballAmmoPickup.remove(myId)
                            _activeIds[myId] = nil
                        end
                    end, id)
                end
            end
        end

        local waited = 0
        while waited < gap and _running do
            local step = math.min(0.25, gap - waited)
            task.wait(step)
            waited += step
        end
    end
end

function AmmoPickupManager.start(_currentMap: any)
    currentMap = _currentMap
    _running = true

    if not _subscribed and SnowballAmmoPickup and typeof(SnowballAmmoPickup.onSnowballPickup) == "function" then
        _subscribed = true
        SnowballAmmoPickup.onSnowballPickup(function(id: number)
            AmmoPickupManager.onAmmoPickup(id)
        end)
    end

    task.spawn(_spawnLoop)
end

function AmmoPickupManager.onAmmoPickup(id: number)
    if _activeIds[id] then
        _activeIds[id] = nil
    end
end

function AmmoPickupManager.cleanup()
    _running = false
    currentMap = nil
    _activeIds = {}
    SnowballAmmoPickup.reset()
end

return AmmoPickupManager

--[[
Suggestions:
- If SnowballAmmoPickup.onSnowballPickup returns a connection, store and disconnect it on cleanup to avoid duplicate binds.
- Consider exposing a getActiveCount() for debugging/telemetry.
- Add an optional min-distance-to-player filter when choosing spawn positions.
]]
