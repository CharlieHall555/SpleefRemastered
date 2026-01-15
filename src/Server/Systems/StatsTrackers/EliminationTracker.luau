local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockDestructionTracker = require(ModuleDirectory.Systems.Gameplay.BlockDestructionTracker)
local PlayerDeathDetector = require(ModuleDirectory.Systems.Round.PlayerDeathDetector)
local TouchedBlockTracker = require(ModuleDirectory.Systems.Stats.TouchedBlockTracker)
local KnockbackTracker = require(ModuleDirectory.Systems.Stats.KnockbackTracker)

export type EliminationTracker = {
    configure: (opts: { knockbackWindow: number?, tileWindow: number? }) -> nil,
    getEliminator: (playerWhoDied: Player) -> Player?,
    getElimationsFor: (player: Player) -> { Player },
    reset: () -> nil
}

local EliminationTracker: EliminationTracker = {}

-- Tunables (adjust in playtests)
local T_KNOCKBACK_WINDOW = 4 -- seconds: max time from knockback to death
local T_TILE_WINDOW = 2 -- seconds: max time from block break to death
local REQUIRE_TOUCH_BEFORE_BREAK = true -- must have touched block before it broke

-- Local state for simple attribution stats
local _victimsByKiller: { [Player]: { Player } } = {}

function EliminationTracker.configure(opts: { knockbackWindow: number?, tileWindow: number? })
    if opts.knockbackWindow then T_KNOCKBACK_WINDOW = opts.knockbackWindow end
    if opts.tileWindow then T_TILE_WINDOW = opts.tileWindow end
end

-- Knockback attribution
local function resolveKnockbackKO(victim: Player, deathTime: number): Player?
    local knocks: { KnockbackTracker.KnockbackRecord } = KnockbackTracker.getKnockbacksFor(victim) or {}
    local best: KnockbackTracker.KnockbackRecord? = nil

    for _, rec in ipairs(knocks) do
        if rec and rec.time and rec.originPlayer and rec.originPlayer ~= victim then
            local dt = deathTime - rec.time
            if dt >= 0 and dt <= T_KNOCKBACK_WINDOW then
                if not best or rec.time > best.time then
                    best = rec
                end
            end
        end
    end

    return best and best.originPlayer or nil
end

-- Tile-break attribution
local function resolveTileBreakKO(victim: Player, deathTime: number): Player?
    local touches: { TouchedBlockTracker.TouchRecord } = TouchedBlockTracker.getLastTouchedBlocks(victim) or {}

    for _, touch in ipairs(touches) do
        if touch and touch.blockId and touch.time then
            local record = BlockDestructionTracker.getDestroyRecord(touch.blockId)
            if record and record.time and record.player and record.player ~= victim then
                local breakDt = deathTime - record.time
                local touchedBeforeBreakOk = (not REQUIRE_TOUCH_BEFORE_BREAK) or (record.time >= touch.time)
                if breakDt >= 0 and breakDt <= T_TILE_WINDOW and touchedBeforeBreakOk then
                    return record.player
                end
            end
        end
    end

    return nil
end

-- Main attribution function
function EliminationTracker.getEliminator(playerWhoDied: Player): Player?
    if not playerWhoDied then
        return nil
    end

    local deathTime: number? = PlayerDeathDetector.getDeathTime and PlayerDeathDetector.getDeathTime(playerWhoDied) or nil
    if not deathTime then
        return nil
    end

    -- 1) Knockback attribution first
    local kbKiller = resolveKnockbackKO(playerWhoDied, deathTime)
    if kbKiller and kbKiller ~= playerWhoDied then
        _victimsByKiller[kbKiller] = _victimsByKiller[kbKiller] or {}
        table.insert(_victimsByKiller[kbKiller], playerWhoDied)
        return kbKiller
    end

    -- 2) Tile-break attribution
    local tileKiller = resolveTileBreakKO(playerWhoDied, deathTime)
    if tileKiller and tileKiller ~= playerWhoDied then
        _victimsByKiller[tileKiller] = _victimsByKiller[tileKiller] or {}
        table.insert(_victimsByKiller[tileKiller], playerWhoDied)
        return tileKiller
    end

    -- 3) No clear killer or self-caused = suicide
    return nil
end

function EliminationTracker.getElimationsFor(player: Player): { Player }
    local list = _victimsByKiller[player]
    if not list then
        return {}
    end
    local copy: { Player } = {}
    for i = 1, #list do
        copy[i] = list[i]
    end
    return copy
end

function EliminationTracker.reset()
    for k in pairs(_victimsByKiller) do
        _victimsByKiller[k] = nil
    end
end

return EliminationTracker
