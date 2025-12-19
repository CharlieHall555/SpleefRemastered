local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LayerFactory = require(ModuleDirectory.Map.LayerFactory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local Map = require(ModuleDirectory.Map.Map)

local MapBuilder = {}

function MapBuilder.build(param: MapDataFactory.MapData): Map.Map
    local layers = param.layersToGenerate
    local origin = param.originPosition

    local map = Map.new(origin)
    for layerN, layerOutput in ipairs(layers) do
        local Layer = LayerFactory.create(layerOutput.layerParams, layerOutput.planeInfo)
        Layer.LayerIndex = layerN
        map:addLayer(Layer)
        task.wait()
    end

    return map
end

return MapBuilder