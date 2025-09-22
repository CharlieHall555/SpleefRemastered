local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayersAlive = require(ModuleDirectory.Round.PlayersInGame)

local AbilitiesFunctions = {}
    
AbilitiesFunctions["DASH"] = function(player , character)
end

return AbilitiesFunctions