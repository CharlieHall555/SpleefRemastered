local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local PlayerPool = {}
PlayerPool.__index = PlayerPool

-- Internal list of players currently in the pool
local activePool: { Player } = {}

local onAddedToPool : (player : Player) -> ()

local onChange : ((any) -> (any))? = nil

function PlayerPool.init(): nil
    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        PlayerPool.addToPool(player)
    end)

    RemoteEventHandler.newEventConnection("PLAYER_REQUEST_JOIN_POOL", function(player: Player)
        PlayerPool.addToPool(player)
    end)

    RemoteEventHandler.newEventConnection("PLAYER_REQUEST_LEAVE_POOL", function(player: Player)
        PlayerPool.removeFromPool(player)
    end)

    Players.PlayerRemoving:Connect(function(player : Player)
        PlayerPool.removeFromPool(player)
    end)
    
end

function PlayerPool.getActivePool(): { Player }
    return activePool
end

function PlayerPool.addToPool(player: Player): nil
    -- Prevent duplicates
    for _, p in ipairs(activePool) do
        if p == player then
            return

        end
    end
    table.insert(activePool, player)
    if onAddedToPool then
        onAddedToPool(player)
    end
    if onChange then
        onChange(activePool)
    end
end

function PlayerPool.setOnChange(fn : ()->()) :nil
    onChange = fn
end

function PlayerPool.removeFromPool(player: Player): nil
    for i, p in ipairs(activePool) do
        if p == player then
            table.remove(activePool, i)
            if onChange then
                onChange(activePool)
            end
            break
        end
    end
end

function PlayerPool.connectOnAdded(callback: (player: Player) -> ()): nil
    onAddedToPool = callback
end


return PlayerPool