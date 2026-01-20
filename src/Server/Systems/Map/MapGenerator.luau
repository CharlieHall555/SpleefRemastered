--!strict

local MapGenerator = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LavaManager = require(ModuleDirectory.Systems.Gameplay.LavaManager) -- kept as-is (even if unused here)
local Map = require(ModuleDirectory.Systems.Map.Map)
local Block = require(ModuleDirectory.Systems.Map.Block)
local Layer = require(ModuleDirectory.Systems.Map.Layer)
local MapSaves = require(ModuleDirectory.Systems.Map.MapSaves)
local PlaneGenerator = require(ModuleDirectory.Systems.Map.PlaneGenerator)
local ServerConfigurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local LavaManager = require(ModuleDirectory.Systems.Gameplay.LavaManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

--ServerConfigurations.MAX_PARTS_PER_FRAME_PER_LAYER

local BackgroundFolder: Folder?

function MapGenerator.init()
	BackgroundFolder = game:GetService("ServerStorage"):WaitForChild("Background")
	assert(BackgroundFolder)
end

local function cloneAndPlaceBackground(mapData: MapSaves.MapSave): Model
	assert(BackgroundFolder, "MapGenerator.init() must be called before MapGenerator.generate()")

	local backgroundName = mapData.background
	local template = BackgroundFolder:FindFirstChild(backgroundName) or BackgroundFolder.Background1
	local newBackground = template:Clone()

	if newBackground.PrimaryPart == nil then
		error("Background model " .. newBackground.Name .. " is missing a PrimaryPart.")
	end

	local lavaPart = newBackground:FindFirstChild("Lava")
	if lavaPart then
		LavaManager.setLava(lavaPart)
	end

	newBackground:PivotTo(CFrame.new(mapData.originPosition or Vector3.new(0, 0, 0)))
	newBackground.Parent = game.Workspace


	return newBackground
end

local function resolveOriginAndPersist(mapData: MapSaves.MapSave, backgroundModel: Model): Vector3
	local origin = (backgroundModel:FindFirstChild("MapOrigin") :: any).Position or Vector3.new(0, 0, 0)
	mapData.originPosition = origin
	return origin
end

local function createAndAttachLayer(newMap: Map.Map, origin: Vector3, index: number, params: MapSaves.LayerParams): Layer.Layer
	local eachLayerConfig: Layer.LayerConfig = {
		originPosition = origin,
		size = params.size,
		layerIndex = index,
		spawnsAmmo = params.spawnsAmmo,
	}

	local newLayer = Layer.new(eachLayerConfig)
	
	local relativeHeight = newLayer.originPosition.Y - newMap.originPosition.Y
	local layerOnHeight = newMap:getLayerAtHeight(relativeHeight)

	newMap:addLayer(newLayer)
	newLayer:setParentMap(newMap)
	return newLayer
end

local function generatePlane(params: MapSaves.LayerParams): any
	local planeGenerationParams: PlaneGenerator.PlaneCreationParams = {
		size = params.size,
		shape = params.shape,
		tileMap = params.tileMap,
	}
	return PlaneGenerator.create(planeGenerationParams)
end

local function placeBlocksForPlaneData(
	newLayer: Layer.Layer,
	origin: Vector3,
	params: MapSaves.LayerParams,
	planeData: any
)

    local width = #planeData
    local height = #planeData[1]

    -- Calculate the top-left corner so layer is centered on 'center'
    local halfWidth  = (width - 1) * ServerConfigurations.BLOCK_SIZE / 2
    local halfHeight = (height - 1) * ServerConfigurations.BLOCK_SIZE / 2
    local originCorner = Vector3.new(
        origin.X - halfWidth,
        origin.Y,
        origin.Z - halfHeight
    )

	-- Throttle block creation so we don't spawn too many parts in one frame
	local maxPerFrame = ServerConfigurations.MAX_PARTS_PER_FRAME_PER_LAYER
	if maxPerFrame == nil or maxPerFrame <= 0 then
		maxPerFrame = math.huge
	end

	local placedThisFrame = 0

	for x, eachRow in planeData do
		for y, eachPlaceInfo: PlaneGenerator.PlaceInfo in eachRow do
			if eachPlaceInfo.place then
				local newBlockConfig: Block.BlockConfig = {
					material = eachPlaceInfo.material or "grass",
					worldPosition = originCorner
						+ Vector3.new(
							ServerConfigurations.BLOCK_SIZE * x,
							0,
							ServerConfigurations.BLOCK_SIZE * y
						),
					layerPosition = Vector2.new(x, y),
				}

				local newBlock = Block.new(newBlockConfig)
				newLayer:addBlock(newBlock, Vector2.new(x, y))
				newBlock:setParentLayer(newLayer)

				placedThisFrame += 1
				if placedThisFrame >= maxPerFrame then
					placedThisFrame = 0
					task.wait() -- yield to next frame
				end
			end
		end
	end
end

--yields
function MapGenerator.generate(mapData: MapSaves.MapSave): Map.Map
	local startTime = os.clock()
	
	local backgroundModel = cloneAndPlaceBackground(mapData)
	local origin = resolveOriginAndPersist(mapData, backgroundModel)

	RemoteEventHandler.FireOnAllClients("NEW_BACKGROUND_LOADED" , backgroundModel)
	
	local newMap = Map.new(origin)
	newMap:setBackground(backgroundModel)

	for index, eachLayerParams: MapSaves.LayerParams in (mapData.layerParams or {}) do
        local layerOrigin = Vector3.new(origin.X , origin.Y + eachLayerParams.height , origin.Z)
		local newLayer = createAndAttachLayer(newMap, layerOrigin, index, eachLayerParams)
		local planeData = generatePlane(eachLayerParams)
		placeBlocksForPlaneData(newLayer, layerOrigin, eachLayerParams, planeData)
        
	end
	
	local elapsed = os.clock() - startTime
	warn(string.format("[MapGenerator] Map generation completed in %.3f seconds", elapsed))

	return newMap
end

return MapGenerator
