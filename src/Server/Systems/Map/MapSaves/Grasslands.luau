export type Cell = {
	filled: "EMPTY" | "PLACE" | nil,
	Material: string,
}

local function makeCheckerTileMap(rows: number, cols: number, lightMat: string, darkMat: string, lightOn11: boolean): { { Cell } }
	local tileMap: { { Cell } } = table.create(rows)

	for r = 1, rows do
		local row: { Cell } = table.create(cols)

		for c = 1, cols do
			local isOdd = ((r + c) % 2) == 0 -- (1,1) => even => true
			local useLight = lightOn11 and isOdd or (not lightOn11 and not isOdd)

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
	background = "Grasslands",
	weatherName = "lobbyWeather",
	layerParams = {
		{
            shape = "SQUARE",
			height = 0,
			size = Vector2.new(GRID, GRID),
			spawnsAmmo = true,

			-- Combined from Checked_Odd (grass_light) + Checked_Even (grass)
			tileMap = makeCheckerTileMap(GRID, GRID, "grass_light", "grass", true),
		},
		{
            shape = "SQUARE",
			height = 30,
			size = Vector2.new(GRID, GRID),
			spawnsAmmo = true,

			tileMap = makeCheckerTileMap(GRID, GRID, "grass_light", "grass", true),
		},
		{
            shape = "SQUARE",
			height = 60,
			size = Vector2.new(GRID, GRID),
			spawnsAmmo = true,

			tileMap = makeCheckerTileMap(GRID, GRID, "grass_light", "grass", true),
		},
	},
}