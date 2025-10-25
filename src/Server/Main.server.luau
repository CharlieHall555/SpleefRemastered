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
local SnowballAmmoPickup = require(ModuleDirectory.Ammo.SnowballAmmoPickup)
local ThrowableManager = require(ModuleDirectory.Throwable.ThrowableManager)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerPool = require(ModuleDirectory.Round.PlayerPool)
local TutorialManager = require(ModuleDirectory.Tutorial.TutorialManager)

RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
	TutorialManager.start(player)
end)

local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
RoundSystem.main()	
