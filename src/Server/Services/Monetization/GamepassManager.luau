local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerSessionVariables = require(ModuleDirectory.Player.SessionVariables)
local GamepassData = require(ModuleDirectory.Monetization.GamepassData)
local ShovelCustomization = require(ModuleDirectory.Tool.ShovelCustomization)
local MarketplaceService = game:GetService("MarketplaceService")
local Overhead = require(ModuleDirectory.Overhead)

local GamepassManager = {}

local onJoinFunctions = {}

onJoinFunctions["1502155612"] = function(player)
    PlayerSessionVariables.setValue(player , "coinsMultiplier" , 2)
end

onJoinFunctions["1502789277"] = function(player)
    PlayerSessionVariables.setValue(player , "isVIP" , true)
    ShovelCustomization.giveShovel(player , "VIP")
    Overhead.refreshForPlayer(player)
end

local onBuyFunctions = {}

onBuyFunctions["1502155612"] = function(player)
    PlayerSessionVariables.setValue(player , "coinsMultiplier" , 2)
end

onBuyFunctions["1502789277"] = function(player)
    PlayerSessionVariables.setValue(player , "isVIP" , true)
    ShovelCustomization.giveShovel(player , "VIP")
    Overhead.refreshForPlayer(player)
end

function GamepassManager.init()
    
    RemoteEventHandler.newEventConnection("PLAYER_LOADED" , function(player)
        GamepassManager.determineOnwership(player)

        for passId , eachFunc in onJoinFunctions do
            local ownedGamepasses = PlayerSessionVariables.getValue(player , "ownedGamepasses") or {}
            if table.find(ownedGamepasses , passId) then
                eachFunc(player)
            end
        end

    end)

    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        if wasPurchased then
            local passIdStr = tostring(gamePassId)
            local ownedGamepasses = PlayerSessionVariables.getValue(player , "ownedGamepasses") or {}
            if not table.find(ownedGamepasses , passIdStr) then
                table.insert(ownedGamepasses , passIdStr)
                PlayerSessionVariables.setValue(player , "ownedGamepasses" , ownedGamepasses)
            end

            local func = onBuyFunctions[passIdStr] or onJoinFunctions[passIdStr]
            if func then
                func(player)
            end
        end
    end)
end

function GamepassManager.determineOnwership(player)
    
    for _ , each in GamepassData do

        local gamepassId = each.passId
        
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
        end)

        if success and owns then
            local ownedGamepasses = PlayerSessionVariables.getValue(player , "ownedGamepasses") or {}
            if not table.find(ownedGamepasses , gamepassId) then
                table.insert(ownedGamepasses , gamepassId)
                PlayerSessionVariables.setValue(player , "ownedGamepasses" , ownedGamepasses)
            end
        end
    end

end


return GamepassManager