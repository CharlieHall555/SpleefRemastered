local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneGenerator = require(ModuleDirectory.PlaneGenerator)
local GridGenerator = require(ModuleDirectory.GridGenerator)

export type MapGenerationParams = {
layerSeperation: number,
originPosition: Vector3,
layerParams: {PlaneGenerator.PlaneCreationParams}
}

export type layerOutput = {
layerNumber: number,
gridParms: GridGenerator.GridCreationParams,
planeInfo: PlaneGenerator.PlaneCreationOutput
}

export type MapGeneratorOutput = {
layerSeperation: number,
gridToGenerate: {layerOutput}
}

export type MapGenerator = {
generateMap: (self: MapGenerator, params: MapGenerationParams) -> MapGeneratorOutput
}

local MapGenerator = {}

function MapGenerator:generateMap(params: MapGenerationParams): MapGeneratorOutput
    local layerSeperation = params.layerSeperation
    local originPosition = params.originPosition
    local outputs: {layerOutput} = {}


    for layerNumber, planeParams in ipairs(params.layerParams) do
        local worldPosition = originPosition + Vector3.new(0, layerSeperation * (layerNumber - 1), 0)
        local creationParams = table.clone(planeParams)
        creationParams.worldPosition = worldPosition

        local planeInfo = PlaneGenerator.generatePlane(creationParams)
        local gridParms: GridGenerator.GridCreationParams = {
            worldPosition = worldPosition
        }

        table.insert(outputs, {
            layerNumber = layerNumber,
            gridParms = gridParms,
            planeInfo = planeInfo
        })
    end

    return {
        layerSeperation = layerSeperation,
        gridToGenerate = outputs
    }
end

return MapGenerator