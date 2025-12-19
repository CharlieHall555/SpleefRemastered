-- tutorialMapGenerator.lua
-- Creates and tracks a per-player tutorial map instance.

local Players = game:GetService("Players")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local Map = require(ModuleDirectory.Map.Map)

local TutorialMapTemplate = require(game:GetService("ServerScriptService").Systems.Map.MapSaves.TutorialMap)

local tutorialMapGenerator = {}

-- Track maps per user and a slot index for spatial separation.
local mapsByUser: { [number]: Map.Map } = {}
local slotByUser: { [number]: number } = {}
local usedSlots: { [number]: boolean } = {}

-- Grid spacing so maps don't overlap; tweak as needed.
local CELL_X = 1500
local CELL_Z = 1500
local BASE_Y = 4000

local function slotToOrigin(slot: number): Vector3
	-- 0-index internally for nicer grid math
	local n = math.max(0, slot - 1)
	local cols = 10 
	local row = math.floor(n / cols)
	local col = n % cols
	return Vector3.new(col * CELL_X, BASE_Y, row * CELL_Z)
end

local function getMapOrigin(map: Map.Map): Vector3
	-- Be tolerant of naming differences
	return (map.originPosition or map.originPosition or map.Origin or Vector3.new())
end

function tutorialMapGenerator.getMap(player: Player): Map.Map?
	return mapsByUser[player.UserId]
end

function tutorialMapGenerator.getMapOrigin(player: Player): Vector3?
	local map = mapsByUser[player.UserId]
	return map and getMapOrigin(map) or nil
end

function tutorialMapGenerator.generateMap(player: Player): Map.Map
	local uid = player.UserId
	if mapsByUser[uid] then
		return mapsByUser[uid]
	end

	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	slotByUser[uid] = slot
	usedSlots[slot] = true

	local tpl = table.clone(TutorialMapTemplate)
	local origin = slotToOrigin(slot)
	tpl.originPosition = origin

	local newMap: Map.Map = MapGenerator.generate(tpl)
	mapsByUser[uid] = newMap
	return newMap
end

function tutorialMapGenerator.deleteMap(player: Player)
	local uid = player.UserId
	local map = mapsByUser[uid]
	if map then
		map:Destroy()
	end
	mapsByUser[uid] = nil
	local slot = slotByUser[uid]
	if slot then
		usedSlots[slot] = nil
	end
	slotByUser[uid] = nil
end

return tutorialMapGenerator