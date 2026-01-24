local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local Overhead = require(ModuleDirectory.Overhead)

local GroupRanks = {}

function GroupRanks.init()

	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
		local success, isInGroup = pcall(function()
			return player:IsInGroup(Config.GROUP_ID)
		end)

		if success and isInGroup then
			SessionVariables.setValue(player, "inGroup", true)
		else
			SessionVariables.setValue(player, "inGroup", false)
		end

		if table.find(Config.DEV_ID , player.UserId)  then
			SessionVariables.setValue(player, "isDev", true)
		else
			SessionVariables.setValue(player, "isDev", false)
		end

		Overhead.refreshForPlayer(player)
	end)
end

return GroupRanks
