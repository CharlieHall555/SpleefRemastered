local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Map.Block)


local BlockFactory = {}

function BlockFactory.create(config : Block.BlockConfig) : Block.Block
    local newBlock = Block.new(config)
    return newBlock
end

function BlockFactory.destroy(block : Block.Block) : nil

    block:Destroy()
    
end

function BlockFactory.createAtPosition(worldPosition, config)
    local block = BlockFactory.create(config)
    if block and worldPosition then
        block:setWorldPosition(worldPosition)
    end
    return block
end

function BlockFactory.bulkCreate(configs)
    local blocks = {}
    for i, cfg in ipairs(configs) do
        blocks[i] = BlockFactory.create(cfg)
    end
    return blocks
end

return BlockFactory