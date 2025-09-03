local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local SpawnProtectionManager = require(ModuleDirectory.Gameplay.SpawnProtectionManager)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local Map = require(ModuleDirectory.Map.Map)

local RespawnManager = {}

local currentMap: Map.Map? = nil

function RespawnManager.init()
	RemoteEventHandler.newEventConnection("REQUEST_RESPAWN", function(player)
		if PlayerData.getRespawns(player) >= 0 then
			if RespawnManager.canRespawn(player) == false then
				RemoteEventHandler.FireOnClient(player, "RESPAWN_DENIED", "CANNOT_RESPAWN_NOW")
                print("RESPAWN DENIED")
			end
            RespawnManager.respawnPlayer(player)
		else
			RemoteEventHandler.FireOnClient(player, "RESPAWN_DENIED", "NO_RESPAWNS")
            print("RESPAWN DENIED")
		end
	end)
end

function RespawnManager.setMap(newMap: Map.Map?)
	currentMap = newMap
end

function RespawnManager.canRespawn(player: Player): boolean
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

function RespawnManager.respawnPlayer(Player): boolean
	if RespawnManager.canRespawn(Player) then
		local topLayer = currentMap:getTopLayer()
		local randomBlock = topLayer:getRandomBlock()
		local Position = Vector3.new(0, 150, 0)
		if randomBlock then
			Position = randomBlock.Part.Position + Vector3.new(0, 30, 0)
		else
			Position = currentMap.OriginPosition + Vector3.new(0, 150, 0)
		end

		local success = TeleportManager.teleport(Player, Position, false)
		if not success then
			return false
		end

		RemoteEventHandler.FireOnClient(Player, "CHANGE_STATE", "ACTIVE")
		SpawnProtectionManager.apply(Player)
		PlayersInGame.addPlayer(Player, true)
	else
		return false
	end
end

return RespawnManager
