export type PlaceInfo = {
    place: boolean
}

export type Cell = "PLACE" | "EMPTY"

export type PlaneCreationParams = {
    size: Vector2,
    shape: "Circle" | "Square" | "Override" | "Checked_Even" | "Checked_Odd",
    tileMap: ({ [number]: { [number]: Cell } })?,
}

export type PlaneData = { [number]: { [number]: PlaceInfo } }

local PlaneGenerator = {}
PlaneGenerator.__index = PlaneGenerator

function PlaneGenerator.create(params: PlaneCreationParams): PlaneData
    local width = math.floor(params.size.X)
    local height = math.floor(params.size.Y)
    local shape = params.shape

    local planeGrid: PlaneData = {}

    if shape == "Square" then
        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                planeGrid[x][y] = { place = true }
            end
        end

    elseif shape == "Circle" then
        local cx = (width + 1) / 2
        local cy = (height + 1) / 2
        local radius = math.min(width, height) / 2

        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local dx = x - cx
                local dy = y - cy
                local inside = (dx * dx + dy * dy) <= (radius * radius)
                planeGrid[x][y] = { place = inside }
            end
        end

    elseif shape == "Override" then
        local tileMap = params.tileMap
        if not tileMap then
            error("PlaneFactory.create: shape 'Override' requires params.tileMap")
        end

        -- Build from tileMap, ignoring size if dimensions differ
        for x, col in pairs(tileMap) do
            planeGrid[x] = {}
            for y, tile in pairs(col) do
                planeGrid[x][y] = { place = (tile == "PLACE") }
            end
        end

    elseif shape == "Checked_Even" then
        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local isEven = ((x + y) % 2) == 0
                planeGrid[x][y] = { place = isEven }
            end
        end

    elseif shape == "Checked_Odd" then
        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local isOdd = ((x + y) % 2) == 1
                planeGrid[x][y] = { place = isOdd }
            end
        end

    else
        error(("PlaneFactory.create: Unsupported shape %s"):format(tostring(shape)))
    end

    return planeGrid
end

return PlaneGenerator