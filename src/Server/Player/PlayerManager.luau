local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Leaderstats = require(ModuleDirectory.Player.Leaderstats)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local PlayTimeTracker = require(ModuleDirectory.Player.PlayTimeTracker)

local PlayerManager = {}

local charAddedConnections : {[number] : RBXScriptConnection} = {}

local function onPlayerRemoving(player : Player) 
        local conn = charAddedConnections[player.UserId]
        if conn then
            conn:Disconnect()
            charAddedConnections[player.UserId] = nil
        end 
end

local function onCharacterAdded(player : Player , character : Model )

    local desc = character:GetDescendants()

    for _ , each in desc do
        if each:IsA("BasePart") then
            each.CollisionGroup = "CG_AGENT_OR_PLAYER"
        end
    end

end

function PlayerManager.onLoaded()
    
    for _ , eachPlayer in Players:GetPlayers() do
        PlayerManager.Setup(eachPlayer)
    end

    Players.PlayerAdded:Connect(PlayerManager.Setup)

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", Leaderstats.newPlayer)

    Players.PlayerRemoving:Connect(PlayerData.onPlayerRemoving)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    RemoteEventHandler.newEventConnection("QUERY_PROFILE_LOAD" , function(player)
        
        return PlayerData.isProfileLoaded(player)

    end)

    PlayerData.setCallback(PlayerManager.onProfileLoad)

end

function PlayerManager.Setup(player)
    PlayerData.onPlayerAdded(player)

    charAddedConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player , character)
    end)

end

function PlayerManager.onProfileLoad(player)
    Leaderstats.updateStat(player , "Wins" , PlayerData.getWins(player))
    PlayTimeTracker.trackPlayer(player)
end

return PlayerManager