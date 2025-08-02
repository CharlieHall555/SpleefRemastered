export type LayerCreationParams = {
    worldPosition: Vector3,
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneGenerator = require(ModuleDirectory.Map.PlaneFactory)
local Layer = require(ModuleDirectory.Map.Layer)
local Block = require(ModuleDirectory.Map.Block)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local LayerFactory = {}
LayerFactory.__index = LayerFactory

function LayerFactory.create(params: LayerCreationParams, plane: PlaneGenerator.PlaneData): Layer.Layer
    local width = #plane
    local height = #plane[1]
    local origin = params.worldPosition
    local blockSize = Config.BLOCK_SIZE

    local Layer = Layer.new(origin, Vector2.new(width, height))

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
                blk:setLayerPosition(Vector2.new(x, y))
                blk:setParentLayerId(Layer._id)
                Layer:addBlock(blk, Vector2.new(x, y))
            end
        end
    end

    return Layer
end

return LayerFactory
