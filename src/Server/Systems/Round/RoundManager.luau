local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local TeleportManager = require(ModuleDirectory.Systems.Round.TeleportManager)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local Timer = require(ModuleDirectory.Timer)
local MapGenerator = require(ModuleDirectory.Systems.Map.MapGenerator)
local MapDataFactory = require(ModuleDirectory.Systems.Map.MapDataFactory)
local SuddenDeath = require(ModuleDirectory.Systems.Round.SuddenDeath)
local BlockFactory = require(ModuleDirectory.Systems.Map.BlockFactory)
local currentMap = nil
local PlayerDeathDetector = require(ModuleDirectory.Systems.Round.PlayerDeathDetector)
local WinnerDetection = require(ModuleDirectory.Systems.Stats.WinnerDetection)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local Leaderstats = require(ModuleDirectory.Player.Leaderstats)
local AmmoManager = require(ModuleDirectory.Systems.Ammo.AmmoManager)
local AmmoPickupManager = require(ModuleDirectory.Systems.Ammo.AmmoPickupManager)
local ToolManager = require(ModuleDirectory.Systems.Tool.ToolManager)
local PLayerManger = require(ModuleDirectory.Player.PlayerManager)
local MapSaves = require(ModuleDirectory.Systems.Map.Saves)
local Onboarding = require(ModuleDirectory.Services.Analytics.Onboarding)
local ServerStatus = require(ModuleDirectory.ServerStatus)
local MapSelection = require(ModuleDirectory.Systems.Round.MapSelection)
local BlockDestructionTracker = require(ModuleDirectory.Systems.Gameplay.BlockDestructionTracker)
local ClearLobby = require(ModuleDirectory.Systems.Round.ClearLobby)
local WinBadgeHandler = require(ModuleDirectory.Services.Badges.WinBadgeHandler)
local KnockbackTracker = require(ModuleDirectory.Systems.Stats.KnockbackTracker)
local EliminationTracker = require(ModuleDirectory.Systems.Stats.EliminationTracker)
local RoundSummary = require(ModuleDirectory.Systems.Stats.RoundSummary)
local LevelController = require(ModuleDirectory.LevelSystem.LevelController)
local LeaderboardUpdater = require(ModuleDirectory.Services.Analytics.LeaderboardUpdater)
local RespawnManager = require(ModuleDirectory.Systems.Gameplay.RespawnManager)
local PodiumManager = require(ModuleDirectory.Systems.Round.PodiumManager)
local CoinPickupManager = require(ModuleDirectory.Coins.CoinPickupManager)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local Overhead = require(ModuleDirectory.Overhead)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local TutorialManager = require(ModuleDirectory.Systems.Tutorial.TutorialManager)
local AgentManager = require(ModuleDirectory.Systems.Agent.AgentManager)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)
local MapUtilities = require(ModuleDirectory.Systems.Map.MapUtilities)

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
	AmmoManager.setInfinite(true)
	RemoteEventHandler.FireOnAllClients("START_SUDDEN_DEATH")
end

local function onRoundStarting(currentRound: RoundSystem.Round) --realy wierd this fires first 


	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "ROUND_STARTING")
	currentMap = MapGenerator.generate(MapSaves[MapSelection.getNextMap()])
	print("MapSpawn: @" .. VectorUtil.SerializeVector3(currentMap.originPosition))
	task.wait(1)

	for _, each in currentRound.startingPlayers do
		Onboarding.action(each, "JOINED_ROUND")
	end

	TileScoring.setCurrentMap(currentMap)
	MapUtilities.setCurrentMap(currentMap)


	AgentManager.spawnNAgentsOnMap(currentMap, 1)

	TileScoring.start()

end


local function onRoundPreparing(currentRound) -- and then this
	RemoteEventHandler.FireOnClients(
		PlayersInGame.getActivePlayers(),
		"SEND_STARTING_PLAYERS",
		currentRound.startingPlayers
	)
	AmmoManager.setUp(PlayersInGame.getActivePlayers())
	RespawnManager.setMap(currentMap)
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

	AgentManager.activateAgents()



end

local function onRoundEnding(currentRound)
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "INTERMISSION")
	SuddenDeathTimer:End()
	--ToolManager.reset()
	AmmoPickupManager.stop()
	TileScoring.stop()

	AmmoManager.reset()
	RespawnManager.onRoundEnd()
	RespawnManager.setMap(nil)
	BlockFactory.stopAllTweens()
	local Winner
	if ServerStatus.get() == "OK" then
		Winner = WinnerDetection.getWinner(currentRound.startingPlayers)
		Onboarding.action(Winner, "WON")
		if Winner then
			--pcall(PodiumManager.setChar , Winner)
			PlayerData.incrementWins(Winner, 1)
			LeaderboardUpdater.incrementWins(Winner.UserId, 1)
			local totalWins = PlayerData.getWins(Winner)
			Leaderstats.updateStat(Winner, "Wins", totalWins)
			WinBadgeHandler.playerAwardedWin(Winner, totalWins)
			Overhead.refreshForPlayer(Winner)
			RemoteEventHandler.FireOnAllClients("PLAYER_WON", Winner.DisplayName, Winner)
		else
			PodiumManager.clear()
			print("No winner")
		end
	end

	RoundSummary.onRoundEnd(currentRound, Winner)
	CoinPickupManager.stop()
	KnockbackTracker.reset()
	EliminationTracker.reset()
	BlockDestructionTracker.reset()
	TeleportManager.teleportPlayers(PlayersInGame.getActivePlayers(), LobbySpawn.Position + Vector3.new(0, 6, 0))
	task.wait()
	currentMap:Destroy()
	PlayerDeathDetector.clearCache()

	task.wait(1)
end

local function onRoundIntermission(currentRound) end

function RoundManager.getCurrentMap(): {}?
	return currentMap
end

local function onRoundActive(currentRound)
	--ToolManager.giveTools(PlayersInGame.getActivePlayers())
	SuddenDeathTimer:Start(Config.ROUND_TIME)
	AmmoPickupManager.start(currentMap)
	CoinPickupManager.start(currentMap)
	ClearLobby.clear()
end

function RoundManager.init(): nil
	TeleportManager.setCallback(onTeleportFail)
	SuddenDeathTimer.StepCallback = function(currentT)
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

	RemoteEventHandler.newEventConnection("QUERY_SERVER_STATE", function(player)
		return RoundSystem.getState()
	end)
end

function RoundManager.onPlayerDeath(playerWhoDied: Player, wasAlive: boolean)
	if SessionVariables.getValue(playerWhoDied, "inTutorial") == true then

		local tutorailMap = TutorialManager.getTutorialMap(playerWhoDied)
		print(tutorailMap)
		if tutorailMap and tutorailMap.originPosition then
			local TELEPORT_OFFSET = Vector3.new(0, 50, 0)
			task.spawn(function()
				task.wait(1)
				if SessionVariables.getValue(playerWhoDied, "inTutorial") == true then
					TeleportManager.teleport(playerWhoDied, tutorailMap.originPosition + TELEPORT_OFFSET, true)
				end
			end)
		end
	else
		RemoteEventHandler.FireOnClient(playerWhoDied, "CHANGE_STATE", "INTERMISSION")
		local Eliminator = EliminationTracker.getEliminator(playerWhoDied)

		if wasAlive then
			RemoteEventHandler.FireOnAllClients("PLAYER_DIED", playerWhoDied, Eliminator)
		end

		if Eliminator then
			RemoteEventHandler.FireOnClient(Eliminator, "ELIMINATION", playerWhoDied)
		end
	end
end

return RoundManager
