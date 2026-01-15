local serverLoaded = false
local LocalizationService = game:GetService("LocalizationService")
local QueryLoaded = game:GetService("ReplicatedStorage"):WaitForChild("QueryLoaded")

QueryLoaded.OnServerInvoke = function(player)
	return serverLoaded
end

local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()
serverLoaded = true

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local SnowballManger = require(ModuleDirectory.Throwable.SnowballManager)
local SnowballAmmoPickup = require(ModuleDirectory.Systems.Ammo.SnowballAmmoPickup)
local ThrowableManager = require(ModuleDirectory.Throwable.ThrowableManager)
local Onboarding = require(ModuleDirectory.Services.Analytics.Onboarding)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerPool = require(ModuleDirectory.Systems.Round.PlayerPool)
local TutorialManager = require(ModuleDirectory.Systems.Tutorial.TutorialManager)

RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)

	local hasCompletedTutorial = PlayerData.getHasCompletedTutorial(player) or false
	if hasCompletedTutorial then
		PlayerPool.addToPool(player)
	else
		TutorialManager.start(player)
	end
end)

local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
RoundSystem.main()	
