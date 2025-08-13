--non persistent varaibles to be stored about player that may be needed by many scripts.
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Players = game:GetService("Players")

local PlayerSessionVariables = {}

local cache : {[number] : {}} = {}

function PlayerSessionVariables.init()
    
    RemoteEventHandler.newEventConnection("PLAYER_LOADED" , function(player , platform)
        PlayerSessionVariables.create(player)
        local table = PlayerSessionVariables.get(player)
        table.platform = platform
    end)

    Players.PlayerRemoving:Connect(PlayerSessionVariables.cleanup)

end

function PlayerSessionVariables.create(player : Player) 
    
    cache[player.UserId] = {}
    
end

function PlayerSessionVariables.cleanup(player : Player)
    
    cache[player.UserId] = nil
    
end


function PlayerSessionVariables.get(player : Player) : {}
    return cache[player.UserId]
end

return PlayerSessionVariables