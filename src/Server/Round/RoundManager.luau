local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local TeleportManager = require(ModuleDirectory.TeleportManager)
local PlayersInGame = require(ModuleDirectory.PlayersInGame) -- holds the "active players currently in game"

local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)

local currentMap = nil

local testMapParams: MapDataFactory.MapDataCreationParams = {
	layerSeperation = 50, -- vertical distance between each layer
	originPosition = Vector3.new(0, 0, 0), -- world‐space origin of your bottom layer
	layerParams = { -- each entry is PlaneFactory.PlaneCreationParams
		{
			size = Vector2.new(20, 20), -- X×Y dimensions
			shape = "Square",
		},
		{
			size = Vector2.new(16, 16),
			shape = "Circle",
		},
		{
			size = Vector2.new(12, 12),
			shape = "Square",
		},
	},
}

-- then generate:

local RoundManager = {}

function RoundManager.init(): nil
	TeleportManager.setCallback(function(playerWhoFailed)
		if RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "STARTING" then
			PlayersInGame.removePlayer(playerWhoFailed)
		end
	end)

	RoundSystem.connectStarting(function()
		
		currentMap = MapGenerator.generate(testMapParams)
		task.wait(1)

	end)

	RoundSystem.connectEnding(function()
		TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), Vector3.new(100,0, 0))
		task.wait()
		currentMap:Destroy()
		task.wait(1)
	end)

	RoundSystem.connectIntermission(function()
	end)


	RoundSystem.connectActive(function()
		TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), Vector3.new(0, 150, 0))
	end)
end



return RoundManager
