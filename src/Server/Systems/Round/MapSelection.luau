local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapSaves = require(ModuleDirectory.Systems.Map.MapSaves)

local mapNames: {string} = {}
local MapSelection = {}

local count = 0

function MapSelection.init()
	mapNames = table.clone(MapSaves.getNames())
end

function MapSelection.getNextMap() : string

	if #mapNames == 0 then
		warn("[MapSelection] No maps available in MapSaves.")
		return nil
	end

	count += 1
	if count > #mapNames then
		count = 1
	end

	local name = mapNames[count]

	return name or ("Grasslands")
end

return MapSelection