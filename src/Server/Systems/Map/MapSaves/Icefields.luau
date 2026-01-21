--!strict

export type Cell = {
	filled: "EMPTY" | "PLACE" | nil,
	Material: string,
}

local function makeCheckerTileMap(
	rows: number,
	cols: number,
	lightMat: string,
	darkMat: string,
	lightOn11: boolean
): { { Cell } }
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
	background = "Icefields",
	weatherName = "snowyWeather",
	layerParams = {
		{
			height = 0,
			size = Vector2.new(GRID, GRID),
			shape = "SQUARE",
			spawnsAmmo = true,

			-- start with ICE at (1,1)
			tileMap = makeCheckerTileMap(GRID, GRID, "ice", "snow", true),
		},
		{
			height = 30,
			size = Vector2.new(GRID, GRID),
			shape = "SQUARE",
			spawnsAmmo = true,

			-- flip the checker so it doesn't visually “line up” with layer 0
			tileMap = makeCheckerTileMap(GRID, GRID, "ice", "snow", false),
		},
		{
			height = 60,
			size = Vector2.new(GRID, GRID),
			shape = "SQUARE",
			spawnsAmmo = true,

			-- back to ICE at (1,1)
			tileMap = makeCheckerTileMap(GRID, GRID, "ice", "snow", true),
		},
	},
}
