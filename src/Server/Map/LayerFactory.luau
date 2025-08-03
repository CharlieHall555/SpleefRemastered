export type LayerCreationParams = {
    worldPosition: Vector3,
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlaneFactory = require(ModuleDirectory.Map.PlaneFactory)
local Layer = require(ModuleDirectory.Map.Layer)
local Block = require(ModuleDirectory.Map.Block)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local LayerFactory = {}
LayerFactory.__index = LayerFactory

function LayerFactory.create(params: LayerCreationParams,plane: PlaneFactory.PlaneData): Layer.Layer
    assert(params, "Params are missing")
    assert(params.worldPosition, "Params missing worldPosition argument.")
    assert(plane, "Plane data missing.")

    local width     = #plane
    local height    = #plane[1]
    local center    = params.worldPosition
    local blockSize = Config.BLOCK_SIZE

    -- Calculate the top-left corner so layer is centered on 'center'
    local halfWidth  = (width - 1) * blockSize / 2
    local halfHeight = (height - 1) * blockSize / 2
    local originCorner = Vector3.new(
        center.X - halfWidth,
        center.Y,
        center.Z - halfHeight
    )

    local layerInstance = Layer.new(center, Vector2.new(width, height))

    for x = 1, width do
        for y = 1, height do
            local info = plane[x][y]
            if info.place then
                local worldPos = originCorner + Vector3.new(
                    (x - 1) * blockSize,
                    0,
                    (y - 1) * blockSize
                )
                local blk = Block.new()
                blk:setWorldPosition(worldPos)
                blk:setLayerPosition(Vector2.new(x, y))
                blk:setParentLayerId(layerInstance._id)
                layerInstance:addBlock(blk, Vector2.new(x, y))
            end
        end
    end

    return layerInstance
end

return LayerFactory
