local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local TeleportManager = require(ModuleDirectory.TeleportManager)
local PlayersInGame = require(ModuleDirectory.PlayersInGame)
local Timer = require(ModuleDirectory.Timer)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local SuddenDeath = require(ModuleDirectory.SuddenDeath)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)
local currentMap = nil
local PlayerDeathDetector = require(ModuleDirectory.PlayerDeathDetector)
local WinnerDetection = require(ModuleDirectory.WinnerDetection)
local PlayerData = require(ModuleDirectory.PlayerData)
local Leaderstats = require(ModuleDirectory.Leaderstats)
local AmmoManager = require(ModuleDirectory.AmmoManager)

local PLayerManger = require(ModuleDirectory.PlayerManager)

local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local LobbySpawn

local testMapParams: MapDataFactory.MapDataCreationParams = {
	layerSeperation = 50,
	originPosition = Vector3.new(0, 0, 0),
	layerParams = {
		{
			size = Vector2.new(20, 20),
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

local SuddenDeathTimer = Timer.new()

local RoundManager = {}

local function onTeleportFail(playerWhoFailed)
	if RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "STARTING" then
		PlayersInGame.removePlayer(playerWhoFailed)
	end
end

local function onSuddenDeathTimerEnd()
	SuddenDeath.start(currentMap)
	RemoteEventHandler.FireOnAllClients("START_SUDDEN_DEATH")
	print("startSuddenDeath")
end

local function onRoundStarting(currentRound: RoundSystem.Round)
	print(currentRound)
	currentMap = MapGenerator.generate(testMapParams)
	task.wait(1)
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "ROUND_STARTING")
end

local function onRoundPreparing(currentRound)
	AmmoManager.setUp(PlayersInGame.getActivePlayers())
	TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), Vector3.new(0, 150, 0))
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "ACTIVE")
end

local function onRoundEnding(currentRound)
	SuddenDeathTimer:End()
	AmmoManager.reset()
	BlockFactory.stopAllTweens()
	local Winner = WinnerDetection.getWinner(currentRound.startingPlayers)
	print(Winner)
	if Winner then
		PlayerData.incrementWins(Winner, 1)
		print(PlayerData.getWins(Winner))
		Leaderstats.updateStat(Winner, "Wins", PlayerData.getWins(Winner))
		RemoteEventHandler.FireOnAllClients("PLAYER_WON", Winner.DisplayName)
	else
		print("No winner")
	end
	TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), LobbySpawn.Position + Vector3.new(0, 6, 0))
	task.wait()
	currentMap:Destroy()
	PlayerDeathDetector.clearCache()
	task.wait(1)
end

local function onRoundIntermission(currentRound)
	print("hi!")
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "INTERMISSION")
end

local function onRoundActive(currentRound)
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "HIGHLIGHT_PLAYERS", currentRound.startingPlayers)
	SuddenDeathTimer:Start(Config.ROUND_TIME)
end

function RoundManager.init(): nil
	TeleportManager.setCallback(onTeleportFail)
	SuddenDeathTimer.Callback = function(currentT)
		RemoteEventHandler.FireOnAllClients("SUDDEN_DEATH_TIMER_CHANGED" , currentT)
	end
	SuddenDeathTimer.EndCallback = onSuddenDeathTimerEnd
	RoundSystem.connectStarting(onRoundStarting)
	RoundSystem.connectPreparing(onRoundPreparing)
	RoundSystem.connectEnding(onRoundEnding)
	RoundSystem.connectIntermission(onRoundIntermission)
	RoundSystem.connectActive(onRoundActive)
	PlayerDeathDetector.setCallback(RoundManager.onPlayerDeath)
	LobbySpawn = game.Workspace:WaitForChild("SpawnLocation")
end

function RoundManager.onPlayerDeath(playerWhoDied: Player)
	RemoteEventHandler.FireOnClient(playerWhoDied, "CHANGE_STATE", "INTERMISSION")
	RemoteEventHandler.FireOnAllClients("PLAYER_DIED", playerWhoDied)
end

return RoundManager
