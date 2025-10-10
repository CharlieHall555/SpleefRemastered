local Bomb = {}
Bomb.__index = Bomb

local BombTemplate = game.ReplicatedStorage:WaitForChild("Resources"):WaitForChild("BombTemplate")

local counter = 0

export type Bomb = {
    position: Vector3,
    explosionRadius: number,
    countDown: number,
    timeToExplode: number,
    model : Model?,
    onExplode : () -> (),
    loop : (self : Bomb, dt : number) -> (boolean),
}

function Bomb.new(timeToExplode : number , position : Vector3 , explosionRadius : number , onExplode : () -> ())
    local self = setmetatable({} , Bomb)
    self.id = counter
    counter += 1
    self.position = position
    self.explosionRadius = explosionRadius
    self.countDown = timeToExplode
    self.timeToExplode = timeToExplode
    self.onExplode = onExplode
    self.model = BombTemplate:Clone()
    self.model:PivotTo(CFrame.new(position))
    self.model.Parent = workspace
    return self
end

function Bomb:expode()
    
    if self.onExplode then
        self.onExplode(self.id , self.position , self.explosionRadius)
        self.model:Destroy()
        self = nil
    end

end

function Bomb:loop(dt : number)

    print(self.countDown)
    self.countDown = self.countDown - dt
    if self.countDown <= 0 then
---@diagnostic disable-next-line: invalid-class-name
        if typeof(self.model) == "Model" then
            self.position = self.model.PrimaryPart.Position
        else
            self.position = self.model.Position
        end
        
        self:expode()
    end
    
end

return Bomb