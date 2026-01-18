local Debris = game:GetService("Debris")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Agent

local Combat = {}

function Combat.init()
	Agent = require(ModuleDirectory.Systems.Agent.Agent)
end



return Combat
