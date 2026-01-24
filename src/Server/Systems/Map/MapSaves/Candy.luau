--!strict

export type Cell = {
	filled: "EMPTY" | "PLACE" | nil,
	Material: string,
}

local function makeCheckerTileMapFromSize(
	size: Vector2,
	lightMat: string,
	darkMat: string,
	lightOn11: boolean
): { { Cell } }
	local rows = math.floor(size.Y)
	local cols = math.floor(size.X)

	local tileMap: { { Cell } } = table.create(rows)

	for r = 1, rows do
		local row: { Cell } = table.create(cols)

		for c = 1, cols do
			-- (1,1) => (r+c)=2 => even => true
			local parityEven = ((r + c) % 2) == 0
			local useLight = if lightOn11 then parityEven else (not parityEven)

			row[c] = {
				filled = "PLACE",
				Material = if useLight then lightMat else darkMat,
			}
		end

		tileMap[r] = row
	end

	return tileMap
end

local GRID = 30

return {
	background = "Desert",
	weatherName = "lobbyWeather",
	layerParams = {
		-- height 0 (combined)
		{
			height = 0,
			size = Vector2.new(GRID, GRID),
			shape = "SQUARE",
			spawnsCollectables = true,

			-- Combined: sandstone (light) + sand (dark)
			tileMap = makeCheckerTileMapFromSize(Vector2.new(GRID, GRID), "dark_candy", "light_candy", true),
		},

		-- height 30 (combined)
		{
			height = 30,
			size = Vector2.new(GRID, GRID),
			shape = "SQUARE",
			spawnsCollectables = true,

			tileMap = makeCheckerTileMapFromSize(Vector2.new(GRID, GRID), "light_candy", "dark_candy", true),
		},

		-- height 60 (combined)
		{
			height = 60,
			size = Vector2.new(GRID, GRID),
			shape = "SQUARE",
			spawnsCollectables = true,

			tileMap = makeCheckerTileMapFromSize(Vector2.new(GRID, GRID), "dark_candy", "light_candy", true),
		},
	},
}
