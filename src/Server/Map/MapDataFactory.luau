local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneFactory = require(ModuleDirectory.Map.PlaneFactory)
local LayerFactory = require(ModuleDirectory.Map.LayerFactory)

export type MapDataCreationParams = {
	layerSeperation: number,
	originPosition: Vector3,
	layerParams: { PlaneFactory.PlaneCreationParams },
}

export type layerOutput = {
	layerNumber: number,
	layerParms: LayerFactory.LayerCreationParams,
	planeInfo: PlaneFactory.PlaneData,
}

export type MapData = {
	originPosition: Vector3,
	layersToGenerate: { layerOutput },
}

local MapDataFactory = {}

function MapDataFactory.create(params: MapDataCreationParams): MapData
	local origin = params.originPosition
	local outputs: { any } = {}

	for i, planeParams in ipairs(params.layerParams) do
		local height = origin.Y + planeParams.seperation * (i - 1)
		-- Calculate worldPosition so each layer is centered at origin X,Z
		local worldPosition = Vector3.new(origin.X, height, origin.Z)

		local clonedParams = table.clone(planeParams)

		local planeInfo = PlaneFactory.create(clonedParams)
		local layerParams: LayerFactory.LayerCreationParams = {
			worldPosition = worldPosition,
		}

		table.insert(outputs, {
			layerNumber = i,
			layerParams = layerParams,
			planeInfo = planeInfo,
		})
	end

	return {
		layersToGenerate = outputs,
		originPosition = origin,
	}
end

return MapDataFactory
