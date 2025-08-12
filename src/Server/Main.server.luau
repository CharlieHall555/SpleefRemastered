local serverLoaded = false
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


local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
RoundSystem.main()

	
--[[while true do
	ThrowableManager.newThrowable(game.Workspace.SpawnLocation.Position + Vector3.new(0 ,10 ,0), Vector3.new(math.random(),math.random(), math.random()) , "snowball")
	ThrowableManager.newThrowable(game.Workspace.SpawnLocation.Position + Vector3.new(0 ,10 ,0), Vector3.new(math.random(),math.random(), math.random()) , "snowball")
	task.wait()
end]]--
