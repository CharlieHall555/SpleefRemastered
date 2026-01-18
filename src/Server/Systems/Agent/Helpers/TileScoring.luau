--!strict

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local TileScoring = {}

-- Dependencies (loaded in init)
local VectorUtil
local Layer
local Map
local Block
local PlayersInGame
local TouchedBlockTracker
local AgentsInGame
local TileScoreDebug

local NEIGHBORS = {
	Vector2.new(1, 0),
	Vector2.new(-1, 0),
	Vector2.new(0, 1),
	Vector2.new(0, -1),
}

local DEBUG_MODE = true
local TILE_SCORING_INTERVAL = 10
local MAX_HEAT_DEPTH = 5

-- Internal data (still required for public API to function)
local currentMap: Map.Map? = nil
local roundActive = false
local scoringTask: thread? = nil
local startToken = 0 -- increments

-- [layerIndex][xPos][yPos] = score
local proxScores: { [number]: { [number]: { [number]: number } } } = {}
local connectedScores: { [number]: { [number]: { [number]: number } } } = {}

-- =========================
-- Public API
-- =========================

function TileScoring.init()
	VectorUtil = require(ModuleDirectory.VectorUtil)

	PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
	TouchedBlockTracker = require(ModuleDirectory.Systems.Stats.TouchedBlockTracker)

	Layer = require(ModuleDirectory.Systems.Map.Layer)
	Map = require(ModuleDirectory.Systems.Map.Map)
	Block = require(ModuleDirectory.Systems.Map.Block)
	AgentsInGame = require(ModuleDirectory.Systems.Round.AgentsInGame)
	TileScoreDebug = require(ModuleDirectory.DebugTools.TileScoreDebug)
end

type sourceRecord = {
	blockId: string,
	layerPosition: Vector2,
	layerIndex: number,
}


local function tryGetBlockAtLayerPos(layer: any, x: number, y: number): any?
	-- method-style
	if typeof(layer) == "table" then
		local fn =
			layer.getBlockAtLayerPos
			or layer.getBlockAtLayerPosition
			or layer.getBlockAt
			or layer.getBlock
			or layer.at

		if type(fn) == "function" then
			local ok, res = pcall(function()
				-- some APIs take Vector2, others x,y
				local ok2, r2 = pcall(function() return fn(layer, Vector2.new(x, y)) end)
				if ok2 and r2 ~= nil then return r2 end
				return fn(layer, x, y)
			end)
			if ok and res ~= nil then
				return res
			end
		end
	end

	return nil
end

-- Builds a quick lookup so we only BFS onto real tiles in that layer.
local function buildTileExistence(layer: any): { [number]: { [number]: boolean } }
	local exists: { [number]: { [number]: boolean } } = {}

	-- Common pattern: layer:getBlocks() -> array of blocks with .layerPosition
	if typeof(layer) == "table" and type(layer.getBlocks) == "function" then
		local ok, blocks = pcall(function() return layer:getBlocks() end)
		if ok and type(blocks) == "table" then
			for _, b in blocks do
				local pos = b and (b.layerPosition or b.LayerPosition)
				if typeof(pos) == "Vector2" then
					local x, y = pos.X, pos.Y
					exists[x] = exists[x] or {}
					exists[x][y] = true
				end
			end
			return exists
		end
	end

	-- Fallback (slower): no blocks list available -> we can’t precompute existence reliably,
	-- so return empty and rely on tryGetBlockAtLayerPos checks during BFS.
	return exists
end

local function setProx(layerIndex: number, x: number, y: number, value: number)
	x = math.floor(x + 0.5)
	y = math.floor(y + 0.5)
	proxScores[layerIndex] = proxScores[layerIndex] or {}
	proxScores[layerIndex][x] = proxScores[layerIndex][x] or {}
	proxScores[layerIndex][x][y] = value
end

local function calcProxScores()
	-- reset
	proxScores = {}

	-- if you rely on a current map reference, guard it here
	-- (you can remove this if Map:getLayers() is always valid)
	if currentMap == nil and Map.getCurrentMap ~= nil then
		local ok, m = pcall(function() return Map:getCurrentMap() end)
		if ok then
			currentMap = m
		end
	end

	local sourcePositions: { sourceRecord } = {}

	-- Collect agent sources
	for _, eachAgent in AgentsInGame.getActiveAgents() do
		local ok, rec = pcall(function()
			return (TouchedBlockTracker.getLastTouchedBlocks(eachAgent) or {})[1]
		end)

		if ok and rec then
			local sourceBlock = Block.get(rec.blockId or "")
			if sourceBlock then
				local parentLayer = sourceBlock:getParentLayer()
				local layerIndex = parentLayer and parentLayer.layerIndex
				if type(layerIndex) == "number" and typeof(sourceBlock.layerPosition) == "Vector2" then
					table.insert(sourcePositions, {
						blockId = rec.blockId,
						layerPosition = sourceBlock.layerPosition,
						layerIndex = layerIndex,
					})
				end
			end
		end
	end

	-- Collect player sources
	for _, eachPlayer in PlayersInGame.getActivePlayers() do
		local ok, rec = pcall(function()
			return (TouchedBlockTracker.getLastTouchedBlocks(eachPlayer) or {})[1]
		end)

		if ok and rec then
			local sourceBlock = Block.get(rec.blockId or "")
			if sourceBlock then
				local parentLayer = sourceBlock:getParentLayer()
				local layerIndex = parentLayer and parentLayer.layerIndex
				if type(layerIndex) == "number" and typeof(sourceBlock.layerPosition) == "Vector2" then
					table.insert(sourcePositions, {
						blockId = rec.blockId,
						layerPosition = sourceBlock.layerPosition,
						layerIndex = layerIndex,
					})
				end
			end
		end
	end

	-- Group sources by layer for faster BFS setup
	local sourcesByLayer: { [number]: { sourceRecord } } = {}
	for _, s in sourcePositions do
		sourcesByLayer[s.layerIndex] = sourcesByLayer[s.layerIndex] or {}
		table.insert(sourcesByLayer[s.layerIndex], s)
	end

	-- Iterate layers and BFS per layer
	-- If your API is Map:getLayers() on the module, keep it as-is.
	-- If it’s currentMap:getLayers(), swap it.
	for layerIndex, eachLayer in currentMap:getLayers() do
		local layerSources = sourcesByLayer[layerIndex]
		if not layerSources or #layerSources == 0 then
			continue
		end

		-- Optional existence map (fast path if layer exposes getBlocks)
		local exists = buildTileExistence(eachLayer)

		-- visited min-distance map: visited[x][y] = dist
		local visited: { [number]: { [number]: number } } = {}
		local queue = table.create(64)
		local qHead = 1

		local function tileExists(x: number, y: number): boolean
			if exists[x] and exists[x][y] then
				return true
			end
			-- fallback: probe layer API
			local b = tryGetBlockAtLayerPos(eachLayer, x, y)
			return b ~= nil
		end

		local function getVisited(x: number, y: number): number?
			return visited[x] and visited[x][y] or nil
		end

		local function setVisited(x: number, y: number, d: number)
			visited[x] = visited[x] or {}
			visited[x][y] = d
		end

		-- seed queue (multi-source)
		for _, s in layerSources do
			local x = math.floor(s.layerPosition.X + 0.5)
			local y = math.floor(s.layerPosition.Y + 0.5)
			
			if tileExists(x, y) then
				local prev = getVisited(x, y)
				if prev == nil or 0 < prev then
					setVisited(x, y, 0)
					queue[#queue + 1] = { x = x, y = y, d = 0 }
				end
			end
		end

		-- BFS
		while qHead <= #queue do
			local node = queue[qHead]
			qHead += 1

			local x, y, d = node.x, node.y, node.d
			if d > MAX_HEAT_DEPTH then
				continue
			end

			-- 1 at source, down to 0 at MAX_HEAT_DEPTH
			local score = 1 - (d / MAX_HEAT_DEPTH)
			setProx(layerIndex, x, y, score)

			-- expand
			local nd = d + 1
			if nd <= MAX_HEAT_DEPTH then
				for _, off in NEIGHBORS do
					local nx = math.floor(x + off.X + 0.5)
					local ny = math.floor(y + off.Y + 0.5)

					if tileExists(nx, ny) then
						local prev = getVisited(nx, ny)
						if prev == nil or nd < prev then
							setVisited(nx, ny, nd)
							queue[#queue + 1] = { x = nx, y = ny, d = nd }
						end
					end
				end
			end
		end
	end
end

local function calcDangerScore()
	if not currentMap then
		return
	end

	connectedScores = {}

	for layerIndex, eachLayer in currentMap:getLayers() do
		connectedScores[layerIndex] = connectedScores[layerIndex] or {}

		local exists: { [number]: { [number]: boolean } } = {}
		local dist: { [number]: { [number]: number } } = {}

		local queueX = table.create(512)
		local queueY = table.create(512)
		local head, tail = 1, 0

		local blockAt: { [number]: { [number]: any } } = {} -- [x][y] = block

		for _, block in eachLayer:getBlocks() do
			if block:isActive() then
				local p = block.layerPosition
				local x = math.floor(p.X + 0.5)
				local y = math.floor(p.Y + 0.5)

				exists[x] = exists[x] or {}
				exists[x][y] = true

				blockAt[x] = blockAt[x] or {}
				blockAt[x][y] = block


				-- Seed: edge tiles start at dist 0
				if eachLayer:isEdge(p) then
					dist[x] = dist[x] or {}
					dist[x][y] = 0
					tail += 1
					queueX[tail] = x
					queueY[tail] = y
				end
			end
		end

		if tail == 0 then
			for x, col in pairs(exists) do
				connectedScores[layerIndex][x] = connectedScores[layerIndex][x] or {}
				for y, _ in pairs(col) do
					connectedScores[layerIndex][x][y] = 0
				end
			end
			continue
		end

		while head <= tail do
			local x = queueX[head]
			local y = queueY[head]
			head += 1

			local dHere = (dist[x] and dist[x][y]) or 0
			if dHere < MAX_HEAT_DEPTH then
				for _, dir in ipairs(NEIGHBORS) do
					local nx = math.floor(x + dir.X + 0.5)
					local ny = math.floor(y + dir.Y + 0.5)

					if exists[nx] and exists[nx][ny] then
						-- not visited?
						if not (dist[nx] and dist[nx][ny] ~= nil) then
							dist[nx] = dist[nx] or {}
							dist[nx][ny] = dHere + 1

							tail += 1
							queueX[tail] = nx
							queueY[tail] = ny
						end
					end
				end
			end
		end

		for x, col in pairs(exists) do
			connectedScores[layerIndex][x] = connectedScores[layerIndex][x] or {}
			for y, _ in pairs(col) do
				local d = (dist[x] and dist[x][y]) or 0
				connectedScores[layerIndex][x][y] = math.clamp(d / MAX_HEAT_DEPTH, 0, 1)
			end
		end
	end
end

local function calcStep()
	if not currentMap then
		return
	end

	calcDangerScore()
	calcProxScores()
end

function TileScoring.setCurrentMap(cMap)
	currentMap = cMap
end

function TileScoring.onBlockDestroyed(layerY: number, blockPosition: Vector2) end

function TileScoring.start()
	-- If already running, do nothing (prevents multiple loops)
	if roundActive and scoringTask ~= nil then
		return
	end

	roundActive = true
	startToken += 1
	local myToken = startToken

	scoringTask = task.spawn(function()
		while roundActive and myToken == startToken do
			local ok, err = pcall(calcStep)
			if not ok then
				warn("[TileScoring] calcStep failed:", err)
			end
			task.wait(TILE_SCORING_INTERVAL)
		end

		-- Only clear if we're still the latest task
		if myToken == startToken then
			scoringTask = nil
		end
	end)
end

function TileScoring.stop()
	roundActive = false
	startToken += 1
	scoringTask = nil
end

export type LocalTileScore = {
	-- relative coords from the center (so "0,0" is always the center)
	offset: Vector2,

	-- absolute layer coords in the layer grid
	layerPos: Vector2,

	prox: number,
	connected: number,
}

export type RadiusScoresResult = {
	center: Vector2,
	layerIndex: number,
	radius: number,

	-- key = VectorUtil.serializeVector2(offset)
	-- offset (0,0) == center tile scores
	tiles: { [string]: LocalTileScore },
}

local function getScoreFromGrid(
	grid: { [number]: { [number]: { [number]: number } } },
	layerIndex: number,
	x: number,
	y: number
): number
	x = math.floor(x + 0.5)
	y = math.floor(y + 0.5)
	local byLayer = grid[layerIndex]
	if not byLayer then return 0 end
	local byX = byLayer[x]
	if not byX then return 0 end
	local v = byX[y]
	return if type(v) == "number" then v else 0
end

local function setTileResult(
	out: { [string]: LocalTileScore },
	center: Vector2,
	layerIndex: number,
	dx: number,
	dy: number
)
	local offset = Vector2.new(dx, dy)
	local absX = math.floor(center.X + dx + 0.5)
	local absY = math.floor(center.Y + dy + 0.5)
	local abs = Vector2.new(absX, absY)
	local key = VectorUtil.serializeVector2(offset)

	out[key] = {
		offset = offset,
		layerPos = abs,
		prox = getScoreFromGrid(proxScores, layerIndex, abs.X, abs.Y),
		connected = getScoreFromGrid(connectedScores, layerIndex, abs.X, abs.Y),
	}
end

function TileScoring.getScoresAround(
	layerIndex: number,
	layerPos: Vector2,
	radius: number,
	includeMissing: boolean?,
	useManhattan: boolean?
): RadiusScoresResult
	if radius < 0 then
		radius = 0
	end

	local tiles: { [string]: LocalTileScore } = {}

	-- optional existence filtering (only if we can locate the layer)
	local layerObj = nil
	if currentMap then
		-- try currentMap:getLayers() iteration to find matching layerIndex
		local ok = pcall(function()
			for idx, l in currentMap:getLayers() do
				if idx == layerIndex then
					layerObj = l
					break
				end
			end
		end)
	end

	local existsLookup: { [number]: { [number]: boolean } } = {}
	if layerObj ~= nil then
		existsLookup = buildTileExistence(layerObj)
	end

	local function tileExistsAbs(x: number, y: number): boolean
		if layerObj == nil then
			return true -- can't check, so allow
		end
		if existsLookup[x] and existsLookup[x][y] then
			return true
		end
		-- fallback probe
		return tryGetBlockAtLayerPos(layerObj, x, y) ~= nil
	end

	local allowMissing = includeMissing == true

	-- ensure center always included
	do
		local absX = math.floor(layerPos.X + 0.5)
		local absY = math.floor(layerPos.Y + 0.5)
		if allowMissing or tileExistsAbs(absX, absY) then
			setTileResult(tiles, layerPos, layerIndex, 0, 0)
		else
			-- still include center, but scores will be 0 if missing
			setTileResult(tiles, layerPos, layerIndex, 0, 0)
		end
	end

	local r2 = radius * radius

	for dx = -radius, radius do
		for dy = -radius, radius do
			-- skip center (already done)
			if not (dx == 0 and dy == 0) then
				local inRange
				if useManhattan then
					inRange = (math.abs(dx) + math.abs(dy)) <= radius
				else
					inRange = (dx * dx + dy * dy) <= r2
				end

				if inRange then
					local absX = math.floor(layerPos.X + dx + 0.5)
					local absY = math.floor(layerPos.Y + dy + 0.5)
					if allowMissing or tileExistsAbs(absX, absY) then
						setTileResult(tiles, layerPos, layerIndex, dx, dy)
					end
				end
			end
		end
	end

	return {
		center = layerPos,
		layerIndex = layerIndex,
		radius = radius,
		tiles = tiles,
	}
end

return TileScoring
