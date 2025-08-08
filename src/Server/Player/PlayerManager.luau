local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Leaderstats = require(ModuleDirectory.Leaderstats)
local PlayerData = require(ModuleDirectory.PlayerData)

local PlayerManager = {}

function PlayerManager.init()
    
    for _ , eachPlayer in Players:GetPlayers() do
        PlayerManager.Setup(eachPlayer)
    end

    Players.PlayerAdded:Connect(PlayerManager.Setup)

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", Leaderstats.newPlayer)

    Players.PlayerRemoving:Connect(PlayerData.onPlayerRemoving)

    RemoteEventHandler.newEventConnection("QUERY_PROFILE_LOAD" , function(player)
        
        return PlayerData.isProfileLoaded(player)

    end)

    PlayerData.setCallback(PlayerManager.onProfileLoad)

end

function PlayerManager.Setup(player)
    PlayerData.onPlayerAdded(player)
end

function PlayerManager.onProfileLoad(player)
    Leaderstats.updateStat(player , "Wins" , PlayerData.getWins(player))
end

return PlayerManager