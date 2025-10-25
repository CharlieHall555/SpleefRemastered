local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local SpawnProtectionManager = require(ModuleDirectory.Gameplay.SpawnProtectionManager)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local Map = require(ModuleDirectory.Map.Map)
local SuddenDeath = require(ModuleDirectory.Round.SuddenDeath)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local PlayerDeathDetector = require(ModuleDirectory.Round.PlayerDeathDetector)

local RespawnManager = {}

local currentMap: Map.Map? = nil

function RespawnManager.init()
	RemoteEventHandler.newEventConnection("REQUEST_RESPAWN", function(player)
		if PlayerData.getRespawns(player) >= 0 and SuddenDeath.isActive() == false then
			if RespawnManager.canRespawn(player) == false then
				RemoteEventHandler.FireOnClient(player, "RESPAWN_DENIED", "CANNOT_RESPAWN_NOW")
                print("RESPAWN DENIED")
				return
			end
            RespawnManager.respawnPlayer(player)
		else
			RemoteEventHandler.FireOnClient(player, "RESPAWN_DENIED", "NO_RESPAWNS")
            print("RESPAWN DENIED")
			return
		end
	end)
end

function RespawnManager.onRoundEnd()

	for _, player in Players:GetPlayers() do
		SessionVariables.setValue(player, "hasUsedRespawn", false)
		SessionVariables.setValue(player, "spawnProtectionActive", false)
	end

end

function RespawnManager.setMap(newMap: Map.Map?)
	currentMap = newMap
end

function RespawnManager.canRespawn(player: Player): boolean

	if SessionVariables.getValue(player, "spawnProtectionActive") == true then
		return false
	end

	if player.character == nil then
		return false
	end

	if currentMap == nil then
		return false
	end

	if RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "PREPARING" then
		return true
	end

	return false
end

function RespawnManager.respawnPlayer(player): boolean
	if RespawnManager.canRespawn(player) then

		SessionVariables.setValue(player, "hasUsedRespawn", true)

		local topLayer = currentMap:getTopLayer()
		local randomBlock = topLayer:getRandomBlock()
		local Position = Vector3.new(0, 150, 0)
		if randomBlock then
			Position = randomBlock.Part.Position + Vector3.new(0, 30, 0)
		else
			Position = currentMap.OriginPosition + Vector3.new(0, 150, 0)
		end

		local success = TeleportManager.teleport(player, Position, false)
		if not success then
			return false
		end

		local respawns = PlayerData.getRespawns(player) -- prevent respawns going negative
		if respawns > 0 then
			PlayerData.incrementRespawns(player , -1)
		end

		RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "ACTIVE")
		SpawnProtectionManager.apply(player)
		PlayerDeathDetector.clearDeathTime(player)
		PlayersInGame.addPlayer(player, true)
		RemoteEventHandler.FireOnClient(player , "REHIGHLIGHT_PLAYERS" , PlayersInGame.getActivePlayers())
		RemoteEventHandler.FireOnAllClients("PLAYER_REVIVED", player)
		return true
	else
		return false
	end
end

return RespawnManager
