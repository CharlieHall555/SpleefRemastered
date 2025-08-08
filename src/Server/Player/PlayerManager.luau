local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Leaderstats = require(ModuleDirectory.Leaderstats)
local PlayerData = require(ModuleDirectory.PlayerData)

local PlayerManager = {}

function PlayerManager.init()
    
    Players.PlayerAdded:Connect(PlayerData.onPlayerAdded)

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", Leaderstats.newPlayer)

    Players.PlayerRemoving:Connect(PlayerData.onPlayerRemoving)

end


return PlayerManager