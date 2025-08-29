local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local KnockbackTracker = require(ModuleDirectory.Gameplay.KnockbackTracker)

local lastHitCache: { [number]: number } = {}

local KnockBackManager = {}

local function now(): number
    return time()
end

local function canApplyKnockback(userId: number): boolean
    local cooldown = Config.KNOCKBACK_COOLDOWN or 0
    local last = lastHitCache[userId]
    if not last then
        return true
    end
    return (now() - last) >= cooldown
end

local function markHit(userId: number)
    lastHitCache[userId] = now()
end

function KnockBackManager.init()
    Players.PlayerRemoving:Connect(function(player)
        lastHitCache[player.UserId] = nil
    end)
end

function KnockBackManager.hitHitbox(hitBox: Part, dir: Vector3 , fromPlayer : Player?)
    local char = hitBox.Parent
    if not char then
        return
    end

    local player = Players:GetPlayerFromCharacter(char)
    if not player then
        return
    end

    if not canApplyKnockback(player.UserId) then
        return
    end

    markHit(player.UserId)

    KnockbackTracker.newKnockback(fromPlayer , player)
    RemoteEventHandler.FireOnClient(player, "KNOCKBACK", dir, Config.KNOCKBACK_POWER)
    RemoteEventHandler.FireOnAllClients("KNOCKBACK_ANIMATION", player)

    print(player.DisplayName .. " hIT")
end

return KnockBackManager
