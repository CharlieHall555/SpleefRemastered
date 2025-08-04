local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)

local testMapParams: MapDataFactory.MapDataCreationParams = {
	layerSeperation = 50, -- vertical distance between each layer
	originPosition = Vector3.new(0, 0, 0), -- world‐space origin of your bottom layer
	layerParams = { -- each entry is PlaneFactory.PlaneCreationParams
		{
			size = Vector2.new(20, 20), -- X×Y dimensions
			shape = "Square",
		},
		{
			size = Vector2.new(16, 16),
			shape = "Circle",
		},
		{
			size = Vector2.new(12, 12),
			shape = "Square",
		},
	},
}

-- then generate:
local map = MapGenerator.generate(testMapParams)

local RoundSystem = require(ModuleDirectory.RoundSystem)
RoundSystem.main()