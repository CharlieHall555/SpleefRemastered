
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ShovelCustomization = require(ModuleDirectory.Tool.ShovelCustomization)
local CoinManager = require(ModuleDirectory.Monetization.CoinManager)
local ShovelDefinitions = require(ModuleDirectory.ShovelDefinitions)
local EconomyAnalytics = require(ModuleDirectory.Analytics.EconomyAnalytics)

local ShovelShopManager = {}

function ShovelShopManager.init()

    RemoteEventHandler.newEventConnection("REQUEST_EQUIP_SHOVEL", function(player : Player , shovelName : string) : nil
        print(PlayerData.getShovels(player))
        print(player  , shovelName)
        return ShovelCustomization.equipShovel(player, shovelName)

    end)

    RemoteEventHandler.newEventConnection("REQUEST_BUY_SHOVEL", function(player : Player , shovelName : string) : nil
        print(player  , shovelName)
        local definition = ShovelDefinitions[shovelName]
        if definition == nil then
            return false
        end

        local ownedShovels = PlayerData.getShovels(player) or {}
        if table.find(ownedShovels, shovelName) then
            return false
        end

        if CoinManager.hasCoins(player, definition.cost) == false then
            return false
        end

        CoinManager.takeCoins(player , definition.cost)
        EconomyAnalytics.logCoinsTransaction(player, -definition.cost , "Sink" , "Shop")

        ShovelCustomization.giveShovel(player, shovelName)
        ShovelCustomization.equipShovel(player, shovelName)
        return true

    end)
    

end

return ShovelShopManager