local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local PlayersInGame = {}
PlayersInGame.__index = PlayersInGame

-- Internal list of players currently in the game
local activePlayers: { Player } = {}

-- Optional callback invoked when the activePlayers list changes
local onChange: ((players: { Player }) -> ())? = nil

-- Returns the current list (caller should not mutate it directly)
function PlayersInGame.getActivePlayers(): { Player }
    return activePlayers
end

function PlayersInGame.isAlive(player: Player): boolean
    for _, p in ipairs(activePlayers) do
        if p == player then
            return true
        end
    end
    return false
end

function PlayersInGame.addAgent()
    
end

function PlayersInGame.addPlayer(player: Player , fireOnChangeCallback : boolean?): nil
    -- Prevent duplicates
    for _, p in ipairs(activePlayers) do
        if p == player then
            return
        end
    end
    table.insert(activePlayers, player)
    if onChange and fireOnChangeCallback then
        onChange(activePlayers)
    end
end

function PlayersInGame.removePlayer(player: Player): nil
    for i, p in ipairs(activePlayers) do
        if p == player then
            table.remove(activePlayers, i)
            if onChange then
                onChange(activePlayers)
            end
            break
        end
    end
    
end

function PlayersInGame.setOnChange(fn: (players: { Player }) -> ()): nil
    onChange = fn
end

function PlayersInGame.getSize(): number
    return #activePlayers
end

function PlayersInGame.clear(): nil
    activePlayers = {}
    if onChange then
        onChange(activePlayers)
    end
end

function PlayersInGame.init()

    game.Players.PlayerRemoving:Connect(function(player : Player)
        
        PlayersInGame.removePlayer(player)

    end)

    RemoteEventHandler.newEventConnection("QUERY_ALIVE" , function(player)
        
        return PlayersInGame.getActivePlayers()

    end)
    
end

return PlayersInGame
