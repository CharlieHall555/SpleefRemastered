local serverLoaded = false
local QueryLoaded = game:GetService("ReplicatedStorage"):WaitForChild("QueryLoaded")

QueryLoaded.OnServerInvoke = function(player)
	return serverLoaded
end

local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()
serverLoaded = true

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local SnowballAmmoPickup = require(ModuleDirectory.SnowballAmmoPickup)

task.spawn(function()
	while true do
		task.wait(1)
		SnowballAmmoPickup.new(Vector3.new(math.random(-100, 100), 107, math.random(-100, 100)
))
	end
end)

local RoundSystem = require(ModuleDirectory.RoundSystem)
RoundSystem.main()

