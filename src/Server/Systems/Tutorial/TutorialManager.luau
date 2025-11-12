-- TutorialManager.lua

local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local TutorialMapGen = require(ModuleDirectory.Tutorial.tutorialMapGenerator)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerPool = require(ModuleDirectory.Round.PlayerPool)
local AmmoManager = require(ModuleDirectory.Ammo.AmmoManager)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local EventAnalytics = require(ModuleDirectory.Analytics.EventAnalytics)
local LavaManager = require(ModuleDirectory.Gameplay.LavaManager)


local TutorialManager = {}

local LobbySpawn

function TutorialManager.init()
	
	LavaManager.getMap = TutorialManager.getMap

	RemoteEventHandler.newEventConnection("TUTORIAL_COMPLETE" , TutorialManager.stop)
	LobbySpawn = game.Workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation")

	Players.PlayerRemoving:Connect(function(player : Player)
		local hasCompletedTutorial = PlayerData.getHasCompletedTutorial(player)
		local playTime = SessionVariables.getValue(player , "playTime") or -1
		if hasCompletedTutorial == false then
			EventAnalytics.logEvent(player , "LEFT_TUTORIAL" , 1 , {playTime = playTime})
		end
	end)

end

function TutorialManager.start(player : Player)

	PlayerPool.removeFromPool(player)
	local tutorialMap = TutorialMapGen.generateMap(player)
	SessionVariables.setValue(player , "inTutorial" , true)
	TeleportManager.teleport(player , tutorialMap.OriginPosition + Vector3.new(0 , 50 , 0) , true)
	RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "TUTORIAL")
	RemoteEventHandler.FireOnClient(player, "START_TUTORIAL")
	AmmoManager.setUp({player})
end

function TutorialManager.stop(player : Player , completed : boolean)
	SessionVariables.setValue(player , "inTutorial" , false)
	TeleportManager.teleport(player , LobbySpawn.Position + Vector3.new(0 , 6 , 0) , true)
	RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "INTERMISSION")
	PlayerData.setHasCompletedTutorial(player , true)
	task.spawn(function()
		task.wait()
		TutorialMapGen.deleteMap(player)
		TeleportManager.teleport(player , LobbySpawn.Position + Vector3.new(0 , 6 , 0) , true)
		task.wait(2)
		PlayerPool.addToPool(player)
	end)

	local playTime = SessionVariables.getValue(player , "playTime") or -1

	if completed then
		EventAnalytics.logEvent(player , "TUTORIAL_COMPLETE" , 1 , {playTime = playTime})
	else
		EventAnalytics.logEvent(player , "TUTORIAL_SKIPPED" , 1 , {playTime = playTime})
	end
end

function TutorialManager.getMap(player : Player)
	return TutorialMapGen.getMap(player)
end


return TutorialManager
