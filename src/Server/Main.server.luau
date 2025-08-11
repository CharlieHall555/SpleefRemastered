local serverLoaded = false
local QueryLoaded = game:GetService("ReplicatedStorage"):WaitForChild("QueryLoaded")

QueryLoaded.OnServerInvoke = function(player)
	return serverLoaded
end

local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()
serverLoaded = true

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local SnowballAmmoPickup = require(ModuleDirectory.Gameplay.SnowballAmmoPickup)



local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
RoundSystem.main()

