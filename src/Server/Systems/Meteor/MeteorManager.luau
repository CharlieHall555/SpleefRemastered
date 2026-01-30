local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RunService = game:GetService("RunService")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Configurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local Players = game:GetService("Players")

local RunService = game:GetService("RunService")
local MeteorManager = {}

function MeteorManager.init()
    
    RunService.Stepped:Connect(function(time, deltaTime)
        

    end)


end

MeteorManager.spawnMeteor = {}

return MeteorManager