local MapSaves = script.Parent

export type LayerParams = {
	height: number,
	size: Vector2,
	shape: "Circle" | "Square" | "OVERRIDE" | "Checked_Even" | "Checked_Odd",
	spawnsAmmo: boolean?,
	regenerates: boolean?,
	material: string,
	tileMap: { [number]: { [number]: string } }?,
}

export type MapSave = {
	weatherName : string,
	background: string,
	originPosition: Vector3?,
	layerParams: { LayerParams },
}

export type MapSaves = {
	Grasslands: MapSave,
	Desert: MapSave,
	Icefields: MapSave,
	Desert: MapSave,
}

export type PlaceInfo = {
	
}

local MapSaves = {
	Grasslands = require(MapSaves.Grasslands),
	Icefields = require(MapSaves.Icefields),
	Desert = require(MapSaves.Desert),
	Candy = require(MapSaves.Candy)
}

function MapSaves.getMap(mapName : string): MapSave?
	return MapSaves[mapName]
end

function MapSaves.getNames() : {string}
	return {"Grasslands", "Desert", "Icefields" ,}
end

function MapSaves.generateRandomChoices() : { [number]: string } -- choose 3 unique maps at index 1 , 2, 3
	local mapNames = MapSaves.getNames()
	local choices: { [number]: string } = {}

	-- If there are 3 or fewer maps, just shuffle and return them
	if #mapNames <= 3 then
		-- Fisher-Yates shuffle
		for i = #mapNames, 2, -1 do
			local j = math.random(1, i)
			mapNames[i], mapNames[j] = mapNames[j], mapNames[i]
		end

		for i = 1, #mapNames do
			choices[i] = mapNames[i]
		end
		return choices
	end

	-- Otherwise pick 3 unique at random (no repeats)
	local pool = table.clone(mapNames)

	for i = 1, 3 do
		local idx = math.random(1, #pool)
		choices[i] = pool[idx]
		table.remove(pool, idx) -- ensures uniqueness
	end

	return choices
end

function MapSaves.chooseRandom(excludes : {string}?) : (MapSave, string)
	excludes = excludes or {}
	
	-- Build list of available map names
	local available = {}
	local mapNames = {"Grasslands", "Desert", "Icefields"}
	
	for _, mapName in ipairs(mapNames) do
		local isExcluded = false
		for _, excludeName in ipairs(excludes) do
			if excludeName == mapName then
				isExcluded = true
				break
			end
		end
		if not isExcluded then
			table.insert(available, mapName)
		end
	end
	
	-- Choose random map
	if #available == 0 then
		error("No maps available to choose from")
	end
	
	local chosenName = available[math.random(1, #available)]
	return MapSaves[chosenName], chosenName
end


return MapSaves
