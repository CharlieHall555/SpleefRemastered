local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerConfigurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local LayerUtilities = require(ModuleDirectory.LayerUtilities)

local MapUtilities = {}

local currentMap  = nil
local groupedLayers : {[number] : {}} = {}

function MapUtilities.setCurrentMap(newMap : any)
    
    currentMap = newMap
    groupedLayers = LayerUtilities.groupLayers(currentMap.layers)
    
end

function MapUtilities.getLayerFromAgentPos(agentPosition: Vector3): number?
	
	return LayerUtilities.getLayerPositionIsOn(groupedLayers , agentPosition)

end

local function roundToNearest(n: number): number
	if n >= 0 then
		return math.floor(n + 0.5)
	else
		return math.ceil(n - 0.5)
	end
end

function MapUtilities.snapTile2(v3: Vector3): Vector2
	local origin: Vector3 = currentMap.originPosition -- center
	local mapSize: Vector2 = currentMap:getSize()
	local TILE_SIZE = ServerConfigurations.BLOCK_SIZE

	local localX = (v3.X - origin.X) / TILE_SIZE
	local localZ = (v3.Z - origin.Z) / TILE_SIZE

	-- convert centered coords to 0..size-1
	local localX01 = localX + (mapSize.X - 1) / 2
	local localZ01 = localZ + (mapSize.Y - 1) / 2

	local tileX = roundToNearest(localX01)
	local tileZ = roundToNearest(localZ01)

	tileX = math.clamp(tileX, 0, mapSize.X - 1)
	tileZ = math.clamp(tileZ, 0, mapSize.Y - 1)

	return Vector2.new(tileX, tileZ)
end



return MapUtilities