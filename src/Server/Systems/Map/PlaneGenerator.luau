export type PlaceInfo = {
    place: boolean,
    material: string?
}

export type Cell = {filled : "EMPTY | PLACE" , Material : string}

export type PlaneCreationParams = {
    size: Vector2,
    shape: "Circle" | "Square" | "OVERRIDE" | "Checked_Even" | "Checked_Odd",
    tileMap: ({ [number]: { [number]: Cell } })?,
}

export type PlaneData = { [number]: { [number]: PlaceInfo } }

local PlaneGenerator = {}
PlaneGenerator.__index = PlaneGenerator

local function getCell(params : PlaneCreationParams, x : number , y : number) : Cell?
    if not params.tileMap then
        return nil
    end
    
    if params.tileMap[x] then
        return params.tileMap[x][y]
    end
    
    return nil
end

function PlaneGenerator.create(params: PlaneCreationParams): PlaneData
    local width = math.floor(params.size.X)
    local height = math.floor(params.size.Y)
    local shape = params.shape

    local planeGrid: PlaneData = {}

    if shape == "SQUARE" then
        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local cell = getCell(params, x, y)
                planeGrid[x][y] = { place = true, material = cell and cell.Material or nil }
            end
        end

    elseif shape == "CIRCLE" then
        local cx = (width + 1) / 2
        local cy = (height + 1) / 2
        local radius = math.min(width, height) / 2

        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local dx = x - cx
                local dy = y - cy
                local inside = (dx * dx + dy * dy) <= (radius * radius)
                local cell = getCell(params, x, y)
                planeGrid[x][y] = { place = inside, material = cell and cell.Material or nil }
            end
        end

    elseif shape == "TILEMAP" then
        local tileMap = params.tileMap
        if not tileMap then
            error("PlaneFactory.create: shape 'OVERRIDE' requires params.tileMap")
        end

        -- Build from tileMap, ignoring size if dimensions differ
        for x, col in pairs(tileMap) do
            planeGrid[x] = {}
            for y, cell in pairs(col) do
                planeGrid[x][y] = { place = (cell.filled == "PLACE"), material = cell.Material }
            end
        end

    elseif shape == "CHECKED_EVEN" then
        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local isEven = ((x + y) % 2) == 0
                local cell = getCell(params, x, y)
                planeGrid[x][y] = { place = isEven, material = cell and cell.Material or nil }
            end
        end

    elseif shape == "CHECKED_ODD" then
        for x = 1, width do
            planeGrid[x] = {}
            for y = 1, height do
                local isOdd = ((x + y) % 2) == 1
                local cell = getCell(params, x, y)
                planeGrid[x][y] = { place = isOdd, material = cell and cell.Material or nil }
            end
        end

    else
        error(("PlaneFactory.create: Unsupported shape %s"):format(tostring(shape)))
    end

    return planeGrid
end

return PlaneGenerator