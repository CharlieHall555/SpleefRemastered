local MapGenerator = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LayerGenerator = require(ModuleDirectory.Map.LayerFactory)
local PlaneFactory = require(ModuleDirectory.Map.PlaneFactory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local MapBuilder = require(ModuleDirectory.Map.MapBuilder)
local Map = require(ModuleDirectory.Map.Map)

function MapGenerator.generate(params : MapDataFactory.MapDataCreationParams) : Map.Map
    
    print(params)

    local MapData = MapDataFactory.create(params)
    print("generate complete.")
    return MapBuilder.build(MapData)

end

return MapGenerator
