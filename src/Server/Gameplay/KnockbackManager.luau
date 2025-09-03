local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local KnockbackTracker = require(ModuleDirectory.Gameplay.KnockbackTracker)
local KnockbackUtilities = require(ModuleDirectory.KnockbackUtilities)

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

function KnockBackManager.hitHitbox(hitBox: Part, dir: Vector3, fromPlayer: Player?)
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

    local primary = char.PrimaryPart
    if not primary then
        return
    end

    KnockbackTracker.newKnockback(fromPlayer, player)
    RemoteEventHandler.FireOnAllClients("KNOCKBACK_ANIMATION", player)

    if primary:GetNetworkOwner() == player then
        RemoteEventHandler.FireOnClient(player, "KNOCKBACK", dir, Config.KNOCKBACK_POWER)
    else
        -- apply on server (server has or will take network ownership)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not humanoid or not rootPart then
            return
        end

        if dir.Magnitude < 1e-3 then
            return
        end

        local power = Config.KNOCKBACK_POWER or 0
        if power <= 0 then
            return
        end

        -- Compute physics-consistent impulse (matches client behavior)
        local impulse = KnockbackUtilities.computeImpulse(rootPart, humanoid, dir, power)

        -- Optional micro-lift to reduce ground stickiness (tune as needed)
        impulse += Vector3.new(0, rootPart.AssemblyMass * 15, 0)

        rootPart:ApplyImpulse(impulse)
    end
end

return KnockBackManager
