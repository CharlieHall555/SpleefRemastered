local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LayerFactory = require(ModuleDirectory.Map.LayerFactory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local Map = require(ModuleDirectory.Map.Map)

local MapBuilder = {}

function MapBuilder.build(param: MapDataFactory.MapData): Map.Map
    print(param)
    local layers = param.layersToGenerate
    local origin = param.originPosition

    local map = Map.new(origin)
    for _, layerOutput in ipairs(layers) do
        print(layerOutput)
        local Layer = LayerFactory.create(layerOutput.layerParams, layerOutput.planeInfo)
        map:addLayer(Layer)
    end

    return map
end

return MapBuilder