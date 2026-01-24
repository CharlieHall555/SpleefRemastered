local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RunService = game:GetService("RunService")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Configurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local Players = game:GetService("Players")

local Map = require(ModuleDirectory.Systems.Map.Map)
local Layer = require(ModuleDirectory.Systems.Map.Layer)

local Collectable = require(ModuleDirectory.Systems.Collectable.Collectable)
local CollectablePickupLogic = require(ModuleDirectory.Systems.Collectable.CollectablePickupLogic)

local CollectableManager = {}

local currentMap: Map.Map? = nil
local active = false

--[[
	Configurations keys expected:
	MAX_COLLECTABLES
	COLLECTABLE_SPAWN_INTERVAL
	MIN_COLLECTABLE_PER_FLOOR
	COLLECTABLE_LIFE_SPAN
	COLLECTABLE_OFFSET_HEIGHT
	COLLECTION_THRESHOLD_DISTANCE
	COLLECTABLE_TYPES
]]

-- layerId -> count
local collectablesOnLayer: { [string]: number } = {}

-- timing
local nextSpawnAt: number = 0

local function clamp0(n: number): number
	return (n < 0) and 0 or n
end

local function getTotalCollectables(): number
	local total = 0
	for _, c in pairs(collectablesOnLayer) do
		total += c
	end
	return total
end

local function randomPickupType(): string
	local types = Configurations.COLLECTABLE_TYPES
	return types[math.random(1, #types)]
end

local function randomSpot(layer: Layer.Layer): Vector3?
	if not layer then
		return nil
	end

	local block = layer:getRandomBlock()
	if not block then
		return nil
	end

	return block:getWorldPosition() + Vector3.new(0, Configurations.COLLECTABLE_OFFSET_HEIGHT, 0)
end

local function requestCollectablePickup(player: Player, pickupId: string)
	local collectable = Collectable.get(pickupId)
	if not collectable then
		warn("Collectable not found (maybe already picked up/destroyed):", pickupId)
		return
	end

	if not player.Character or not player.Character.PrimaryPart then
		return
	end

	local playerPos = player.Character.PrimaryPart.Position
	local pickupPos = collectable.worldPosition

	if (playerPos - pickupPos).Magnitude > Configurations.COLLECTION_THRESHOLD_DISTANCE then
		return
	end

	CollectablePickupLogic.processPickup(player, collectable.collectableType)
	collectable:destroy()
end

--====================================================
-- Spawning / lifecycle
--====================================================

local function collectableDestroyed(collectable: Collectable.Collectable)
	-- Collectable:destroy() calls this function
	local layerId = collectable.layerId
	if not layerId then
		return
	end

	if collectablesOnLayer[layerId] ~= nil then
		collectablesOnLayer[layerId] = clamp0((collectablesOnLayer[layerId] :: number) - 1)
	end

	RemoteEventHandler.FireOnAllClients("COLLECTABLE_DESTROYED", collectable.id)
end

local function pickLayerNeedingTopUp(): Layer.Layer?
	if not currentMap then
		return nil
	end

	-- priority 1: any layer under MIN_COLLECTABLE_PER_FLOOR
	local minPer = tonumber(Configurations.MIN_COLLECTABLE_PER_FLOOR) or 0
	for _, layer in currentMap:getLayers() do
		if layer:getSpawnsCollectables() then
			local count = collectablesOnLayer[layer.id]
			if count ~= nil and count < minPer then
				return layer
			end
		end
	end

	-- priority 2: random eligible layer
	local eligible: { Layer.Layer } = {}
	for _, layer in currentMap:getLayers() do
		if layer:getSpawnsCollectables() then
			if collectablesOnLayer[layer.id] ~= nil then
				table.insert(eligible, layer)
			end
		end
	end

	if #eligible == 0 then
		return nil
	end

	return eligible[math.random(1, #eligible)]
end

function CollectableManager.newCollectable(
	position: Vector3,
	collectableType: string,
	layerId: string
): Collectable.Collectable?
	if not currentMap then
		return nil
	end
	if not position or not layerId or collectablesOnLayer[layerId] == nil then
		return nil
	end

	-- global cap
	local maxAll = tonumber(Configurations.MAX_COLLECTABLES) or 0
	if maxAll > 0 and getTotalCollectables() >= maxAll then
		return nil
	end

	local lifeSpan = tonumber(Configurations.COLLECTABLE_LIFE_SPAN) or 10

	local collectable = Collectable.new(position, layerId, collectableType)

	if not collectable then
		warn("Failed to create collectable")
		return nil
	end

	-- increment counts
	collectablesOnLayer[layerId] = (collectablesOnLayer[layerId] :: number) + 1

	-- auto-expire (don’t double-destroy if already gone)
	if lifeSpan > 0 then
		task.delay(lifeSpan, function()
			local stillThere = Collectable.get(collectable.id)
			if stillThere then
				stillThere:destroy()
			end
		end)
	end

	-- Tell clients (include payload so they can spawn visuals deterministically)
	RemoteEventHandler.FireOnAllClients(
		"NEW_COLLECTABLE",
		collectable.id,
		collectable.collectableType,
		collectable.worldPosition,
		lifeSpan
	)

	return collectable
end

local function collectableLoop()
	if not active or not currentMap then
		return
	end

	local interval = tonumber(Configurations.COLLECTABLE_SPAWN_INTERVAL) or 1
	if interval <= 0 then
		interval = 1
	end

	local t = tick()
	if t < nextSpawnAt then
		return
	end
	nextSpawnAt = t + interval

	-- global cap
	local maxAll = tonumber(Configurations.MAX_COLLECTABLES) or 0
	if maxAll > 0 and getTotalCollectables() >= maxAll then
		return
	end

	local layer = pickLayerNeedingTopUp()
	if not layer then
		return
	end

	local pos = randomSpot(layer)
	if not pos then
		return
	end

	local cType = randomPickupType()
	CollectableManager.newCollectable(pos, cType, layer.id)
end

--====================================================
-- Public API
--====================================================

function CollectableManager.start()
	if not currentMap then
		warn("Missing map")
		return
	end

	active = true
	nextSpawnAt = tick() -- spawn ASAP, then interval

	task.spawn(function()
		-- light loop; do not spam spawns because collectableLoop gates by _nextSpawnAt
		while active do
			collectableLoop()
			task.wait(0.1)
		end
	end)
end

function CollectableManager.reset()
	active = false
	collectablesOnLayer = {}
	currentMap = nil
end

function CollectableManager.setMap(map: Map.Map)
	currentMap = map
	collectablesOnLayer = {}

	for _, eachLayer in map:getLayers() do
		if eachLayer:getSpawnsCollectables() then
			collectablesOnLayer[eachLayer.id] = 0
		end
	end
end

function CollectableManager.init()
	Collectable.setOnDestroyed(collectableDestroyed)
	RemoteEventHandler.newEventConnection("REQUEST_PICKUP", requestCollectablePickup)
end

return CollectableManager
