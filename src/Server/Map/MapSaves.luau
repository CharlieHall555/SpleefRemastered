local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local MapSaves = game:GetService("ServerScriptService").MapSaves

export type MapSaves = { [number]: MapDataFactory.MapDataCreationParams }

local MapSaves = {
	TestMap = require(MapSaves.TestMap)
}


return MapSaves
