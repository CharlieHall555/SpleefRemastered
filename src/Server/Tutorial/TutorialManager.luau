local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local TutorialMap = require(game:GetService("ServerScriptService").MapSaves.TutorialMap)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local PlayerPool = require(ModuleDirectory.Round.PlayerPool)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Map = require(ModuleDirectory.Map.Map)

local playersInTutorial = {}

local TutorialManager = {}

local tutroialMap: Map.Map?
local lobbySpawn

function TutorialManager.isPlayerInTutorial(player: Player)
	return playersInTutorial[player.UserId]
end

function TutorialManager.getMapTeleportPoint(): Vector3
	local s, r = pcall(function()
		return tutroialMap.OriginPosition + Vector3.new(0, 80, 0)
	end)
	if s then
		return r
	else
		return Vector3.new(0, 0, 0)
	end
end

function TutorialManager.init()
	lobbySpawn = game.Workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation")
	tutroialMap = MapGenerator.generate(TutorialMap)

	ServerHitBoxManager.setUpCallback("TestLava", function(player, otherPart)
		if player.Character then
			TeleportManager.teleport(player, tutroialMap.OriginPosition + Vector3.new(0, 80, 0))
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		playersInTutorial[player.UserId] = nil
	end)

	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
		wait(1)
		print("hi")
		TutorialManager.playerEnterTutorialArea(player)
	end)

	PlayerPool.connectOnAdded(function(player)
		if TutorialManager.isPlayerInTutorial(player) then
			TutorialManager.playerEnterTutorialArea(player)
		end
	end)
end

function TutorialManager.playerLeaveTutorialArea(player: Player)
	playersInTutorial[player.UserId] = nil
	if player.Character and lobbySpawn then
        RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "INTERMISSION")
		TeleportManager.teleport(player, lobbySpawn.Position + Vector3.new(0, 6, 0))
	end
end

function TutorialManager.playerEnterTutorialArea(player: Player)
	if tutroialMap == nil then
		RemoteEventHandler.FireOnClient(
			player,
			"RECEIVE_SYSTEM_MESSAGE",
			"Cannot enter tutorial area: something went wrong."
		)
		return
	end

	if PlayersInGame.isAlive(player) then
		RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", "Cannot enter tutorial area while in game")
		return
	end

    RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "TUTORIAL")
	PlayerPool.removeFromPool(player)
	playersInTutorial[player.UserId] = player
	TeleportManager.teleport(player, tutroialMap.OriginPosition + Vector3.new(0, 80, 0), true)
end

return TutorialManager
