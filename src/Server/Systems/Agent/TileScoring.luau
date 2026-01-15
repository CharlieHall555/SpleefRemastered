local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LayerUtilities = require(ModuleDirectory.LayerUtilities)
local ServerConfigurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local TileScoreDebug = require(ModuleDirectory.DebugTools.TileScoreDebug)

local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local TouchedBlockTracker = require(ModuleDirectory.Systems.Stats.TouchedBlockTracker)

local LoadedLayers = require(ModuleDirectory.Systems.Map.LoadedLayers)
local LoadedBlocks = require(ModuleDirectory.Systems.Map.LoadedBlocks)

local TileScoring = {}

local currentMap  = nil
local groupedLayers : {[number] : {}} = {}

-- IMPORTANT: keys are layerY (e.g. 15, 30, 45)
local combinedLayer : {[number] : {[string] : {}}} = {}
local scoreGrid : {[number] : {[string] : any}} = {}
local neighborCount : {[number] : {[string] : number}} = {}


export type TileScore = {
	position : Vector2,
	layerY : number,
	ProxScore : number,
	NeighborScore : number,
	blockId : number?,
}

local NEIGHBORS = {
	Vector2.new(1, 0),
	Vector2.new(-1, 0),
	Vector2.new(0, 1),
	Vector2.new(0, -1),
}

local NEIGHBORS_8 = {
	Vector2.new( 1,  0), Vector2.new(-1,  0),
	Vector2.new( 0,  1), Vector2.new( 0, -1),
	Vector2.new( 1,  1), Vector2.new( 1, -1),
	Vector2.new(-1,  1), Vector2.new(-1, -1),
}

local function snapTile(v: Vector2): Vector2
	-- prevents "(12.00001, 7)" key mismatch
	return Vector2.new(math.floor(v.X + 0.5), math.floor(v.Y + 0.5))
end

local function initScoreGrid()
	scoreGrid = {}

	for layerY, eachLayerData in pairs(combinedLayer) do
		scoreGrid[layerY] = {}

		for posKey, block in pairs(eachLayerData) do
			local pos2 = VectorUtil.DeserializeVector2(posKey)

			scoreGrid[layerY][posKey] = {
				position = pos2,
				layerY = layerY,
				Score = 0,
				NeighborScore = 0,
				ProxScore = 0,
				blockId = block._blockId
			}
		end
	end
end

local function initNeighborCount()
	neighborCount = {}

	for layerY, layerData in pairs(combinedLayer) do
		neighborCount[layerY] = {}

		for posKey, _ in pairs(layerData) do
			local pos = VectorUtil.DeserializeVector2(posKey)
			local count = 0

			for _, d in ipairs(NEIGHBORS_8) do
				local nKey = VectorUtil.SerializeVector2(pos + d)
				if layerData[nKey] ~= nil then
					count += 1
				end
			end

			neighborCount[layerY][posKey] = count -- 0..8
		end
	end
end

local function calcProxScores()

	local MAX_DIST = 16
	local FALLOFF = 0.35
	local SCORE_SCALE = 3

	-- Reset all scores
	for _, layerScores in pairs(scoreGrid) do
		for _, tileScore: TileScore in pairs(layerScores) do
			tileScore.ProxScore = 0
		end
	end

	-- sourcesByLayerY[layerY] = { Vector2, Vector2, ... }
	local sourcesByLayerY: {[number]: {Vector2}} = {}

	for _, eachPlayer in PlayersInGame.getActivePlayers() do
		local records = TouchedBlockTracker.getLastTouchedBlocks(eachPlayer)
		if not records or #records == 0 then
			continue
		end

		local first = records[1]
		local currentBlock = LoadedBlocks[first.blockId]
		if not currentBlock then
			continue
		end

		local loadedLayer = LoadedLayers[currentBlock._LayerId]
		if not loadedLayer then
			continue
		end

		-- *** KEY CHANGE ***
		-- Use the layer's Y-position key (the same key as combinedLayer/scoreGrid).
		-- Prefer a real property if you have it:
		--   local layerY = loadedLayer.originposition.Y
		-- Fallback: if your LoadedLayer has Yposition or similar, use that.
		local layerY = loadedLayer.originPosition.Y

		local pos = snapTile(currentBlock.LayerPosition)

		sourcesByLayerY[layerY] = sourcesByLayerY[layerY] or {}
		table.insert(sourcesByLayerY[layerY], pos)

	end

	for layerY, sources in pairs(sourcesByLayerY) do
		if not combinedLayer[layerY] or not scoreGrid[layerY] then
			warn("[TileScoring] No combinedLayer/scoreGrid for layerY " .. tostring(layerY))
			continue
		end

		local queue = table.create(128)
		local head, tail = 1, 0
		local visited: {[string]: number} = {}

		-- Seed queue
		for _, srcPos in ipairs(sources) do
			local key = VectorUtil.SerializeVector2(srcPos)

			if combinedLayer[layerY][key] ~= nil and visited[key] == nil then
				visited[key] = 0
				tail += 1
				queue[tail] = { pos = srcPos, dist = 0 }
			else
				-- Useful debug for key mismatch
				-- print(("[TileScoring] seed miss layerY=%s key=%s exists=%s"):format(layerY, key, tostring(combinedLayer[layerY][key] ~= nil)))
			end
		end

		if tail == 0 then
			warn("[TileScoring] No seeds found for layerY " .. tostring(layerY) .. " (likely key mismatch)")
			continue
		end

		-- BFS
		while head <= tail do
			local node = queue[head]
			head += 1

			local pos: Vector2 = node.pos
			local dist: number = node.dist

			local proxScore = SCORE_SCALE * (1 / (1 + (FALLOFF * dist)))

			local posKey = VectorUtil.SerializeVector2(pos)
			local tile: TileScore? = scoreGrid[layerY][posKey]
			if tile and proxScore > tile.ProxScore then
				tile.ProxScore = proxScore
			end

			if dist >= MAX_DIST then
				continue
			end

			for _, delta in ipairs(NEIGHBORS) do
				local nPos = pos + delta
				local nKey = VectorUtil.SerializeVector2(nPos)

				if combinedLayer[layerY][nKey] ~= nil and visited[nKey] == nil then
					visited[nKey] = dist + 1
					tail += 1
					queue[tail] = { pos = nPos, dist = dist + 1 }
				end
			end
		end
	end
end

local function calcNeighborScores()
	-- Tunables
	local W_NEIGHBORS = 1.0          -- overall weight applied to neighbor score
	local EDGE_PENALTY = 0.35        -- penalty applied when neighbor count is very low
	local EDGE_THRESHOLD = 1         -- <= this count is considered "edge/trap"

	for layerY, layerScores in pairs(scoreGrid) do
		local nTable = neighborCount[layerY]
		if not nTable then
			-- If we somehow have tiles but no neighbor table, just zero them out
			for _, tile: TileScore in pairs(layerScores) do
				tile.NeighborScore = 0
			end
			continue
		end

		for posKey, tile: TileScore in pairs(layerScores) do
			local n = nTable[posKey] or 0      -- 0..8
			local base = n / 8                 -- 0..1

			local penalty = 0
			if n <= EDGE_THRESHOLD then
				penalty = EDGE_PENALTY
			end

			tile.NeighborScore = math.max(0, (base * W_NEIGHBORS) - penalty)
		end
	end
end



function TileScoring.setCurrentMap(cMap)
	currentMap = cMap
	groupedLayers = LayerUtilities.groupLayers(currentMap.layers)

	-- combineLayers must also be keyed by layerY for this to work (sounds like it is)
	combinedLayer = LayerUtilities.combineLayers(currentMap.layers)

	initScoreGrid()
	initNeighborCount()
end

function TileScoring.onBlockDestroyed(layerY: number, blockPosition: Vector2)
	if not combinedLayer[layerY] then
		return
	end

	local pos = Vector2.new(
		math.floor(blockPosition.X + 0.5),
		math.floor(blockPosition.Y + 0.5)
	)
	local key = VectorUtil.SerializeVector2(pos)

	combinedLayer[layerY][key] = nil
	if scoreGrid[layerY] then scoreGrid[layerY][key] = nil end
	if neighborCount[layerY] then neighborCount[layerY][key] = nil end

	-- decrement the 8 surrounding tiles (only if they exist)
	for _, d in ipairs(NEIGHBORS_8) do
		local nKey = VectorUtil.SerializeVector2(pos + d)
		if neighborCount[layerY] and neighborCount[layerY][nKey] ~= nil then
			neighborCount[layerY][nKey] -= 1
		end
	end
end


function TileScoring.calcStep()
	if not currentMap then
		return
	end

	calcNeighborScores()
	calcProxScores()

end

function TileScoring.getScoresAt(layer: number, position: Vector2, radius: number): {[Vector2]: TileScore}
	local results: {[Vector2]: TileScore} = {}

	if not layer or not position or radius == nil then
		warn("[TileScoring.getScoresAt] invalid args")
		return results
	end

	local layerScores = scoreGrid[layer]
	if not layerScores then
		-- still return the full offset grid as nils
		warn("[TileScoring.getScoresAt] no scores for layer " .. tostring(layer))
		for dy = -radius, radius do
			for dx = -radius, radius do
				results[VectorUtil.SerializeVector2(Vector2.new(dx, dy))] = false
			end
		end
		return results
	end

	local center = snapTile(position)


	for dy = -radius, radius do
		for dx = -radius, radius do
			local offset = Vector2.new(dx, dy)
			local tilePos = center + offset
			local key = VectorUtil.SerializeVector2(tilePos)

			-- if tile doesn't exist / destroyed, this will be nil (as requested)
			local value = layerScores[key] 
			if value then
				results[VectorUtil.SerializeVector2(offset)] = table.clone(value)
			else
				results[VectorUtil.SerializeVector2(offset)] = false
			end
		end
	end

	return results
end

local roundActive = false

function TileScoring.start()
	roundActive = true
	task.spawn(function()
		while roundActive do
			TileScoring.calcStep()
			--TileScoreDebug.displayDebug(scoreGrid)
			task.wait(7)
		end
	end)


end

function TileScoring.stop()
	roundActive = false
end


return TileScoring
