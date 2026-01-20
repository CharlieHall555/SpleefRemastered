local HttpService = game:GetService("HttpService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local config = require(game:GetService("ServerScriptService").ServerConfigurations)

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
    removeLayer: (self: Map, layer: Layer) -> nil,
    getLayer: (self: Map, n: number) -> Layer?,
    getLayerAtHeight: (self: Map, height: number) -> Layer?,
    getClosestLayerTo: (self: Map, worldLayerHeight: number) -> Layer?,
    snapPositionToGrid: (self: Map, worldPosition: Vector3) -> {layerIndex: number, layerPosition: Vector2},
    getLayers: (self: Map) -> {Layer},
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
    self.background = nil
    self.count = 0
    self.id = HttpService:GenerateGUID(false)
    self.worldHeightToLayer = {}
    loadedMaps[self.id] = self
    return self
end

function Map.setBackground(self: Map , newBackground : Model?)
    self.background = newBackground
end

function Map.getBackground(self: Map)
    return self.background
end

function Map.get(id : string) : Map?
    return loadedMaps[id]
end

function Map.removeLayer(self : Map , layer : Layer) : nil
    -- Remove from layers array
    local idx = table.find(self.layers, layer)
    if idx then
        table.remove(self.layers, idx)
        self.count -= 1
    end
    
    -- Remove from worldHeightToLayer mapping
    local height = layer.originPosition.Y - self.originPosition.Y
    if self.worldHeightToLayer[height] == layer then
        self.worldHeightToLayer[height] = nil
    end
end

function Map.snapPositionToGrid(self: Map, worldPosition: Vector3): { layerIndex: number, layerPosition: Vector2 }
    local layer = self:getClosestLayerTo(worldPosition.Y)
    assert(layer, "[Map] snapPositionToGrid: No layer found")
    assert(layer.originPosition, "[Map] snapPositionToGrid: Layer missing originPosition")

    local tileSize = config.BLOCK_SIZE

    -- Calculate the corner where blocks start (block 1,1)
    -- The layer.originPosition is the center, blocks are offset by half the layer size
    local halfWidth = (layer.size.X - 1) * tileSize / 2
    local halfHeight = (layer.size.Y - 1) * tileSize / 2
    
    local cornerX = layer.originPosition.X - halfWidth
    local cornerZ = layer.originPosition.Z - halfHeight

    local localX = worldPosition.X - cornerX
    local localZ = worldPosition.Z - cornerZ

    -- Convert to grid coordinates (1-based)
    local gridX = math.floor(localX / tileSize) + 1
    local gridY = math.floor(localZ / tileSize) + 1

    -- Clamp to layer bounds
    gridX = math.clamp(gridX, 1, layer.size.X)
    gridY = math.clamp(gridY, 1, layer.size.Y)

    return {
        layerIndex = layer.layerIndex,
        layerPosition = Vector2.new(gridX, gridY),
    }
end

function Map.getClosestLayerTo(self: Map , worldHeight: number): Layer?
    local closestLayer: Layer? = nil
    local closestDist = math.huge

    for _, layer in self:getLayers() do
        local layerY = layer.originPosition.Y
        local d = math.abs(worldHeight - layerY)

        if d < closestDist then
            closestDist = d
            closestLayer = layer
        end
    end

    return closestLayer
end

function Map.addLayer(self: Map, layer: Layer): nil
    table.insert(self.layers, layer)
    if self.worldHeightToLayer[layer.originPosition.Y - self.originPosition.Y] then
        self.worldHeightToLayer[layer.originPosition.Y - self.originPosition.Y] = layer
        warn("OVerwriting existing layer at height " .. tostring(layer.originPosition.Y - self.originPosition.Y))
    else
        self.worldHeightToLayer[layer.originPosition.Y - self.originPosition.Y] = layer
    end
  
    self.count += 1
end

function Map.getLayerAtHeight(self : Map , height : number) : Layer?
   return self.worldHeightToLayer[height]
end

function Map.getLayers(self: Map) : {Layer}
    return self.layers
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
    -- Stop all block tweens (slow falling blocks) before destroying
    Block.stopAllTweens()
    
    -- Destroy background
    if self.background then
        self.background:Destroy()
        self.background = nil
    end
    
    -- Destroy all layers (making a copy to avoid mutation during iteration)
    local layersCopy = table.clone(self.layers)
    for _, layer in ipairs(layersCopy) do
        if layer then
            layer:destroy()
        end
    end
    
    -- Clear all references
    table.clear(self.layers)
    if self.worldHeightToLayer then
        table.clear(self.worldHeightToLayer)
    end
    
    -- Remove from registry
    loadedMaps[self.id] = nil
end

function Map.init()

    Block = require(ModuleDirectory.Systems.Map.Block)
    Layer = require(ModuleDirectory.Systems.Map.Layer)
    
end

return Map