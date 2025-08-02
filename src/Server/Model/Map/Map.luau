local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Grid = require(ModuleDirectory.Map.Grid)

export type Map = {
    OriginPosition: Vector3,
    Grids: { Grid.Grid },
    Count: number,

    new: (originPosition: Vector3) -> Map,
    addGrid: (self: Map, grid: Grid.Grid ) -> nil,
    getTopGrid: (self: Map) -> Grid.Grid ?
}

local Map = {}
Map.__index = Map

function Map.new(originPosition: Vector3): Map
    local self = setmetatable({}, Map)
    self.OriginPosition = originPosition
    self.Grids = {}
    self.Count = 0
    return self
end

function Map:addGrid(grid: Grid.Grid): nil
    table.insert(self.Grids, grid)
    self.Count += 1
end

function Map:getTopGrid(): Grid.Grid ?
    for i = #self.Grids, 1, -1 do
        local grid = self.Grids[i]
        if not grid:isEmpty() then
            return grid
        end
    end
    return nil
end

return Map