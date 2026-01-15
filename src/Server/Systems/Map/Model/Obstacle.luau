local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Systems.Map.Block)

local ObstacleModels: Folder?
 local ObstaclesFolder : Folder?

export type Obstacle = {
    Id: number?,
    model: Model,
    parentBlockId: number?,
    hitbox: Part,

    setParentBlock: (self: Obstacle, parentBlockId: number, parentCFrame: CFrame) -> nil,
    getWorldPosition: (self: Obstacle) -> Vector3
}

local Obstacle = {}
Obstacle.__index = Obstacle

local Counter = 0

function Obstacle.init(): nil
    ObstaclesFolder = Instance.new("Folder")
	ObstaclesFolder.Name = "Obstacles"
	ObstaclesFolder.Parent = game.Workspace
	ObstacleModels = game:GetService("ServerStorage"):WaitForChild("Models"):WaitForChild("Obstacles")
end

function Obstacle.new(ObstacleName: string): Obstacle
	local self = setmetatable({}, Obstacle)
	self.parentBlockId = nil

	assert(ObstacleModels:FindFirstChild(ObstacleName), "Obstacle name doesnt exsist")
	self.model = ObstacleModels[ObstacleName]:Clone()
    self.Id = Counter
    Counter += 1
	self.hitbox = self.model.Hitbox
	self.hitbox:AddTag("Obstacle")
	self.hitbox.CollisionGroup = "CG_BLOCKS"

	self.model:SetAttribute("Id", self.Id)

	return self
end

function Obstacle:setParentBlock(parentBlockId : number , ParentCframe : CFrame): nil
    if self.model then
        self.model:PivotTo(ParentCframe)
	    self.model.Parent = ObstaclesFolder
    end
	

	self.parentBlockId = parentBlockId
end

function Obstacle:getWorldPosition(): Vector3
	return self.Part.Position
end
return Obstacle
