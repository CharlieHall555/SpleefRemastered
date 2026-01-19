local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Systems.Map.Block)
local Layer = require(ModuleDirectory.Systems.Map.Layer)

local loadedPaths = {}

local Pathfinding = {}

export type path = {
	pathId: string, -- use httpservice
	waypoints: { [number]: Block.Block },
}

local HttpService = game:GetService("HttpService")

local loadedPaths: { [string]: path } = {}

local Pathfinding = {}

local function keyFromPos(pos: Vector2): string
	return tostring(pos.X) .. "," .. tostring(pos.Y)
end

local function heuristic(a: Vector2, b: Vector2): number
	-- Manhattan (good for 4-way)
	return math.abs(a.X - b.X) + math.abs(a.Y - b.Y)
end

local function getNeighbors(layer: Layer.Layer, pos: Vector2): { Vector2 }
	-- 4-way neighbors. Add diagonals if you want.
	return {
		Vector2.new(pos.X + 1, pos.Y),
		Vector2.new(pos.X - 1, pos.Y),
		Vector2.new(pos.X, pos.Y + 1),
		Vector2.new(pos.X, pos.Y - 1),
	}
end

local function reconstruct(cameFrom: { [string]: Vector2 }, currentPos: Vector2): { Vector2 }
	local out = { currentPos }
	while true do
		local k = keyFromPos(currentPos)
		local prev = cameFrom[k]
		if not prev then
			break
		end
		currentPos = prev
		table.insert(out, 1, currentPos)
	end
	return out
end

local function aStar(layer: Layer.Layer, startPos: Vector2, goalPos: Vector2): { Block.Block }
	local openSet: { [string]: boolean } = {}
	local openList: { Vector2 } = {}

	local cameFrom: { [string]: Vector2 } = {}

	local gScore: { [string]: number } = {}
	local fScore: { [string]: number } = {}

	local startKey = keyFromPos(startPos)
	openSet[startKey] = true
	table.insert(openList, startPos)

	gScore[startKey] = 0
	fScore[startKey] = heuristic(startPos, goalPos)

	local function popLowestF(): Vector2?
		local bestIndex = nil
		local bestF = math.huge

		for i, pos in ipairs(openList) do
			local k = keyFromPos(pos)
			local f = fScore[k] or math.huge
			if f < bestF then
				bestF = f
				bestIndex = i
			end
		end

		if not bestIndex then
			return nil
		end

		local pos = openList[bestIndex]
		table.remove(openList, bestIndex)
		openSet[keyFromPos(pos)] = nil
		return pos
	end

	while true do
		local currentPos = popLowestF()
		if not currentPos then
			return {} -- no path
		end

		if currentPos == goalPos then
			local positions = reconstruct(cameFrom, currentPos)
			local blocks: { Block.Block } = {}
			for _, p in ipairs(positions) do
				local b = layer:getBlock(p)
				if not b then
					-- If layer changed mid-search, bail safely
					return {}
				end
				table.insert(blocks, b)
			end
			return blocks
		end

		local currentKey = keyFromPos(currentPos)
		local currentG = gScore[currentKey] or math.huge

		for _, nPos in ipairs(getNeighbors(layer, currentPos)) do
			local nBlock = layer:getBlock(nPos)
			if nBlock then
				local nKey = keyFromPos(nPos)
				local tentativeG = currentG + 1

				if tentativeG < (gScore[nKey] or math.huge) then
					cameFrom[nKey] = currentPos
					gScore[nKey] = tentativeG
					fScore[nKey] = tentativeG + heuristic(nPos, goalPos)

					if not openSet[nKey] then
						openSet[nKey] = true
						table.insert(openList, nPos)
					end
				end
			end
		end
	end
end

function Pathfinding.findPath(layer: Layer.Layer, startPos: Vector2, toPos: Vector2): path?
	
	local startBlock = layer:getBlock(startPos)
	local goalBlock = layer:getBlock(toPos)
	
	if not startBlock then
		warn("[Pathfinding.findPath] No start block at position:", startPos)
		return nil
	end
	
	if not goalBlock then
		warn("[Pathfinding.findPath] No goal block at position:", toPos)
		return nil
	end

	
	-- compute
	local result = aStar(layer, startPos, toPos)
	if #result == 0 then
		return nil
	end

	
	local newPath: path = {
		pathId = HttpService:GenerateGUID(false),
		waypoints = {},
	}

	newPath.waypoints = result
	loadedPaths[newPath.pathId] = newPath
	return newPath
end

function Pathfinding.discardPath(id: string)
	loadedPaths[id] = nil
end

return Pathfinding
