export type DestroyRecord = {
    player: Player?,
    time: number,
    blockId: number
}

local BlockDestructionTracker = {}

local destroyCache: { [number]: DestroyRecord } = {} -- blockId -> record
local playerCache: { [number]: { number } } = {} -- userId -> list of blockIds

local function getUserId(p: Player?): number?
    return p and p.UserId or nil
end

function BlockDestructionTracker.reset()
    table.clear(destroyCache)
    table.clear(playerCache)
end

function BlockDestructionTracker.getBlocksDestroyedByPlayer(playerOrUserId: Player | number): { number }
    local userId = typeof(playerOrUserId) == "number" and (playerOrUserId :: number) or getUserId(playerOrUserId :: Player)
    if not userId then
        return {}
    end
    local list = playerCache[userId]
    if not list then
        return {}
    end
    return list
end

function BlockDestructionTracker.getDestroyRecord(blockId: number): DestroyRecord?
    return destroyCache[blockId]
end

function BlockDestructionTracker.blockDestroyed(blockId: number, player: Player?)
    if destroyCache[blockId] then
        -- already recorded; ignore duplicates
        return
    end

    local record: DestroyRecord = {
        player = player,
        time = time(),
        blockId = blockId
    }
    destroyCache[blockId] = record

    local userId = getUserId(player)
    if userId then
        local list = playerCache[userId]
        if not list then
            list = {}
            playerCache[userId] = list
        end
        list[#list + 1] = blockId
    end
end

return BlockDestructionTracker