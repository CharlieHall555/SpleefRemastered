local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local TeleportManager = require(ModuleDirectory.TeleportManager)
local PlayersInGame = require(ModuleDirectory.PlayersInGame) -- holds the "active players currently in game"
local Timer = require(ModuleDirectory.Timer)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local SuddenDeath = require(ModuleDirectory.SuddenDeath)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)
local currentMap = nil
local PlayerDeathDetector = require(ModuleDirectory.PlayerDeathDetector)
local WinnerDetection = require(ModuleDirectory.WinnerDetection)
local PlayerData = require(ModuleDirectory.PlayerData)

local PLayerManger = require(ModuleDirectory.PlayerManager)

local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local LobbySpawn

local testMapParams: MapDataFactory.MapDataCreationParams = {
	layerSeperation = 50, -- vertical distance between each layer
	originPosition = Vector3.new(0, 0, 0), -- world‐space origin of your bottom layer
	layerParams = { -- each entry is PlaneFactory.PlaneCreationParams
		{
			size = Vector2.new(20, 20), -- X×Y dimensions
			shape = "Circle",
		},
		{
			size = Vector2.new(26, 26),
			shape = "Circle",
		},
		{
			size = Vector2.new(35, 35),
			shape = "Circle",
		},
	},
}

-- then generate:

local SuddenDeathTimer = Timer.new()

local RoundManager = {}

function RoundManager.init(): nil

	TeleportManager.setCallback(function(playerWhoFailed)
		if RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "STARTING" then
			PlayersInGame.removePlayer(playerWhoFailed)
		end
	end)

	SuddenDeathTimer.EndCallback = function()
		SuddenDeath.start(currentMap)
		print("startSuddenDeath")
	end

	RoundSystem.connectStarting(function(currentRound : RoundSystem.Round)
		print(currentRound)
		currentMap = MapGenerator.generate(testMapParams)
		task.wait(1)
		RemoteEventHandler.FireOnClients(currentRound.startingPlayers , "CHANGE_STATE" , "ROUND_STARTING")

	end)

	RoundSystem.connectEnding(function(currentRound)
		SuddenDeathTimer:End()

		BlockFactory.stopAllTweens()
		local Winner = WinnerDetection.getWinner(currentRound.startingPlayers)
		print(Winner)
		PlayerData.incrementWins(Winner , 1)
		RemoteEventHandler.FireOnAllClients("PLAYER_WON" , Winner.DisplayName)
		TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), LobbySpawn.Position + Vector3.new(0 , 6 , 0))
		task.wait()
		currentMap:Destroy()
		PlayerDeathDetector.clearCache()
		
		task.wait(1)
	end)

	RoundSystem.connectIntermission(function()
	end)

	RoundSystem.connectActive(function(currentRound)
		RemoteEventHandler.FireOnClients(currentRound.startingPlayers , "CHANGE_STATE" , "ACTIVE")

		TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), Vector3.new(0, 150, 0))

		SuddenDeathTimer:Start(Config.ROUND_TIME)
	end)

	PlayerDeathDetector.setCallback(RoundManager.onPlayerDeath)

	LobbySpawn = game.Workspace:WaitForChild("SpawnLocation")

end


function RoundManager.onPlayerDeath(playerWhoDied : Player)

	RemoteEventHandler.FireOnClient(playerWhoDied , "CHANGE_STATE" , "INTERMISSION")
	RemoteEventHandler.FireOnAllClients("PLAYER_DIED" , playerWhoDied)


end




return RoundManager
