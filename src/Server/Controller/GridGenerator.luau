export type GridCreationParams = {
    worldPosition: Vector3,
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapGenerator = require(ModuleDirectory.MapGenerator)
local Grid = require(ModuleDirectory.Map.Grid)
local Block = require(ModuleDirectory.Map.Block)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local GridGenerator = {}
GridGenerator.__index = GridGenerator

-- Generates a Grid from a PlaceInfo plane, instantiating blocks in the world
function GridGenerator.generateGrid(
    self,
    params: GridCreationParams,
    plane: { [number]: { [number]: MapGenerator.PlaceInfo } }
): Grid.Grid
    local width = #plane
    local height = #plane[1]
    local origin = params.worldPosition
    local blockSize = Config.BLOCK_SIZE

    -- create an empty Grid
    local grid = Grid.new(origin, Vector2.new(width, height))

    -- iterate over map plane
    for x = 1, width do
        for y = 1, height do
            local info = plane[x][y]
            if info.place then
                -- compute world position for this block based on Config.BLOCK_SIZE
                local worldPos = Vector3.new(
                    origin.X + (x - 1) * blockSize,
                    origin.Y,
                    origin.Z + (y - 1) * blockSize
                )
                -- instantiate block at position
                local blk = Block.new(worldPos)
                -- record its grid position on the block
                blk.GridPosition = Vector2.new(x, y)
                -- add to grid
                grid:addBlock(blk, Vector2.new(x, y))
            end
        end
    end

    return grid
end

return GridGenerator