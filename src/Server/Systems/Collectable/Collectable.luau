local HttpService = game:GetService("HttpService")

local Collectable = {}
Collectable.__index = Collectable

export type Collectable = {
    id : string,
    worldPosition : Vector3,
    layerId : string,
    collectableType : string,
    destroy : (self : Collectable) -> ()
}

local onDestroyed : ((c : Collectable) -> ())? = nil

local loaded = {}

function Collectable.get(id : string)
    return loaded[id]
    
end

function Collectable.setOnDestroyed(fn : (c : Collectable) -> ())
    onDestroyed = fn
end

function Collectable.new(worldPosition: Vector3, layerId: string, collectableType: string): Collectable
    local self = setmetatable({}, Collectable)
    
    self.id = HttpService:GenerateGUID(false)
    self.worldPosition = worldPosition
    self.layerId = layerId
    self.collectableType = collectableType
    loaded[self.id] = self
    
    return self
end

function Collectable:destroy()

    loaded[self.id] = nil
    if onDestroyed then
        onDestroyed(self)
    end
    
    setmetatable(self, nil)
end

return Collectable