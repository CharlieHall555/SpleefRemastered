local HttpService = game:GetService("HttpService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local Block , Map

type Block = Block.Block
type Map = Map.Map

export type LayerConfig = {
	originPosition: Vector3,
	size: Vector2,
	layerIndex: number?,
	spawnsAmmo: boolean?,
}

export type Layer = {
	id: string,
	size: Vector2,
	blocks: { Block },
	tileMap: { [number]: { [number]: Block? } },
	originPosition: Vector3,
	layerIndex: number,
	spawnsAmmo: boolean,
	parentMapId: string?,

	new: (config: LayerConfig) -> Layer,
	get: (id: string) -> Layer?,
	combine: (layer1: Layer, layer2: Layer) -> Layer,
	setParentMap: (self: Layer, map: Map) -> nil,
	getMap: (self: Layer) -> Map?,
	addBlock: (self: Layer, block: Block, position: Vector2) -> nil,
	getBlock: (self: Layer, position: Vector2) -> Block?,
	getNeighbors: (self: Layer, position: Vector2) -> { [string]: Block? },
	isEdge: (self: Layer, position: Vector2) -> boolean,
	IsEmpty: (self: Layer, position: Vector2) -> boolean,
	removeBlock: (self: Layer, block: Block) -> nil,
	getBlocks: (self: Layer) -> {Block},
	getRandomBlock: (self: Layer) -> Block?,
	destroy: (self: Layer) -> nil,
	isEmpty: (self: Layer) -> boolean,
	getSpawnsAmmo: (self: Layer) -> boolean,
	setSpawnsAmmo: (self: Layer, value: boolean) -> nil,
}

local loadedLayers: { [string]: Layer } = {}

local Layer = {}
Layer.__index = Layer

function Layer.get(id : string)
    return loadedLayers[id]
end

-- Constructor
function Layer.new(conig : LayerConfig): Layer

	local self: Layer = setmetatable({}, Layer)
	self.id = HttpService:GenerateGUID(false)
	self.size = conig.size
	self.originPosition = conig.originPosition
	self.blocks = {}
	self.layerIndex = conig.layerIndex or 0
	self.tileMap = {}
	self.spawnsAmmo = conig.spawnsAmmo
    self.parentMapId = nil

	for x = 1, self.size.X do
		self.tileMap[x] = {}
		for y = 1, self.size.Y do
			self.tileMap[x][y] = nil
		end
	end

	loadedLayers[self.id] = self
	return self
end

function Layer.setParentMap(self : Layer , map : Map) : nil
    self.parentMapId = map.id
end

function Layer.getMap(self : Layer) : Map?
    if self.parentMapId then
        return Map.get(self.parentMapId)
    end
    return nil
end

-- Add block
function Layer.addBlock(self: Layer, block: Block, position: Vector2): nil
	table.insert(self.blocks, block)
	self.tileMap[position.X][position.Y] = block
end

-- Get block at grid position
function Layer.getBlock(self: Layer, position: Vector2): Block?
	-- Check if position is within bounds
	if position.X < 1 or position.X > self.size.X or
	   position.Y < 1 or position.Y > self.size.Y then
		return nil
	end
	
	return (self.tileMap[position.X] and self.tileMap[position.X][position.Y]) or nil
end

function Layer.getNeighbors(self: Layer, position: Vector2): { [string]: Block? }
	local neighbors = {}
	
	-- Define 4-directional neighbors (cardinal directions)
	local directions = {
		Vector2.new(0, 1),   -- Up
		Vector2.new(0, -1),  -- Down
		Vector2.new(-1, 0),  -- Left
		Vector2.new(1, 0),   -- Right
	}
	
	for _, direction in ipairs(directions) do
		local neighborPos = position + direction
		local block = self:getBlock(neighborPos)
			if block then
				local key = VectorUtil.serializeVector2(direction)
				neighbors[key] = block
			end
	end
	
	return neighbors
end

function Layer.isEdge(self: Layer , position : Vector2) : boolean
	local neighbors = self:getNeighbors(position)
	local count = 0
	for _ in pairs(neighbors) do
		count += 1
	end
	return count < 4
end

function Layer.IsEmpty(self: Layer , position : Vector2) : boolean
	return self:getBlock(position) == nil
end

-- Remove block
function Layer.removeBlock(self: Layer, block: Block): nil
	local pos = block.layerPosition
	if self.tileMap[pos.X] then
		self.tileMap[pos.X][pos.Y] = nil
	end

	local idx = table.find(self.blocks, block)
	if idx then
		table.remove(self.blocks, idx)
	end
end

function Layer.getBlocks(self : Layer) : {Block}
	return self.blocks
end

-- Random block
function Layer.getRandomBlock(self: Layer): Block?
	if #self.blocks == 0 then
		return nil
	end
	return self.blocks[math.random(1, #self.blocks)]
end

-- Destroy layer
function Layer.destroy(self: Layer): nil

	local parentMap = self:getMap()
	if parentMap then
		parentMap:removeLayer(self)
	end

	loadedLayers[self.id] = nil

	for _, blk in ipairs(self.blocks) do
		blk:destroy()
	end

	self.blocks = {}
	self.tileMap = {}
end

-- Is empty
function Layer.isEmpty(self: Layer): boolean
	return #self.blocks == 0
end

-- Ammo spawn flag
function Layer.setSpawnsAmmo(self: Layer, value: boolean): nil
	self.spawnsAmmo = value
end

function Layer.getSpawnsAmmo(self: Layer): boolean
	return self.spawnsAmmo
end

-- Init dependencies
function Layer.init(): nil
	Block = require(ModuleDirectory.Systems.Map.Block)
    Map = require(ModuleDirectory.Systems.Map.Map)
end

return Layer
