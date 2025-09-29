local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerSessionVariables = require(ModuleDirectory.Player.SessionVariables)
local GamepassData = require(ModuleDirectory.Monetization.GamepassData)
local ShovelCustomization = require(ModuleDirectory.Tool.ShovelCustomization)
local MarketplaceService = game:GetService("MarketplaceService")

local GamepassManager = {}

local onJoinFunctions = {}

onJoinFunctions["1502155612"] = function(player)
    PlayerSessionVariables.setValue(player , "coinsMultiplier" , 2)
end

onJoinFunctions["1502789277"] = function(player)
    PlayerSessionVariables.setValue(player , "isVIP" , true)
    ShovelCustomization.giveShovel(player , "VIP")
end

function GamepassManager.init()
    
    RemoteEventHandler.newEventConnection("PLAYER_LOADED" , function(player)
        GamepassManager.determineOnwership(player)
    end)
    
    print(PlayerSessionVariables.getValue("ownedGamepasses"))

end

function GamepassManager.determineOnwership(player)
    
    for _ , each in GamepassData do

        local gamepassId = each.passId
        
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
        end)

        print("Owns" , gamepassId , owns)

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