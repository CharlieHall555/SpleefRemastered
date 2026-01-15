local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Systems.Map.Block)
local LoadedLayers = require(ModuleDirectory.Systems.Map.LoadedLayers)

export type Layer = {
    _id: number,
    size: Vector2,
    blocks: { Block.Block },
    tileMap: { [number]: { [number]: Block.Block? } },
    originPosition: Vector3,

    new: (originPosition: Vector3, size: Vector2) -> Layer,
    addBlock: (self: Layer, block: Block.Block, position: Vector2) -> nil,
    getBlock: (self: Layer, position: Vector2) -> Block.Block?,
    removeBlock: (self: Layer, block: Block.Block) -> nil,
    getRandomBlock: (self: Layer) -> Block.Block?,
    destroy: (self: Layer) -> nil,
    isEmpty: (self: Layer) -> boolean,
    getSpawnsAmmo : (self : Layer) -> boolean,
    setpawnsAmmo : (self : Layer , value : boolean) -> nil,

}

local nextLayerId = 0
local Layer = {}
Layer.__index = Layer

function Layer.new(originPosition: Vector3, size: Vector2 , layerIndex : number?): Layer
    nextLayerId += 1

    local self = setmetatable({}, Layer)
    self._id = nextLayerId
    self.size = size
    self.originPosition = originPosition
    self.blocks = {}
    self.LayerIndex = layerIndex or 0
    self.tileMap = {}
    self.spawnsAmmo = false

    for x = 1, size.X do
        self.tileMap[x] = {}
        for y = 1, size.Y do
            self.tileMap[x][y] = nil
        end
    end

    LoadedLayers[self._id] = self
    return self
end

function Layer:addBlock(block: Block.Block, position: Vector2): nil
    table.insert(self.blocks, block)
    self.tileMap[position.X][position.Y] = block
end

function Layer:getBlock(position: Vector2): Block.Block?
    return (self.tileMap[position.X] and self.tileMap[position.X][position.Y]) or nil
end

function Layer:setSpawnsAmmo(value : boolean)
    self.spawnsAmmo = value
end

function Layer:getSpawnsAmmo() : boolean
    return self.spawnsAmmo
end

function Layer:removeBlock(block: Block.Block): nil
    local pos = block.LayerPosition
    if self.tileMap[pos.X] then
        self.tileMap[pos.X][pos.Y] = nil
    end

    local idx = table.find(self.blocks, block)
    if idx then
        table.remove(self.blocks, idx)
    end
end

function Layer:getRandomBlock(): Block.Block?
    if #self.blocks == 0 then
        return nil
    end
    return self.blocks[math.random(1, #self.blocks)]
end

function Layer:Destroy(): nil
    LoadedLayers[self._id] = nil
    for _, blk in ipairs(self.blocks) do
        blk:Destroy()
    end
    self.blocks = {}
    self.tileMap = {}
    
end

function Layer:isEmpty(): boolean
    return #self.blocks == 0
end

return Layer
