local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Block = require(ModuleDirectory.Map.Block)
local Obstacle = require(ModuleDirectory.Map.Obstacle)

local ObstacleFactory = {}

function ObstacleFactory.newObstacle(parentBlock : Block.Block , name : string) : Obstacle.Obstacle
    
    local new = Obstacle.new(name)
    new:setParentBlock(parentBlock.Id , parentBlock.Part.CFrame)
    parentBlock.obstacle = new
    return new

end

function ObstacleFactory.destroy(obstacle : Obstacle.Obstacle)
    obstacle.model:Destroy()
    obstacle.hitbox = nil
    obstacle = nil
end

function ObstacleFactory.removeObstacle(block : Block.Block)
    if block.Obstacle then
        ObstacleFactory.destroy(block.obstacle)
    end
    block.Obstacle = nil
end



return ObstacleFactory 