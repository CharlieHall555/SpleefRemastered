local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local AnalyticsMain = {}

function AnalyticsMain.init()
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
		local profile = PlayerData.getProfile(player)
		if profile.Data.onboardingComplete == false then
			print("wowowo")
			Onboarding.registerUser(player, profile.Data.onboardingStep)
			Onboarding.action(player, "JOINED_GAME")
		end
	end)

	Onboarding.setCallback(function(player, newStep)
		local profile = PlayerData.getProfile(player)
		if profile then
            print(newStep)
			profile.Data.onboardingStep = newStep
			if newStep >= Onboarding.getNumberOfSteps() then
                print("onboardcomplete")
				profile.Data.onboardingComplete = true
			end
		end
	end)
end

return AnalyticsMain
