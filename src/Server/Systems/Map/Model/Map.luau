local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Layer = require(ModuleDirectory.Systems.Map.Layer)
local BlockFactory = require(ModuleDirectory.Systems.Map.BlockFactory)

export type Map = {
    originPosition: Vector3,
    layers: { Layer.Layer },
    count: number,
    background : Model?,

    new: (originPosition: Vector3) -> Map,
    addLayer: (self: Map, Layer: Layer.Layer ) -> nil,
    getTopLayer: (self: Map) -> Layer.Layer ?,
    getRandomLayer: (self: Map) -> Layer.Layer?,
    Destroy:  (self: Map) -> nil,

}

local Map = {}
Map.__index = Map

function Map.new(originPosition: Vector3): Map
    local self = setmetatable({}, Map)
    self.originPosition = originPosition
    self.layers = {}
    self.count = 0
    return self
end

---@diagnostic disable-next-line: undefined-type
function Map:addLayer(Layer:Layer.Layer): nil
    table.insert(self.layers, Layer)
    self.count += 1
end

function Map:getLayer(n : number) : Layer.Layer?
    return self.layers[n]  
end

function Map:getTopLayer(): Layer.Layer ?
    for i = #self.layers, 1, -1 do
        local Layer = self.layers[i]
        if not Layer:isEmpty() then
            return Layer
        end
    end
    return nil
end

function Map:getSize() : Vector2
    return self:getTopLayer().size
end

function Map:getRandomLayer(): Layer.Layer?
    if #self.layers == 0 then
        return nil
    end
    return self.layers[math.random(1, #self.layers)]
end


function Map:Destroy()
    if self.background then
        self.background:Destroy()
    end
    for _ , each in self.layers do
        
        for _, blk in ipairs(table.clone(each.blocks)) do
            BlockFactory.destroy(blk)
        end
        each:Destroy()
    end

    self = nil 
end

return Map