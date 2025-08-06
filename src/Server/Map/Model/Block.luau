export type BlockConfig = {
    Material: string?,       -- name of the material (defaults to "Sand")
    Shape: string?,          -- part shape, e.g. "Ball"
    Regenerates: boolean?    -- whether this block regenerates (defaults to false)
}

export type Block = {
    Id: number,
    _blockId: number,
    _LayerId: number?,
    Part: Part,
    Shape: string?,
    Regenerates: boolean,
    Obstacle: any?,
    State: string,
    ParentLayer: any?,
    LayerPosition: Vector2,
    Falling: boolean,
    Type : string,

    setParentLayerId: (self: Block, parentLayerId: number) -> nil,
    setObstacle: (self: Block, Obstacle: any) -> nil,
    RemoveObstacle: (self: Block) -> nil,
    setLayerPosition: (self: Block, newLayerPosition: Vector2) -> nil,
    setWorldPosition: (self: Block , newWorldPosition : Vector3) -> nil,
    getWorldPosition: (self: Block) -> Vector3,
    Destroy: (self: Block) -> nil
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PartPool = require(ModuleDirectory.PartPool)
local Materials = require(ModuleDirectory.Materials)
local LoadedBlocks = require(ModuleDirectory.LoadedBlocks)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local Block = {}
Block.__index = Block

local Counter = 0

function Block.init(): nil
    local BlocksFolder = Instance.new("Folder")
    BlocksFolder.Name = "Blocks"
    BlocksFolder.Parent = game.Workspace
end

function Block.new(config: BlockConfig?): Block
    config = config or {}
    local materialName = config.Type or "Sand"
    local shape = config.Shape
    local regenerates = config.Regenerates or false

    local self = setmetatable({}, Block)

    -- assign IDs
    self.Id = Counter
    Counter += 1
    self._blockId = self.Id
    self._LayerId = nil
    self.Type = config.Type

    -- take or create part
    self.Part = PartPool.take() or Instance.new("Part")
    self.Part.CastShadow = false
    self.Part.CanCollide = true
    self.Part.CanTouch = true
    self.Part.CanQuery = true
    self.Part.Transparency = 0
    self.Part.Size = Vector3.new(1, 1, 1) * Config.BLOCK_SIZE
    self.Part.Color = Materials[materialName].Color
    self.Part.Material = Materials[materialName].Material
    self.Part.Anchored = true
    self.Part.Parent = game.Workspace.Blocks
    self.Part:AddTag("Block")
    self.Part:SetAttribute("Id", self.Id)

    -- config
    self.Shape = shape
    self.Regenerates = regenerates
    self.Obstacle = nil

    if shape == "Ball" then
        self.Part.Shape = Enum.PartType.Ball
        self.Part.Size = Vector3.new(1, 1, 1) * Config.BLOCK_SIZE
    end

    -- initial state
    self.State = "DEFAULT"
    self.ParentLayer = nil
    self.LayerPosition = Vector2.new(0, 0)
    self.Falling = false

    LoadedBlocks[self.Id] = self
    return self
end

function Block:setParentLayerId(parentLayerId: number): nil
    self._LayerId = parentLayerId
end

function Block:setObstacle(obstacle: any)
    self.Obstacle = obstacle
    obstacle:setParentBlock(self)
end

function Block:RemoveObstacle()
    self.Obstacle = nil
end

function Block:setWorldPosition(newWorldPosition: Vector3): nil
    self.Part.Position = newWorldPosition
end

function Block:setLayerPosition(newLayerPosition: Vector2): nil
    self.LayerPosition = newLayerPosition
end

function Block:getWorldPosition(): Vector3
    return self.Part.Position
end

function Block:Destroy(): nil
    if self.ParentLayer then
        self.ParentLayer:RemoveBlock(self)
    end
    if self.Obstacle then
        self.Obstacle:Destroy()
    end

    if self.Part then
        self.Part.Transparency = 1
        self.Part.CanCollide = false
        self.Part.CanQuery = false
        self.Part.CanTouch = false
        PartPool.add(self.Part)
    end
    

    LoadedBlocks[self.Id] = nil
    self.Part = nil
end

return Block
