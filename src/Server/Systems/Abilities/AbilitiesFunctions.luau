local LocalizationService = game:GetService("LocalizationService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayersAlive = require(ModuleDirectory.Systems.Round.PlayersInGame)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local BombManager = require(ModuleDirectory.Bomb.BombManager)

local AbilitiesFunctions = {}

AbilitiesFunctions["BOMB"] = function(player , character)

    local bombPosition = character.HumanoidRootPart.Position
    BombManager.createBomb(bombPosition)

end
    
AbilitiesFunctions["DASH"] = function(player , character)
end

AbilitiesFunctions["INFINITE_AMMO"] = function(player , character)

    SessionVariables.setValue(player , "infiniteAmmoAbility" , true)

end

return AbilitiesFunctions