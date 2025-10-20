local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Leaderstats = require(ModuleDirectory.Player.Leaderstats)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local Players = game:GetService("Players")

local trackedPlayers = {}

local PlayTimeTracker = {}

local function runTimeLoop(time : number , dt : number)

    for _ , eachPlayer in trackedPlayers do
        
        local count = SessionVariables.getValue(eachPlayer , "playTime")
        dt *= 30
        SessionVariables.setValue(eachPlayer , "playTime" , count + dt)

    end

end

function PlayTimeTracker.resetPlayTime(player : Player)
    SessionVariables.setValue(player , "playTime" , 0)
end


function PlayTimeTracker.getPlayTime(player : Player)
    return SessionVariables.getValue(player , "playTime") or 0
end


function PlayTimeTracker.init()

    Players.PlayerRemoving:Connect(function(player, reason)        
        local pos = table.find(trackedPlayers , player)
        table.remove(trackedPlayers , pos)
    end)

    RunService.Stepped:Connect(runTimeLoop)
    
end

function PlayTimeTracker.trackPlayer(player : Player)

    table.insert(trackedPlayers , player)
    
end

return PlayTimeTracker