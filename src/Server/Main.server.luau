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
local SnowballAmmoPickup = require(ModuleDirectory.Gameplay.SnowballAmmoPickup)
local ThrowableManager = require(ModuleDirectory.Throwable.ThrowableManager)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
RoundSystem.main()	
