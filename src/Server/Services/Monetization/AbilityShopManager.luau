
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ShovelCustomization = require(ModuleDirectory.Tool.ShovelCustomization)
local CoinManager = require(ModuleDirectory.Monetization.CoinManager)
local AbilityDefinitions = require(ModuleDirectory.Abilities.Definitions)
local EconomyAnalytics = require(ModuleDirectory.Analytics.EconomyAnalytics)

local AbilityShopManager = {}

function AbilityShopManager.init()

    RemoteEventHandler.newEventConnection("REQUEST_EQUIP_ABILITY", function(player : Player , abilityName : string) : nil
        
        local ownedAbilities = PlayerData.getAbilities(player) or {}
        if table.find(ownedAbilities, abilityName) == nil then
            return false
        end

        PlayerData.setAbility(player, abilityName)
        return true

    end)

    RemoteEventHandler.newEventConnection("REQUEST_BUY_ABILITY", function(player : Player , abilityName : string) : nil

        print(player  , abilityName)
        local definition = AbilityDefinitions[abilityName]
        if definition == nil then
            return false
        end

        local ownedAbilities = PlayerData.getAbilities(player) or {}
        if table.find(ownedAbilities, abilityName) then
            return false
        end

        if CoinManager.hasCoins(player, definition.cost) == false then
            return false
        end

        CoinManager.takeCoins(player, definition.cost)
        EconomyAnalytics.logCoinsTransaction(player, -definition.cost, "Sink", "Shop")

        PlayerData.addAbility(player, abilityName)
        PlayerData.setAbility(player, abilityName)
        return true

    end)
    

end

return AbilityShopManager