
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ShovelCustomization = require(ModuleDirectory.Tool.ShovelCustomization)
local CoinManager = require(ModuleDirectory.Monetization.CoinManager)
local ShovelData = require(ModuleDirectory.ShovelDefinitions)

local ShovelShopManager = {}

function ShovelShopManager.init()

    RemoteEventHandler.newEventConnection("REQUEST_EQUIP_SHOVEL", function(player : Player , shovelName : string) : nil
    
        return ShovelCustomization.equipShovel(player, shovelName)

    end)

    RemoteEventHandler.newEventConnection("REQUEST_BUY_SHOVEL", function(player : Player , shovelName : string) : nil
    
        
        return ShovelCustomization.equipShovel(player, shovelName)

    end)
    

end

return ShovelShopManager