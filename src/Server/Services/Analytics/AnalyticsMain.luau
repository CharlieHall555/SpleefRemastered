local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local ProfileManager = require(ModuleDirectory.Player.ProfileManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local AnalyticsMain = {}

function AnalyticsMain.init()
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
		local profile = ProfileManager.getProfile(player)
		if profile.Data.onboardingComplete == false then
			Onboarding.registerUser(player, profile.Data.onboardingStep)
			Onboarding.action(player, "JOINED_GAME")
		end
	end)

	Onboarding.setCallback(function(player, newStep)
		local profile = ProfileManager.getProfile(player)
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
