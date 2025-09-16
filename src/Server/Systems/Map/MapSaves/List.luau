local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local MapSaves = script.Parent

export type MapSaves = { [number]: MapDataFactory.MapDataCreationParams }

local MapSaves = {
	Grasslands = require(MapSaves.Grasslands),
	Icefields = require(MapSaves.Icefields),
	Desert = require(MapSaves.Desert)
}


return MapSaves
