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

return {
	background = "Desert",
	layerParams = {
		-- height 0 (combined)
		{
			height = 0,
			size = Vector2.new(35, 35),
			shape = "Override",
			spawnsAmmo = true,

			-- Combined: sandstone (light) + sand (dark)
			tileMap = makeCheckerTileMapFromSize(Vector2.new(35, 35), "sandstone", "sand", true),
		},

		-- height 30 (combined)
		{
			height = 30,
			size = Vector2.new(35, 35),
			shape = "Override",
			spawnsAmmo = true,

			tileMap = makeCheckerTileMapFromSize(Vector2.new(35, 35), "sandstone", "sand", true),
		},

		-- height 60 (combined)
		{
			height = 60,
			size = Vector2.new(35, 35),
			shape = "Override",
			spawnsAmmo = true,

			tileMap = makeCheckerTileMapFromSize(Vector2.new(35, 35), "sandstone", "sand", true),
		},
	},
}
