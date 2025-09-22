-- tutorialMapGenerator.lua
-- Creates and tracks a per-player tutorial map instance.

local Players = game:GetService("Players")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local Map = require(ModuleDirectory.Map.Map)

local TutorialMapTemplate = require(game:GetService("ServerScriptService").Systems.Map.MapSaves.TutorialMap)

local tutorialMapGenerator = {}

-- Track maps per user and a slot index for spatial separation.
local _mapsByUser: { [number]: Map.Map } = {}
local _slotByUser: { [number]: number } = {}
local _usedSlots: { [number]: boolean } = {}

-- Grid spacing so maps don't overlap; tweak as needed.
local CELL_X = 1500
local CELL_Z = 1500
local BASE_Y = 4000

-- optional: distribute on a simple grid to keep worlds nicely spaced
local function slotToOrigin(slot: number): Vector3
	-- 0-index internally for nicer grid math
	local n = math.max(0, slot - 1)
	local cols = 10 -- change to pack denser/wider
	local row = math.floor(n / cols)
	local col = n % cols
	return Vector3.new(col * CELL_X, BASE_Y, row * CELL_Z)
end

local function deepCopy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local copy = {}
	for k, v in pairs(tbl) do
		copy[deepCopy(k)] = deepCopy(v)
	end
	return copy
end

local function getMapOrigin(map: Map.Map): Vector3
	-- Be tolerant of naming differences
	return (map.OriginPosition or map.originPosition or map.Origin or Vector3.new())
end

function tutorialMapGenerator.getMap(player: Player): Map.Map?
	return _mapsByUser[player.UserId]
end

function tutorialMapGenerator.getMapOrigin(player: Player): Vector3?
	local map = _mapsByUser[player.UserId]
	return map and getMapOrigin(map) or nil
end

function tutorialMapGenerator.ensureMap(player: Player): Map.Map
	local uid = player.UserId
	if _mapsByUser[uid] then
		return _mapsByUser[uid]
	end

	-- Find the smallest available slot
	local slot = 1
	while _usedSlots[slot] do
		slot += 1
	end
	_slotByUser[uid] = slot
	_usedSlots[slot] = true

	-- clone template without mutating the shared module table
	local tpl = deepCopy(TutorialMapTemplate)
	local origin = slotToOrigin(slot)
	-- normalise the expected field name the generator uses (handle a few common names)
	if tpl.originPosition ~= nil then
		tpl.originPosition = origin
	elseif tpl.OriginPosition ~= nil then
		tpl.OriginPosition = origin
	else
		-- fall back to a standard key MapGenerator understands in your codebase
		tpl.OriginPosition = origin
	end

	local newMap: Map.Map = MapGenerator.generate(tpl)
	print(newMap.background)
	_mapsByUser[uid] = newMap
	return newMap
end

function tutorialMapGenerator.deleteMap(player: Player)
	local uid = player.UserId
	local map = _mapsByUser[uid]
	if map then
		-- Your Map class likely has :Destroy(); if not, clean descendants/instances here.
		pcall(function()
			if map.Destroy then map:Destroy() end
		end)
	end
	_mapsByUser[uid] = nil
	local slot = _slotByUser[uid]
	if slot then
		_usedSlots[slot] = nil
	end
	_slotByUser[uid] = nil
end

return tutorialMapGenerator