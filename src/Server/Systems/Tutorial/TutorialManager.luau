-- TutorialManager.lua

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local TutorialMapGen = require(ModuleDirectory.Tutorial.tutorialMapGenerator)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerPool = require(ModuleDirectory.Round.PlayerPool)
local AmmoManager = require(ModuleDirectory.Ammo.AmmoManager)

local TutorialManager = {}

local LobbySpawn

function TutorialManager.init()
	
	RemoteEventHandler.newEventConnection("TUTORIAL_COMPLETE" , function(player : Player)

		TutorialManager.stop(player)
		
	end)

	LobbySpawn = game.Workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation")

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

function TutorialManager.stop(player : Player)
	SessionVariables.setValue(player , "inTutorial" , false	)
	TeleportManager.teleport(player , LobbySpawn.Position + Vector3.new(0 , 6 , 0) , true)
	RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "INTERMISSION")
	PlayerPool.addToPool(player)
	task.spawn(function()
		task.wait()
		TutorialMapGen.deleteMap(player)
	end)
end

function TutorialManager.getMap(player : Player)
	return TutorialMapGen.getMap(player)
end


return TutorialManager
