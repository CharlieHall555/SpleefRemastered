local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local PlaneGenerator = require(ModuleDirectory.PlaneGenerator)

local params : PlaneGenerator.PlaneCreationParams = {
    size = Vector2.new(10 , 10),
    shape = "Circle"
}

local output = PlaneGenerator.generatePlane(params)

local GridGenerator = require(ModuleDirectory.GridGenerator)
local params2 : GridGenerator.GridCreationParams = {
    worldPosition = Vector3.new(0 , 50 , 0)
}

GridGenerator.generateGrid(params2 , output)