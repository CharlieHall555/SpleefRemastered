local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local RoundSystem = require(ModuleDirectory.RoundSystem)
RoundSystem.main()
