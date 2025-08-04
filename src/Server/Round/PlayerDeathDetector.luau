local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerPool = require(ModuleDirectory.PlayerPool)
local PlayersInGame = require(ModuleDirectory.PlayersInGame)
local Players = game:GetService("Players")

local connections = {}

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

return PlayerDeathDetector