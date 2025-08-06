local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Layer = require(ModuleDirectory.Map.Layer)

export type Map = {
    OriginPosition: Vector3,
    Layers: { Layer.Layer },
    Count: number,

    new: (originPosition: Vector3) -> Map,
    addLayer: (self: Map, Layer: Layer.Layer ) -> nil,
    getTopLayer: (self: Map) -> Layer.Layer ?,
    getRandomLayer: (self: Map) -> Layer.Layer?

}

local Map = {}
Map.__index = Map

function Map.new(originPosition: Vector3): Map
    local self = setmetatable({}, Map)
    self.OriginPosition = originPosition
    self.Layers = {}
    self.Count = 0
    return self
end

---@diagnostic disable-next-line: undefined-type
function Map:addLayer(Layer:Layer.Layer): nil
    table.insert(self.Layers, Layer)
    self.Count += 1
end

function Map:getTopLayer(): Layer.Layer ?
    for i = #self.Layers, 1, -1 do
        local Layer = self.Layers[i]
        if not Layer:isEmpty() then
            return Layer
        end
    end
    return nil
end

function Map:getRandomLayer(): Layer.Layer?
    if #self.Layers == 0 then
        return nil
    end
    return self.Layers[math.random(1, #self.Layers)]
end


function Map:Destroy()
    for _ , each in self.Layers do
        each:Destroy()
    end

    self = nil 
end

return Map