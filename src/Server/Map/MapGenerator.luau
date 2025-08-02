local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LayerGenerator = require(ModuleDirectory.Map.LayerFactory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local Map = require(ModuleDirectory.Map.Map)

local MapBuilder = {}

function MapBuilder.generate(param: MapDataFactory.MapData): Map.Map
    local layers = param.LayerToGenerate
    local origin = Vector3.new(0, 0, 0)
    if #layers > 0 and layers[1].LayerParms.worldPosition then
    origin = layers[1].LayerParms.worldPosition
    end

    local map = Map.new(origin)
    for _, layerOutput in ipairs(layers) do
        local Layer = LayerGenerator.create(layerOutput.LayerParms, layerOutput.planeInfo)
        map:addLayer(Layer)
    end

    return map
end

return MapBuilder