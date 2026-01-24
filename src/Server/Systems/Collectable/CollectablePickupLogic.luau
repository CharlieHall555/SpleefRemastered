local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local AmmoManager = require(ModuleDirectory.Systems.Ammo.AmmoManager)

local CollectablePickupLogic = {}

local collectableFunctions = {}

collectableFunctions.coin = function(fromPlayer)
	local coinsCollected = SessionVariables.getValue(fromPlayer, "coinsCollected") or 0
	SessionVariables.setValue(fromPlayer, "coinsCollected", coinsCollected + 1)
end

collectableFunctions.ammo = function(fromPlayer)
   
    local increment = Config.AMMO_PICKUP_VALUE
    AmmoManager.incrementAmmo(fromPlayer, increment)
    RemoteEventHandler.FireOnClient(fromPlayer, "AMMO_GAINED", increment)
end

function CollectablePickupLogic.processPickup(fromPlayer: Player, collectableType: string) 

    local fn = collectableFunctions[collectableType]
    if fn then
        fn(fromPlayer)
    end
    
end

return CollectablePickupLogic
