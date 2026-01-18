local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local TeleportManager = require(ModuleDirectory.Systems.Round.TeleportManager)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local Timer = require(ModuleDirectory.Timer)
local MapGenerator = require(ModuleDirectory.Systems.Map.MapGenerator)
local MapSaves = require(ModuleDirectory.Systems.Map.MapSaves)
local SuddenDeath = require(ModuleDirectory.Systems.Round.SuddenDeath)
local Block = require(ModuleDirectory.Systems.Map.Block)
local currentMap = nil
local PlayerDeathDetector = require(ModuleDirectory.Systems.Round.PlayerDeathDetector)
local WinnerDetection = require(ModuleDirectory.Systems.Stats.WinnerDetection)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local Leaderstats = require(ModuleDirectory.Player.Leaderstats)
local AmmoManager = require(ModuleDirectory.Systems.Ammo.AmmoManager)
local AmmoPickupManager = require(ModuleDirectory.Systems.Ammo.AmmoPickupManager)
local ToolManager = require(ModuleDirectory.Systems.Tool.ToolManager)
local PLayerManger = require(ModuleDirectory.Player.PlayerManager)
local Onboarding = require(ModuleDirectory.Services.Analytics.Onboarding)
local ServerStatus = require(ModuleDirectory.ServerStatus)
local MapSelection = require(ModuleDirectory.Systems.Round.MapSelection)
local BlockDestructionTracker = require(ModuleDirectory.Systems.Map.BlockDestructionTracker)
local ClearLobby = require(ModuleDirectory.Systems.Round.ClearLobby)
local WinBadgeHandler = require(ModuleDirectory.Services.Badges.WinBadgeHandler)
local KnockbackTracker = require(ModuleDirectory.Systems.Stats.KnockbackTracker)
local EliminationTracker = require(ModuleDirectory.Systems.Stats.EliminationTracker)
local RoundSummary = require(ModuleDirectory.Systems.Stats.RoundSummary)
local LevelController = require(ModuleDirectory.LevelSystem.LevelController)
local LeaderboardUpdater = require(ModuleDirectory.Services.Analytics.LeaderboardUpdater)
local RespawnManager = require(ModuleDirectory.Systems.Gameplay.RespawnManager)
local PodiumManager = require(ModuleDirectory.Systems.Round.PodiumManager)
local CoinPickupManager = require(ModuleDirectory.Systems.Coins.CoinPickupManager)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local Overhead = require(ModuleDirectory.Overhead)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local TutorialManager = require(ModuleDirectory.Systems.Tutorial.TutorialManager)
local AgentManager = require(ModuleDirectory.Systems.Agent.AgentManager)
local TileScoring = require(ModuleDirectory.Systems.Agent.TileScoring)

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
	local nextMapData = MapSaves.getMap(MapSelection.getNextMap())
	currentMap = MapGenerator.generate(nextMapData)
	print("CurrentMap" , currentMap)
	print("MapSpawn: @" .. VectorUtil.SerializeVector3(currentMap.originPosition))
	task.wait(1)

	for _, each in currentRound.startingPlayers do
		Onboarding.action(each, "JOINED_ROUND")
	end

	TileScoring.setCurrentMap(currentMap)

	if Config.BOTS_ACTIVE then
		local agentsToFill = Config.TARGET_PLAYER_COUNT - #currentRound.startingPlayers
		if agentsToFill > 0 then
			AgentManager.createAgentsFor(currentMap, agentsToFill)

		end
	end

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
		if not topLayer then
			warn("[RoundManager] Failed to get top layer for player teleport:", eachPlayer.Name)
			continue
		end
		
		local randomBlock = topLayer:getRandomBlock()
		local Position = Vector3.new(0, 150, 0)
		if randomBlock then
			Position = randomBlock:getWorldPosition() + Vector3.new(0, 15, 0)
		else
			warn("[RoundManager] No random block available for player:", eachPlayer.Name)
		end
		TeleportManager.teleport(eachPlayer, Position)
	end

	AgentManager.activateAgents()
	AgentManager.sendAgentModels(PlayersInGame.getActivePlayers())



end

local function onRoundEnding(currentRound)
	RemoteEventHandler.FireOnClients(currentRound.startingPlayers, "CHANGE_STATE", "INTERMISSION")
	SuddenDeathTimer:End()
	AmmoPickupManager.stop()
	TileScoring.stop()

	AmmoManager.reset()
	RespawnManager.onRoundEnd()
	RespawnManager.setMap(nil)
	Block.stopAllTweens()
	local Winner
	if ServerStatus.get() == "OK" then
		Winner = WinnerDetection.getWinner(currentRound.startingPlayers)
		if Winner then
			Onboarding.action(Winner, "WON")
			--pcall(PodiumManager.setChar , Winner)
			
			local success, err = pcall(function()
				PlayerData.incrementWins(Winner, 1)
				LeaderboardUpdater.incrementWins(Winner.UserId, 1)
			end)
			if not success then
				warn("[RoundManager] Failed to increment wins for winner:", Winner.Name, "Error:", err)
			end
			
			local totalWins = PlayerData.getWins(Winner)
			Leaderstats.updateStat(Winner, "Wins", totalWins)
			WinBadgeHandler.playerAwardedWin(Winner, totalWins)
			Overhead.refreshForPlayer(Winner)
			RemoteEventHandler.FireOnAllClients("PLAYER_WON", Winner.DisplayName, Winner)
		else
			RemoteEventHandler.FireOnAllClients("PLAYER_WON", nil , nil)
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
	
	local success, err = pcall(function()
		currentMap:destroy()
	end)
	if not success then
		warn("[RoundManager] Failed to destroy map:", err)
	end
	
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
	
	local success, err = pcall(function()
		ClearLobby.clear()
	end)
	if not success then
		warn("[RoundManager] Failed to clear lobby:", err)
	end
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
	AgentManager.setOnAgentDeath(RoundManager.onAgentDeath)
	
	LobbySpawn = game.Workspace:WaitForChild("Lobby", 10)
	if not LobbySpawn then
		warn("[RoundManager] Failed to find Lobby in Workspace")
		return
	end
	
	LobbySpawn = LobbySpawn:WaitForChild("SpawnLocation", 10)
	if not LobbySpawn then
		warn("[RoundManager] Failed to find SpawnLocation in Lobby")
		return
	end

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

function RoundManager.onAgentDeath(agentWhoDied)
	local Eliminator = nil
	RemoteEventHandler.FireOnAllClients("AGENT_DIED", agentWhoDied, Eliminator)
end

return RoundManager
