
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local TweenService = game:GetService("TweenService")
local Block = require(ModuleDirectory.Map.Block)
local Layer = require(ModuleDirectory.Map.Layer)
local LoadedBlocks = require(ModuleDirectory.LoadedBlocks)
local LoadedLayers = require(ModuleDirectory.LoadedLayers)

local BlockFactory = {
    _activeTweens = {}
}

function BlockFactory.create(config: Block.BlockConfig): Block.Block
    local newBlock = Block.new(config)
    return newBlock
end

function BlockFactory.destroyById(blockId: number): nil
    local block = LoadedBlocks[blockId]
    if block then
        BlockFactory.destroy(block)
    end
end

function BlockFactory.destroy(block: Block.Block): nil
    -- cancel any active tween for this block
    local tween = BlockFactory._activeTweens[block]
    if tween then
        tween:Cancel()
        BlockFactory._activeTweens[block] = nil
    end

    local parentGridId = block._LayerId
    if parentGridId then
        local parentGrid: Layer.Layer? = LoadedLayers[parentGridId]
        if parentGrid then
            parentGrid:removeBlock(block)
        end
    end
    block:Destroy()
end

function BlockFactory.createAtPosition(worldPosition: Vector3?, config: Block.BlockConfig): Block.Block
    local block = BlockFactory.create(config)
    if block and worldPosition then
        block:setWorldPosition(worldPosition)
    end
    return block
end

function BlockFactory.bulkCreate(configs: {Block.BlockConfig}): {Block.Block}
    local blocks = {}
    for i, cfg in ipairs(configs) do
        blocks[i] = BlockFactory.create(cfg)
    end
    return blocks
end

function BlockFactory.slowDestroy(block: Block.Block): nil
    if not block or not block.Part then
        return
    end

    local part = block.Part
    part.Transparency = 0
    local tweenInfo = TweenInfo.new(1)
    local tween = TweenService:Create(part, tweenInfo, {Transparency = 0.8})
    BlockFactory._activeTweens[block] = tween
    tween:Play()

    tween.Completed:Connect(function()
        -- remove mapping when done
        BlockFactory._activeTweens[block] = nil
        -- if block still exists, destroy it
        if part and part.Parent then
            BlockFactory.destroy(block)
        end
    end)
end

function BlockFactory.stopAllTweens(): nil
    for block, tween : Tween in pairs(BlockFactory._activeTweens) do
        if tween then
            tween:Cancel()
            BlockFactory._activeTweens[block] = nil
            if tween.Instance and tween.Instance:IsA("Part") then
                tween.Instance.Transparency = 1
            end
            tween:Destroy()
        end
    end
end

return BlockFactory
