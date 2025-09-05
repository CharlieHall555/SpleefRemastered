export type BlockConfig = {
	Material: string?, -- name of the material (defaults to "Sand")
	Shape: string?, -- part shape, e.g. "Ball"
	Regenerates: boolean?, -- whether this block regenerates (defaults to false)
}

export type Block = {
	Id: number,
	_blockId: number,
	_LayerId: number?,
	Part: Part?,
	Shape: string?,
	Regenerates: boolean,
	Obstacle: Instance?, -- or a more specific type if you have one
	State: "VISIBLE" | "HIDDEN" | "DESTROYED",
	LayerPosition: Vector2,
	Falling: boolean,
	Type: string,

	setParentLayerId: (self: Block, parentLayerId: number) -> nil,
	setObstacle: (self: Block, obstacle: Instance?) -> nil,
	RemoveObstacle: (self: Block) -> nil,
	getObstacle: (self: Block) -> Instance?,

	setLayerPosition: (self: Block, newLayerPosition: Vector2) -> nil,
	setWorldPosition: (self: Block, newWorldPosition: Vector3) -> nil,
	getWorldPosition: (self: Block) -> Vector3,

	Show: (self: Block) -> nil,
	Hide: (self: Block) -> nil,
	Destroy: (self: Block) -> nil,
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PartPool = require(ModuleDirectory.PartPool)
local Materials = require(ModuleDirectory.Resources.Materials)
local LoadedBlocks = require(ModuleDirectory.LoadedBlocks)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local TweenService = game:GetService("TweenService")

local Block = {}
Block.__index = Block

local Counter = 0

function Block.init(): nil
	local BlocksFolder = Instance.new("Folder")
	BlocksFolder.Name = "Blocks"
	BlocksFolder.Parent = game.Workspace
end

function Block.new(blockConfig: BlockConfig?): Block
	blockConfig = blockConfig or {}
	local materialName = blockConfig.material or "grass"
	local shape = blockConfig.Shape
	local regenerates = blockConfig.Regenerates or false

	local materialDef: Materials.CustomMaterial = Materials.get(materialName)

	local self = setmetatable({}, Block)

	-- assign IDs
	self.Id = Counter
	Counter += 1
	self._blockId = self.Id
	self._LayerId = nil
	self.Type = blockConfig.material

	-- take or create part
	self.Part = PartPool.take() or Instance.new("Part")
	self.Part.CastShadow = false
	self.Part.CanCollide = true
	self.Part.CanTouch = true
	self.Part.CanQuery = true
	self.Part.Transparency = 0
	self.Part.CollisionGroup = "CG_BLOCKS"
	self.Part.Size = Vector3.new(1, 1, 1) * Config.BLOCK_SIZE
	self.Part.Color = (materialDef.color or Color3.fromRGB(187, 47, 187))
	self.Part.Material = materialDef.material or Enum.Material.Plastic
	self.Part.Anchored = true
	self.Part.Shape = Enum.PartType.Block
	self.Part.Parent = game.Workspace.Blocks
	self.Part:AddTag("Block")
	self.Part:SetAttribute("Id", self.Id)
	self.Part:SetAttribute("Type", blockConfig.material)

	-- config
	self.Shape = shape
	self.Regenerates = regenerates
	self.Obstacle = nil
	self.Part:SetAttribute("Regenerates", self.Regenerates or false)
	if self.Regenerates then
		self.Part:AddTag("TutorialBlock")
		self.TutorialBlock = true
	end

	if shape == "Ball" then
		self.Part.Shape = Enum.PartType.Ball
		self.Part.Size = Vector3.new(1, 1, 1) * Config.BLOCK_SIZE
	end

	-- initial state
	self.State = "VISIBLE"
	self.ParentLayer = nil
	self.LayerPosition = Vector2.new(0, 0)
	self.Falling = false

	LoadedBlocks[self.Id] = self
	return self
end

function Block:setParentLayerId(parentLayerId: number): nil
	self._LayerId = parentLayerId
end

function Block:getObstacle(): {}?
	return self.Obstacle
end

function Block:setObstacle(new: {}): nil
	self.Obstacle = new
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

function Block:Show(): nil
	if self.State == "DESTROYED" then
		warn(("Block %d:Show() called after destroy"):format(self.Id))
		return
	end
	if not self.Part then
		return
	end

	self.Part.Transparency = 0
	self.Part.CanCollide = true
	self.Part.CanQuery = true
	self.Part.CanTouch = true

	self.State = "VISIBLE"
end

function Block:Hide(): nil
	if self.State == "DESTROYED" then
		warn(("Block %d:Hide() called after destroy"):format(self.Id))
		return
	end
	if not self.Part then
		return
	end

	self.Part.Transparency = 1
	self.Part.CanCollide = false
	self.Part.CanQuery = false
	self.Part.CanTouch = false

	self.State = "HIDDEN"
end

function Block:Destroy(): nil
	if self.Obstacle then
		pcall(function()
			self.Obstacle:Destroy()
		end)
		self.Obstacle = nil
	end

	if self.Part then
		pcall(function()
			self.Part.Transparency = 1
			self.Part.CanCollide = false
			self.Part.CanQuery = false
			self.Part.CanTouch = false
			self.Part.CollisionGroup = "Default"
			self.Part.Anchored = true
		end)

		pcall(function()
			PartPool.add(self.Part)
		end)

		self.Part = nil
	end

	if LoadedBlocks then
		LoadedBlocks[self.Id] = nil
	end

	self = nil
end

return Block
