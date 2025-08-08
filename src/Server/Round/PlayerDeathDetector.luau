local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local PlayersInGame = require(ModuleDirectory.PlayersInGame)
local Players = game:GetService("Players")

local connections = {}

local onDeathCallback = nil
local PlayerDeathDetector = {}

export type playerDeathRecord = {
    userId : number,
    timeOfDeath : number
}

local playerDeathCache : {[number] : playerDeathRecord} = {}

function PlayerDeathDetector.init()
    
    Players.PlayerAdded:Connect(function(player)
        
        local deathConnection = nil

        connections[player.UserId] = player.CharacterAdded:Connect(function(character)

            if deathConnection then
                deathConnection:Disconnect()
            end
            local humanoid = character:WaitForChild("Humanoid")
            deathConnection = humanoid.Died:Connect(function()
                if RoundSystem.getState() == "ACTIVE" then
                    PlayersInGame.removePlayer(player)

                    playerDeathCache[player.UserId] = {
                        userId = player.UserId,
                        timeOfDeath = time()
                    }

                end
                if onDeathCallback then
                    onDeathCallback(player)
                end
            end)
            
        end)

    end)

    Players.PlayerRemoving:Connect(function(player)
        
        local connection = connections[player.UserId]
        if connection then
            connection:Disconnect()
        end

    end)

end

function PlayerDeathDetector.getDeathTime(player : Player) : number?
    local record = playerDeathCache[player.UserId]
    if record then
        return record.timeOfDeath
    else
        return nil
    end
end

function PlayerDeathDetector.clearCache()

    for eachKey , _ in playerDeathCache do
        playerDeathCache[eachKey] = nil
    end
    
end

function PlayerDeathDetector.setCallback(func : (player : Player) -> ())
    onDeathCallback = func
end

return PlayerDeathDetector