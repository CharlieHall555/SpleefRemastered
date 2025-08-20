local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local Timer = require(ModuleDirectory.Timer)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local SuddenDeath = require(ModuleDirectory.Round.SuddenDeath)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)
local currentMap = nil
local PlayerDeathDetector = require(ModuleDirectory.Round.PlayerDeathDetector)
local WinnerDetection = require(ModuleDirectory.Round.WinnerDetection)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local Leaderstats = require(ModuleDirectory.Player.Leaderstats)
local AmmoManager = require(ModuleDirectory.Throwable.AmmoManager)
local AmmoPickupManager = require(ModuleDirectory.Gameplay.AmmoPickupManager)
local ToolManager = require(ModuleDirectory.Gameplay.ToolManager)
local PLayerManger = require(ModuleDirectory.Player.PlayerManager)
local MapSaves = require(ModuleDirectory.Map.Saves)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local ServerStatus = require(ModuleDirectory.ServerStatus)
local MapSelection = require(ModuleDirectory.Round.MapSelection)

local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local LobbySpawn

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
end

local function onRoundStarting(currentRound: RoundSystem.Round)
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "ROUND_STARTING")
	currentMap = MapGenerator.generate(MapSaves[MapSelection.getNextMap()])
	task.wait(1)

	for _, each in currentRound.startingPlayers do
		Onboarding.action(each, "JOINED_ROUND")
	end
end

local function onRoundPreparing(currentRound)
	RemoteEventHandler.FireOnClients(PlayersInGame.getActivePlayers(), "SEND_STARTING_PLAYERS", currentRound.startingPlayers)
	AmmoManager.setUp(PlayersInGame.getActivePlayers())
	AmmoManager.startRegenLoop()
	RemoteEventHandler.FireOnClients(PlayersInGame.getActivePlayers(), "CHANGE_STATE", "ACTIVE")

	for _, eachPlayer in PlayersInGame.getActivePlayers() do
		local topLayer = currentMap:getTopLayer()
		local randomBlock = topLayer:getRandomBlock()
		local Position = Vector3.new(0, 150, 0)
		if randomBlock then
			Position = randomBlock.Part.Position + Vector3.new(0, 15, 0)
		end
		TeleportManager.teleport(eachPlayer, Position)
	end
end

local function onRoundEnding(currentRound)
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "INTERMISSION")
	SuddenDeathTimer:End()
	ToolManager.reset()
	AmmoPickupManager.cleanup()
	AmmoManager.reset()
	BlockFactory.stopAllTweens()
	if ServerStatus.get() == "OK" then
		local Winner = WinnerDetection.getWinner(currentRound.startingPlayers)
		Onboarding.action(Winner, "WON")
		if Winner then
			PlayerData.incrementWins(Winner, 1)
			Leaderstats.updateStat(Winner, "Wins", PlayerData.getWins(Winner))
			RemoteEventHandler.FireOnAllClients("PLAYER_WON", Winner.DisplayName)
		else
			print("No winner")
		end
	end

	TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), LobbySpawn.Position + Vector3.new(0, 6, 0))
	task.wait()
	currentMap:Destroy()
	PlayerDeathDetector.clearCache()
	task.wait(1)
end

local function onRoundIntermission(currentRound)
end

function RoundManager.getCurrentMap(): {}?
	return currentMap
end

local function onRoundActive(currentRound)
	ToolManager.giveTools(PlayersInGame.getActivePlayers())
	SuddenDeathTimer:Start(Config.ROUND_TIME)
	AmmoPickupManager.start(currentMap)
end

function RoundManager.init(): nil
	TeleportManager.setCallback(onTeleportFail)
	SuddenDeathTimer.Callback = function(currentT)
		RemoteEventHandler.FireOnAllClients("SUDDEN_DEATH_TIMER_CHANGED", currentT)
	end
	SuddenDeathTimer.EndCallback = onSuddenDeathTimerEnd
	RoundSystem.connectStarting(onRoundStarting)
	RoundSystem.connectPreparing(onRoundPreparing)
	RoundSystem.connectEnding(onRoundEnding)
	RoundSystem.connectIntermission(onRoundIntermission)
	RoundSystem.connectActive(onRoundActive)
	PlayerDeathDetector.setCallback(RoundManager.onPlayerDeath)
	LobbySpawn = game.Workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation")
end

function RoundManager.onPlayerDeath(playerWhoDied: Player)
	RemoteEventHandler.FireOnClient(playerWhoDied, "CHANGE_STATE", "INTERMISSION")
	RemoteEventHandler.FireOnAllClients("PLAYER_DIED", playerWhoDied)
end

return RoundManager
