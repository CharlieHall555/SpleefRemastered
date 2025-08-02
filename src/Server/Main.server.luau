local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local MapGenerator = require(ModuleDirectory.MapGenerator)

local params : MapGenerator.MapCreationParams = {
    size = Vector2.new(10 , 10),
    shape = "Circle"
}

print(MapGenerator.generatePlane(params))

