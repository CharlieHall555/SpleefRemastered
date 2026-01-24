local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ServerConstants = require(ModuleDirectory.ServerConstants)
local Players = game:GetService("Players")

-- USEFUL CONFIGS: Config.MAX_AMMO, Config.STARTING_AMMO, Config.AMMO_REGEN_INTERVAL

local AmmoManager = {}

local AmmoStore: { [number]: number } = {} -- userId -> ammo
local regenProgress: { [number]: number } = {} -- userId -> seconds accumulated toward next +1 ammo
local regenConnection: RBXScriptConnection? = nil
local isInfiniteAmmo = false

local function validatePlayer(player: Player)
    assert(player and player.UserId and player.UserId ~= 0, "Invalid player")
end

local function clampAmmo(value: number): number
    local maxAmmo = Config.MAX_AMMO or math.huge
    return math.clamp(value, 0, maxAmmo)
end

function AmmoManager.init()

    ServerConstants.setValue("infiniteAmmo" , isInfiniteAmmo)
    ServerConstants.setValue("ammoRegenInterval" , Config.AMMO_REGEN_INTERVAL)

    table.clear(AmmoStore)
    table.clear(regenProgress)
    if regenConnection then
        regenConnection:Disconnect()
        regenConnection = nil
    end
end

function AmmoManager.setUp(players: { Player })
    local starting = clampAmmo(Config.STARTING_AMMO or 0)
    for _, player in ipairs(players) do
        if player and player.UserId and player.UserId ~= 0 then
            AmmoStore[player.UserId] = starting
            regenProgress[player.UserId] = 0
            RemoteEventHandler.FireOnClient(player, "SET_MAX_AMMO", Config.MAX_AMMO)
            RemoteEventHandler.FireOnClient(player, "AMMO_CHANGED", starting)
        end
    end
end

function AmmoManager.setInfinite(value : boolean)

    isInfiniteAmmo = value
    ServerConstants.setValue("infiniteAmmo" , isInfiniteAmmo)
end

function AmmoManager.isInfiniteAmmo()
    return isInfiniteAmmo
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
        regenProgress[userId] = 0
    end
end

function AmmoManager.reset()
    AmmoManager.setInfinite(false)
    table.clear(AmmoStore)
    table.clear(regenProgress)
    if regenConnection then
        regenConnection:Disconnect()
        regenConnection = nil
    end
end

return AmmoManager
