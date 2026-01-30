local HttpService = game:GetService("HttpService")

local Meteor = {}
Meteor.__index = Meteor

export type Meteor = {
    id : string,
    worldPosition : Vector3,
    dir : Vector3,
    speed : number,
    layerId : string,
    MeteorType : string,
    destroy : (self : Meteor) -> ()
}

local onDestroyed : ((c :Meteor ) -> ())? = nil

local loaded : {[string] : Meteor} = {}

function Meteor.get(id : string)
    return loaded[id]
    
end

function Meteor.getAll() : {[string] : Meteor}
    return loaded
end

function Meteor.setOnDestroyed(fn : (c : Meteor) -> ())
    onDestroyed = fn
end

function Meteor.new(worldPosition: Vector3, dir: Vector3, speed: number, layerId: string, MeteorType: string): Meteor
    local self = setmetatable({}, Meteor)
    
    self.id = HttpService:GenerateGUID(false)
    self.worldPosition = worldPosition
    self.dir = dir
    self.speed = speed
    self.layerId = layerId
    self.MeteorType = MeteorType
    loaded[self.id] = self
    
    return self
end

function Meteor:destroy()

    loaded[self.id] = nil
    if onDestroyed then
        onDestroyed(self)
    end
    
    setmetatable(self, nil)
end

return Meteor