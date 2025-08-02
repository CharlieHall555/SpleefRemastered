export type PlaceInfo = {
place: boolean
}

export type MapCreationParams = {
size: Vector2,
shape: "Circle" | "Square",
}

local MapGenerator = {}
MapGenerator.__index = MapGenerator

function MapGenerator.generatePlane(params: MapCreationParams): { [number]: { [number]: PlaceInfo } }
    local width = math.floor(params.size.X)
    local height = math.floor(params.size.Y)
    local shape = params.shape

    local mapPlane: { [number]: { [number]: PlaceInfo } } = {}

    if shape == "Square" then
        for x = 1, width do
            mapPlane[x] = {}
            for y = 1, height do
                mapPlane[x][y] = { place = true }
            end
        end
    elseif shape == "Circle" then
        local cx = (width + 1) / 2
        local cy = (height + 1) / 2
        local radius = math.min(width, height) / 2

        for x = 1, width do
            mapPlane[x] = {}
            for y = 1, height do
                local dx = x - cx
                local dy = y - cy
                local inside = (dx * dx + dy * dy) <= (radius * radius)
                mapPlane[x][y] = { place = inside }
            end
        end
    else
        error(("MapGenerator.generatePlane: Unsupported shape %s"):format(tostring(shape)))
    end

    return mapPlane
end

return MapGenerator