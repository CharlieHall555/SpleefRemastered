local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Map.Block)
local LoadedLayers = require(ModuleDirectory.LoadedLayers)

export type Layer = {
    _id: number,
    Size: Vector2,
    Blocks: { Block.Block },
    TileMap: { [number]: { [number]: Block.Block? } },
    OriginPosition: Vector3,

    new: (originPosition: Vector3, size: Vector2) -> Layer,
    addBlock: (self: Layer, block: Block.Block, position: Vector2) -> nil,
    getBlock: (self: Layer, position: Vector2) -> Block.Block?,
    removeBlock: (self: Layer, block: Block.Block) -> nil,
    getRandomBlock: (self: Layer) -> Block.Block?,
    destroy: (self: Layer) -> nil,
    isEmpty: (self: Layer) -> boolean,
}

local nextLayerId = 0
local Layer = {}
Layer.__index = Layer

function Layer.new(originPosition: Vector3, size: Vector2): Layer
    nextLayerId += 1

    local self = setmetatable({}, Layer)
    self._id = nextLayerId
    self.Size = size
    self.OriginPosition = originPosition
    self.Blocks = {}
    self.TileMap = {}

    for x = 1, size.X do
        self.TileMap[x] = {}
        for y = 1, size.Y do
            self.TileMap[x][y] = nil
        end
    end

    LoadedLayers[self._id] = self
    return self
end

function Layer:addBlock(block: Block.Block, position: Vector2): nil
    table.insert(self.Blocks, block)
    self.TileMap[position.X][position.Y] = block
end

function Layer:getBlock(position: Vector2): Block.Block?
    return (self.TileMap[position.X] and self.TileMap[position.X][position.Y]) or nil
end

function Layer:removeBlock(block: Block.Block): nil
    local pos = block.LayerPosition
    if self.TileMap[pos.X] then
        self.TileMap[pos.X][pos.Y] = nil
    end

    local idx = table.find(self.Blocks, block)
    if idx then
        table.remove(self.Blocks, idx)
    end
end

function Layer:getRandomBlock(): Block.Block?
    if #self.Blocks == 0 then
        return nil
    end
    return self.Blocks[math.random(1, #self.Blocks)]
end

function Layer:Destroy(): nil
    LoadedLayers[self._id] = nil
    for _, blk in ipairs(self.Blocks) do
        blk:Destroy()
    end
    self.Blocks = {}
    self.TileMap = {}
    
end

function Layer:isEmpty(): boolean
    return #self.Blocks == 0
end

return Layer
