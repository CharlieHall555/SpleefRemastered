local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneFactory = require(ModuleDirectory.Map.PlaneFactory)
local LayerFactory = require(ModuleDirectory.Map.LayerFactory)

export type MapGenerationParams = {
layerSeperation: number,
originPosition: Vector3,
layerParams: {PlaneFactory.PlaneCreationParams}
}

export type layerOutput = {
layerNumber: number,
LayerParms: LayerFactory.LayerCreationParams,
planeInfo: PlaneFactory.PlaneData
}

export type MapData = {
layerSeperation: number,
LayerToGenerate: {layerOutput}
}


local MapGenerator = {}

function MapGenerator:generateMap(params: MapGenerationParams): MapData
    local layerSeperation = params.layerSeperation
    local originPosition = params.originPosition
    local outputs: {layerOutput} = {}


    for layerNumber, planeParams in ipairs(params.layerParams) do
        local worldPosition = originPosition + Vector3.new(0, layerSeperation * (layerNumber - 1), 0)
        local creationParams = table.clone(planeParams)
        creationParams.worldPosition = worldPosition

        local planeInfo = PlaneFactory.create(creationParams)
        local LayerParms: LayerFactory.LayerCreationParams = {
            worldPosition = worldPosition
        }

        table.insert(outputs, {
            layerNumber = layerNumber,
            LayerParms = LayerParms,
            planeInfo = planeInfo
        })
    end

    return {
        layerSeperation = layerSeperation,
        LayerToGenerate = outputs
    }
end

return MapGenerator