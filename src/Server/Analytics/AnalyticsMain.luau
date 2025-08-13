
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local AnalyticsMain = {}

function AnalyticsMain.init()
    
    RemoteEventHandler.newEventConnection("PLAYER_LOADED" , function(player)
        
        local profile = PlayerData.getProfile(player)
        if profile.Data.onboardingComplete == false then
            
            Onboarding.registerUser(player , profile.Data.onboardingStep)
            Onboarding.action(player , "JOINED_GAME")

        end


    end)

end

return AnalyticsMain