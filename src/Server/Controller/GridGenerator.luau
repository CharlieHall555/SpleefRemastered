export type GridCreationParams = {
    worldPosition: Vector3,
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneGenerator = require(ModuleDirectory.PlaneGenerator)
local Grid = require(ModuleDirectory.Map.Grid)
local Block = require(ModuleDirectory.Map.Block)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local GridGenerator = {}
GridGenerator.__index = GridGenerator

function GridGenerator.generateGrid(params: GridCreationParams, plane: PlaneGenerator.PlaneCreationOutput): Grid.Grid
    local width = #plane
    local height = #plane[1]
    local origin = params.worldPosition
    local blockSize = Config.BLOCK_SIZE

    local grid = Grid.new(origin, Vector2.new(width, height))

    for x = 1, width do
        for y = 1, height do
            local info = plane[x][y]
            if info.place then
                local worldPos = Vector3.new(
                    origin.X + (x - 1) * blockSize,
                    origin.Y,
                    origin.Z + (y - 1) * blockSize
                )
                local blk = Block.new()
                blk:setWorldPosition(worldPos)
                blk:setGridPosition(Vector2.new(x, y))
                blk:setParentGridId(grid._id)
                grid:addBlock(blk, Vector2.new(x, y))
            end
        end
    end

    return grid
end

return GridGenerator
