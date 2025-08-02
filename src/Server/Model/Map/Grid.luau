local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = ModuleDirectory.Map.Block

export type Grid = {
    _id: number,
    Size: Vector2,
    Blocks: { Block.Block },
    TileMap: { [number]: { [number]: Block.Block? } },
    OriginPosition: Vector3,

    new: (originPosition: Vector3, size: Vector2) -> Grid,
    addBlock: (self: Grid, block: Block.Block, position: Vector2) -> nil,
    getBlock: (self: Grid, position: Vector2) -> Block.Block?,
    removeBlock: (self: Grid, block: Block.Block) -> nil,
    getRandomBlock: (self: Grid) -> Block.Block?,
    destroy: (self: Grid) -> nil,
    isEmpty: (self: Grid) -> boolean,
}

local nextGridId = 0
local Grid = {}
Grid.__index = Grid

function Grid.new(originPosition: Vector3, size: Vector2): Grid
    nextGridId += 1

    local self = setmetatable({}, Grid)
    self._id = nextGridId
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

    return self
end

function Grid:addBlock(block: Block.Block, position: Vector2): nil
    table.insert(self.Blocks, block)
    self.TileMap[position.X][position.Y] = block
end

function Grid:getBlock(position: Vector2): Block.Block?
    return (self.TileMap[position.X] and self.TileMap[position.X][position.Y]) or nil
end

function Grid:removeBlock(block: Block.Block): nil
    local pos = block.GridPosition
    if self.TileMap[pos.X] then
        self.TileMap[pos.X][pos.Y] = nil
    end

    local idx = table.find(self.Blocks, block)
    if idx then
        table.remove(self.Blocks, idx)
    end
end

function Grid:getRandomBlock(): Block.Block?
    if #self.Blocks == 0 then
        return nil
    end
    return self.Blocks[math.random(1, #self.Blocks)]
end

function Grid:destroy(): nil
    for _, blk in ipairs(self.Blocks) do
        blk:Destroy()
    end
    self.Blocks = {}
    self.TileMap = {}
end

function Grid:isEmpty(): boolean
    return #self.Blocks == 0
end

return Grid
