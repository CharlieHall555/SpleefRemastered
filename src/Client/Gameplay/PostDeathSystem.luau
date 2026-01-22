local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local RespawnScreen = require(ClientModuleDirectory.Gui.RespawnScreen)
local EliminationScreen = require(ClientModuleDirectory.Gui.EliminationScreen)
local SpectateController = require(ClientModuleDirectory.Spectate.Controller)
local PlayerSessionVariables = require(ClientModuleDirectory.Variables.SessionVariables)

local PostDeathSystem = {}

local debounceActive = false
local CHECK_DELAY_SECONDS = 1
local DEBOUNCE_WINDOW = 1 -- ignore duplicate death events within this window

local function resetState()
	debounceActive = false
end

function PostDeathSystem.init()
	EliminationScreen.setOnSpectatePressed(function()
		if ClientStateTracker.getServerState() == "ACTIVE" then
			SpectateController.enter()
		end
	end)

	RemoteEventHandler.newEventConnection("RESPAWN_GRANTED", function(_player)
		debounceActive = false
	end)

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "PREPARING" then
			resetState()
		end
	end)

	RemoteEventHandler.newEventConnection("PLAYER_DIED", function(player: Player?, eliminator: Player?)
		if player ~= LocalPlayer then
			return
		end
		if debounceActive then
			return
		end
		debounceActive = true

		task.spawn(function()
			task.wait(CHECK_DELAY_SECONDS)

			local state = ClientStateTracker.getServerState()
			if state == "ACTIVE" or state == "PREPARING" then
				if (PlayerSessionVariables.getValue("hasUsedRespawn") or false) == true then
					EliminationScreen.show(player, eliminator)
				else
					RespawnScreen.show(LocalPlayer, eliminator)
				end
			else
				return
			end

			-- keep debounce for a short window to swallow duplicate events
			task.wait(DEBOUNCE_WINDOW)
			debounceActive = false
		end)
	end)

	ClientStateTracker.connectServerStateChange(function(newState)
		if (newState == "ACTIVE" or newState == "PREPARING") == false then
			RespawnScreen.hide()
		end
	end)
end

return PostDeathSystem
