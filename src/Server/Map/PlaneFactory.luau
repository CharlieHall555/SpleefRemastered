export type PlaceInfo = {
place: boolean
}

export type PlaneCreationParams = {
size: Vector2,
shape: "Circle" | "Square",
}

export type PlaneData = { [number]: { [number]: PlaceInfo } }

local PlaneFactory = {}
PlaneFactory.__index = PlaneFactory

function PlaneFactory.create(params: PlaneCreationParams): PlaneData
    local width = math.floor(params.size.X)
    local height = math.floor(params.size.Y)
    local shape = params.shape

    local PlanePlane: { [number]: { [number]: PlaceInfo } } = {}

    if shape == "Square" then
        for x = 1, width do
            PlanePlane[x] = {}
            for y = 1, height do
                PlanePlane[x][y] = { place = true }
            end
        end
    elseif shape == "Circle" then
        local cx = (width + 1) / 2
        local cy = (height + 1) / 2
        local radius = math.min(width, height) / 2

        for x = 1, width do
            PlanePlane[x] = {}
            for y = 1, height do
                local dx = x - cx
                local dy = y - cy
                local inside = (dx * dx + dy * dy) <= (radius * radius)
                PlanePlane[x][y] = { place = inside }
            end
        end
    else
        error(("PlaneGenerator.generatePlane: Unsupported shape %s"):format(tostring(shape)))
    end

    return PlanePlane
end

return PlaneFactory