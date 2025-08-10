local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Players = game:GetService("Players")

-- USEFUL CONFIGS: Config.MAX_AMMO, Config.STARTING_AMMO, Config.AMMO_REGEN_INTERVAL

local AmmoManager = {}

local AmmoStore: { [number]: number } = {} -- userId -> ammo
local _regenProgress: { [number]: number } = {} -- userId -> seconds accumulated toward next +1 ammo
local _regenConnection: RBXScriptConnection? = nil

local function validatePlayer(player: Player)
    assert(player and player.UserId and player.UserId ~= 0, "Invalid player")
end

local function clampAmmo(value: number): number
    local maxAmmo = Config.MAX_AMMO or math.huge
    return math.clamp(value, 0, maxAmmo)
end

function AmmoManager.init()
    RemoteEventHandler.newEventConnection("QUERY_AMMO_REGEN_INTERVAL" , function(player)
        return Config.AMMO_REGEN_INTERVAL
    end)

    table.clear(AmmoStore)
    table.clear(_regenProgress)
    if _regenConnection then
        _regenConnection:Disconnect()
        _regenConnection = nil
    end
end

function AmmoManager.startRegenLoop()
    if _regenConnection then
        _regenConnection:Disconnect()
        _regenConnection = nil
    end

    local RunService = game:GetService("RunService")
    _regenConnection = RunService.Heartbeat:Connect(function(dt)
        if RoundSystem.getState() ~= "ACTIVE" and RoundSystem.getState() ~= "PREPARING" then
            -- stop ticking outside of active rounds
            _regenConnection:Disconnect()
            _regenConnection = nil
            return
        end

        local secondsPerAmmo = math.max(0.01, Config.AMMO_REGEN_INTERVAL or 2)

        for userId, ammo in pairs(AmmoStore) do
            local maxAmmo = Config.MAX_AMMO or math.huge

            if ammo >= maxAmmo then
                -- at max: progress is reset and does not accumulate
                _regenProgress[userId] = 0
                continue
            end

            local progress = (_regenProgress[userId] or 0) + dt
            local gained = 0
            -- award ammo for each full interval accumulated
            while progress >= secondsPerAmmo and (ammo + gained) < maxAmmo do
                progress -= secondsPerAmmo
				gained += 1
            end

            if gained > 0 then
                local newAmmo = clampAmmo(ammo + gained)
                AmmoStore[userId] = newAmmo

                local player = Players:GetPlayerByUserId(userId)
                if player then
                    local serverTime = workspace:GetServerTimeNow()
                    RemoteEventHandler.FireOnClient(player,"AMMO_REGEN" ,serverTime, newAmmo)
                end
            end

            _regenProgress[userId] = progress
        end
    end)
end

function AmmoManager.setUp(players: { Player })
    local starting = clampAmmo(Config.STARTING_AMMO or 0)
    for _, player in ipairs(players) do
        if player and player.UserId and player.UserId ~= 0 then
            AmmoStore[player.UserId] = starting
            _regenProgress[player.UserId] = 0
            RemoteEventHandler.FireOnClient(player, "SET_MAX_AMMO", Config.MAX_AMMO)
            RemoteEventHandler.FireOnClient(player, "AMMO_CHANGED", Config.MAX_AMMO)
        end
    end
end

function AmmoManager.getAmmo(player: Player): number?
    validatePlayer(player)
    return AmmoStore[player.UserId]
end

function AmmoManager.incrementAmmo(player: Player, value: number): nil
    validatePlayer(player)
    assert(type(value) == "number", "value must be a number")

    local userId = player.UserId
    local current = AmmoStore[userId]
    if current == nil then
        current = clampAmmo(Config.STARTING_AMMO or 0)
    end

    local newValue = clampAmmo(current + value)
    AmmoStore[userId] = newValue
    
    RemoteEventHandler.FireOnClient(player, "AMMO_CHANGED" , newValue)

    if newValue >= (Config.MAX_AMMO or math.huge) then
        _regenProgress[userId] = 0
    end
end

function AmmoManager.reset()
    table.clear(AmmoStore)
    table.clear(_regenProgress)
    if _regenConnection then
        _regenConnection:Disconnect()
        _regenConnection = nil
    end
end

return AmmoManager
