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
	Desert = require(MapSaves.Desert)
}

function MapSaves.getMap(mapName : string): MapSave?
	return MapSaves[mapName]
end

function MapSaves.getNames() : {string}
	return {"Grasslands", "Desert", "Icefields"}
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
