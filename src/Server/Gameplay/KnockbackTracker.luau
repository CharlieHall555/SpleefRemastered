export type KnockbackRecord = {
    playerHit: Player?,
    originPlayer: Player?,
    time: number
}

local KnockbackTracker = {}

local knockbackCache: { [Player]: { KnockbackRecord } } = {}

function KnockbackTracker.reset()
    table.clear(knockbackCache)
end

function KnockbackTracker.newKnockback(fromPlayer: Player, toPlayer: Player)
    if not knockbackCache[toPlayer] then
        knockbackCache[toPlayer] = {}
    end

    local record: KnockbackRecord = {
        playerHit = toPlayer,
        originPlayer = fromPlayer,
        time = time()
    }

    table.insert(knockbackCache[toPlayer], 1, record)
end

function KnockbackTracker.getKnockbacksFor(player: Player): { KnockbackRecord }
    return knockbackCache[player] or {}
end

return KnockbackTracker
