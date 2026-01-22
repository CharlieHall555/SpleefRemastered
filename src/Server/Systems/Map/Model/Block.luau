export type BlockConfig = {
	material: string?, -- name of the material (defaults to "grass")
	shape: string?, -- part shape, e.g. "ball"
	regenerates: boolean?, -- whether this block regenerates (defaults to false)
	worldPosition: Vector3?, -- initial world position
	layerPosition: Vector2?, -- initial layer position
}

export type Block = {
	id: string,
	_blockId: number,
	parentLayerId: string?,
	part: Part?,
	shape: string?,
	regenerates: boolean,
	state: "VISIBLE" | "HIDDEN" | "DESTROYED",
	layerPosition: Vector2,
	falling: boolean,
	type: string?,

	setParentLayerId: (self: Block, parentLayerId: string) -> nil,
	getParentLayer: (self: Block) -> Layer?, -- you can tighten this to Layer.Layer? once Layer type is clean

	setLayerPosition: (self: Block, newLayerPosition: Vector2) -> nil,
	setWorldPosition: (self: Block, newWorldPosition: Vector3) -> nil,
	getWorldPosition: (self: Block) -> Vector3,

	show: (self: Block) -> nil,
	hide: (self: Block) -> nil,
	isActive: (self: Block) -> boolean,
	destroy: (self: Block) -> nil,
}

local HttpService = game:GetService("HttpService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local partPool = require(ModuleDirectory.PartPool)
local Materials = require(ModuleDirectory.Systems.Map.Materials)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local TweenService = game:GetService("TweenService")

local Layer, Map, BlocksFolder

type Layer = Layer.Layer
type Map = Map.Map

local loadedBlocks: { [string]: Block } = {}
local activeTweens: { [string]: Tween } = {}

local blockDestroyedCallback : ((block: Block) -> ())? = nil 

local Block = {}
Block.__index = Block

local Counter = 0

function Block.setBlockDestroyedCallback(fn :((block: Block) -> ())?)
	blockDestroyedCallback = fn
end

function Block.getBlockFolder(): Folder?
	return BlocksFolder
end

function Block.init(): nil
	BlocksFolder = Instance.new("Folder")
	BlocksFolder.Name = "Blocks"
	BlocksFolder.Parent = workspace

	Map = require(ModuleDirectory.Systems.Map.Map)
	Layer = require(ModuleDirectory.Systems.Map.Layer)
end

local function createPart(blockConfig: BlockConfig?): Part
	blockConfig = blockConfig or {}

	local materialName = blockConfig.material or "grass"
	local shape = blockConfig.shape

	local materialDef: Materials.CustomMaterial = Materials.get(materialName)

	-- take or create part
	local part = partPool.take() or Instance.new("Part")
	part.CastShadow = false
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	part.Transparency = materialDef.transparency or 0
	part.CollisionGroup = "CG_BLOCKS"
	part.Size = Vector3.new(1, 1, 1) * Config.BLOCK_SIZE
	part.Color = (materialDef.color or Color3.fromRGB(187, 47, 187))
	part.Material = materialDef.material or Enum.Material.Plastic
	part.Anchored = true
	part.Shape = Enum.PartType.Block
	part:AddTag("block")
	part:AddTag("Block")

	if shape == "ball" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1, 1, 1) * Config.BLOCK_SIZE
	end

	part.Parent = BlocksFolder
	return part
end

function Block.get(id : string)
	return loadedBlocks[id]
end

function Block.bulkCreate(configs: { BlockConfig }): { Block }
	local blocks = {}
	for i, cfg in ipairs(configs) do
		blocks[i] = Block.new(cfg)
	end
	return blocks
end

function Block.new(blockConfig: BlockConfig?): Block
	blockConfig = blockConfig or {}

	local materialName = blockConfig.material or "grass"
	local shape = blockConfig.shape
	local regenerates = blockConfig.regenerates or false

	local self: Block = setmetatable({}, Block)

	self.id = HttpService:GenerateGUID(false)

	self.type = materialName

	self.part = createPart(blockConfig)
	self.part:SetAttribute("id", self.id)
	self.part:SetAttribute("type", self.type)
	self.part:SetAttribute("Id", self.id)
	self.part:SetAttribute("Type", self.type)

	-- config
	self.shape = shape
	self.regenerates = regenerates
	self.part:SetAttribute("regenerates", self.regenerates)

	-- optional initial position
	if blockConfig.worldPosition and self.part then
		self.part.Position = blockConfig.worldPosition
	end

	if self.regenerates then
		self.part:AddTag("tutorialBlock")
		self.part:SetAttribute("tutorialBlock", true)
	end

	-- initial state
	self.state = "VISIBLE"
	self.layerPosition = blockConfig.layerPosition or Vector2.new(0,0)
	self.parentLayerId = nil
	self.falling = false

	loadedBlocks[self.id] = self
	return self
end

function Block:setParentLayer(parentLayer: Layer): nil
	self.parentLayerId = parentLayer.id
end

function Block:getParentLayer()
	if self.parentLayerId then
		return Layer.get(self.parentLayerId)
	end
	return nil
end

function Block:setWorldPosition(newWorldPosition: Vector3): nil
	if self.part then
		self.part.Position = newWorldPosition
	end
end

function Block:setLayerPosition(newLayerPosition: Vector2): nil
	self.layerPosition = newLayerPosition
end

function Block:getWorldPosition(): Vector3
	if self.part then
		return self.part.Position
	end
	return Vector3.new(0, 0, 0)
end

function Block:show(): nil
	if self.state == "DESTROYED" then
		warn(("Block %s:show() called after destroy"):format(self.id))
		return
	end
	if not self.part then
		return
	end

	self.part.Transparency = 0
	self.part.CanCollide = true
	self.part.CanQuery = true
	self.part.CanTouch = true

	self.state = "VISIBLE"
end

function Block:hide(): nil
	if self.state == "DESTROYED" then
		warn(("Block %s:hide() called after destroy"):format(self.id))
		return
	end
	if not self.part then
		return
	end

	self.part.Transparency = 1
	self.part.CanCollide = false
	self.part.CanQuery = false
	self.part.CanTouch = false

	self.state = "HIDDEN"
end

function Block.isActive(self : Block) : boolean
	return self and self.state == "VISIBLE" 
end

function Block.destroy(self : Block): nil


	if self.regenerates then
        task.spawn(function()
            self:hide()
            task.wait(Config.BLOCK_REGEN_TIME)
            self:show()
        end)
        return
    end

	if self.part then
		pcall(function()
			self.part.Transparency = 1
			self.part.CanCollide = false
			self.part.CanQuery = false
			self.part.CanTouch = false
			self.part.CollisionGroup = "Default"
			self.part.Anchored = true
		end)

		pcall(function()
			partPool.add(self.part)
		end)

		self.part = nil
	end

	local tween = activeTweens[self.id]
	if tween then
        tween:Cancel()
        activeTweens[self.id] = nil
    end

	if blockDestroyedCallback then
		blockDestroyedCallback(self)
	end

	if self.parentLayerId then
		local parentLayer = self:getParentLayer()
		if parentLayer then
			parentLayer:removeBlock(self)
		end
	end

	loadedBlocks[self.id] = nil
end

function Block.slowDestroy(self: Block): nil
	if not self or not self.part then
		return
	end

	self.part.Transparency = 0
	local tweenInfo = TweenInfo.new(1)
	local tween = TweenService:Create(self.part, tweenInfo, { Transparency = 0.8 })
	activeTweens[self.id] = tween
	tween:Play()

	tween.Completed:Connect(function()
		activeTweens[self.id] = nil
		if self then
			self:destroy()
		end
	end)
end

function Block.stopAllTweens(): nil
	for blockId, tween: Tween in pairs(activeTweens) do
		if tween then
			tween:Cancel()
			activeTweens[blockId] = nil

			local inst = tween.Instance
			if inst and inst:IsA("BasePart") then
				inst.Transparency = 1
			end

			tween:Destroy()
		end
	end
end

return Block
