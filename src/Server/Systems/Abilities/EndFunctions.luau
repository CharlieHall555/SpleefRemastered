local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayersAlive = require(ModuleDirectory.Systems.Round.PlayersInGame)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local AbilitiesFunctions = {}
    
AbilitiesFunctions["DASH"] = function(player , character)
end

AbilitiesFunctions["INFINITE_AMMO"] = function(player , character)

    SessionVariables.setValue(player , "infiniteAmmoAbility" , false)

end

return AbilitiesFunctions