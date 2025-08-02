local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneGenerator = require(ModuleDirectory.PlaneGenerator)
local GridGenerator = require(ModuleDirectory.GridGenerator)
local MapGenerator = require(ModuleDirectory.MapGenerator)
local Map = require(ModuleDirectory.Map.Map)

export type MapBuilder = {
buildMap: (param: MapGenerator.MapGeneratorOutput) -> Map.Map
}

local MapBuilder = {}

function MapBuilder.buildMap(param: MapGenerator.MapGeneratorOutput): Map.Map
    local layers = param.gridToGenerate
    local origin = Vector3.new(0, 0, 0)
    if #layers > 0 and layers[1].gridParms.worldPosition then
    origin = layers[1].gridParms.worldPosition
    end

    local map = Map.new(origin)
    for _, layerOutput in ipairs(layers) do
        local grid = GridGenerator.generateGrid(layerOutput.gridParms, layerOutput.planeInfo)
        map:addGrid(grid)
    end

    return map
end

return MapBuilder