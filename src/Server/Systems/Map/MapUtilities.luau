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

function MapUtilities.snapTile2(v3: Vector3): Vector2
	-- Map info
	local origin: Vector3 = currentMap.originPosition -- center of map
	local mapSize: Vector2 = currentMap:getSize()     -- size in tiles (X, Z)
	local TILE_SIZE = ServerConfigurations.BLOCK_SIZE

	-- Convert world position to map-local space
	local localX = (v3.X - origin.X) / TILE_SIZE
	local localZ = (v3.Z - origin.Z) / TILE_SIZE

	-- Snap to nearest tile
	local tileX = math.floor(localX + 0.5)
	local tileZ = math.floor(localZ + 0.5)

	-- Optional: clamp to map bounds
	tileX = math.clamp(tileX, 0, mapSize.X - 1)
	tileZ = math.clamp(tileZ, 0, mapSize.Y - 1)

	return Vector2.new(tileX, tileZ)
end


return MapUtilities