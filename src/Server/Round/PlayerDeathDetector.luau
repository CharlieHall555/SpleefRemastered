local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local PlayersInGame = require(ModuleDirectory.PlayersInGame)
local Players = game:GetService("Players")

local connections = {}

local onDeathCallback = nil
local PlayerDeathDetector = {}

function PlayerDeathDetector.init()
    
    Players.PlayerAdded:Connect(function(player)
        
        local deathConnection = nil

        connections[player.UserId] = player.CharacterAdded:Connect(function(character)

            if deathConnection then
                deathConnection:Disconnect()
            end
            local humanoid = character:WaitForChild("Humanoid")
            deathConnection = humanoid.Died:Connect(function()
                print("died")
                if RoundSystem.getState() == "ACTIVE" then
                    PlayersInGame.removePlayer(player)
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

function PlayerDeathDetector.setCallback(func : (player : Player) -> ())
    onDeathCallback = func
end

return PlayerDeathDetector