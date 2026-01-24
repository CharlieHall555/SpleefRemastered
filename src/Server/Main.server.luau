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
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerPool = require(ModuleDirectory.Systems.Round.PlayerPool)

RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)

	local hasCompletedTutorial = PlayerData.getHasCompletedTutorial(player) or false
	PlayerPool.addToPool(player)
end)

local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
RoundSystem.main()	
