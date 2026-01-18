local HttpService = game:GetService("HttpService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local Layer , Block

type Layer = Layer.Layer
type Block = Block.Block

export type Map = {
    originPosition: Vector3,
    layers: { Layer },
    count: number,
    background: Model?,
    id : string,

    new: (originPosition: Vector3) -> Map,
    get: (id: string) -> Map?,
    addLayer: (self: Map, layer: Layer) -> nil,
    getLayer: (self: Map, n: number) -> Layer?,
    getTopLayer: (self: Map) -> Layer?,
    getSize: (self: Map) -> Vector2,
    getRandomLayer: (self: Map) -> Layer?,
    destroy: (self: Map) -> nil,
}

local loadedMaps : { [string] : Map } = {}

local Map = {}
Map.__index = Map

function Map.new(originPosition: Vector3): Map
    local self = setmetatable({}, Map)
    self.originPosition = originPosition
    self.layers = {}
    self.count = 0
    self.id = HttpService:GenerateGUID(false)
    self.worldHeightToLayer = {}
    loadedMaps[self.id] = self
    return self
end

function Map.get(id : string) : Map?
    return loadedMaps[id]
end

function Map.addLayer(self: Map, layer: Layer): nil
    table.insert(self.layers, layer)
    if self.worldHeightToLayer[layer.originPosition.Y] then
        warn("Layer already exists at this world height: " .. tostring(layer.originPosition.Y) .. " overwriting.")
        self.worldHeightToLayer[layer.originPosition.Y] = layer
    end
  
    self.count += 1
end

function Map.getLayerAtWorldHeight(self : Map , worldHeight : number) : Layer?
   return self.worldHeightToLayer[worldHeight]
end

function Map.getLayer(self: Map, n: number): Layer?
    return self.layers[n]
end

function Map.getTopLayer(self: Map): Layer?
    for i = #self.layers, 1, -1 do
        local layer = self.layers[i]
        if not layer:isEmpty() then
            return layer
        end
    end
    return nil
end

function Map.getSize(self: Map): Vector2
    error("unimplemented")
    return self:getTopLayer().size
end

function Map.getRandomLayer(self: Map): Layer?
    if #self.layers == 0 then
        return nil
    end
    return self.layers[math.random(1, #self.layers)]
end


function Map.destroy(self: Map): nil
    if self.background then
        self.background:Destroy()
    end
    for _, layer in self.layers do
        for _, blk in ipairs(table.clone(layer.blocks)) do
            blk:destroy()
        end
        layer:destroy()
    end

    loadedMaps[self.id] = nil
    self = nil
end

function Map.init()

    Block = require(ModuleDirectory.Systems.Map.Block)
    Layer = require(ModuleDirectory.Systems.Map.Layer)
    
end

return Map