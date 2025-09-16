local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapSaves = require(ModuleDirectory.Map.Saves)

local mapNames: {string} = {}
local MapSelection = {}

local count = 0

function MapSelection.init()
	table.clear(mapNames)
	for mapName, _ in pairs(MapSaves) do
		table.insert(mapNames, mapName)
	end
	table.sort(mapNames)
	count = 0
end

function MapSelection.getNextMap()

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