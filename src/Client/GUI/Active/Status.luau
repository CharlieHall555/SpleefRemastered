local RoundStatus = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local StatusGUI

function RoundStatus.onProfileLoaded()
	StatusGUI = GuiAssets:WaitForChild("InGame"):WaitForChild("Status")
	StatusGUI.Parent = Screens.gameHUD

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "PREPARING" then
			StatusGUI.State.Visible = true
			StatusGUI.State.Text = "Prepare"
			StatusGUI.State.Fire1.Visible = false
			StatusGUI.State.Fire2.Visible = false
		elseif newState == "ACTIVE" then
			StatusGUI.State.Visible = false
		end
	end)

	RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH", function(player)
		StatusGUI.State.Visible = true
		StatusGUI.State.Text = "Sudden Death"
		StatusGUI.State.Fire1.Visible = true
		StatusGUI.State.Fire2.Visible = true
	end)

	RemoteEventHandler.newEventConnection("PLAYERS_IN_GAME_CHANGED" , function(aliveNow : number , maxAlive : number)
		StatusGUI.TopBar.AliveLabel.Text = aliveNow .. " / " .. maxAlive

	end)

    RemoteEventHandler.newEventConnection("PREPARING_TIMER_CHANGED", function(time)
		if ClientStateTracker.getServerState() == "PREPARING" then
			StatusGUI.TopBar.TimerLabel.Text = math.max(0, math.floor(time))
		end
	end)
    

	RemoteEventHandler.newEventConnection("SUDDEN_DEATH_TIMER_CHANGED", function(time)
		if ClientStateTracker.getServerState() == "ACTIVE" then
			StatusGUI.TopBar.TimerLabel.Text = math.max(0, math.floor(time))
		end
	end)

end



return RoundStatus
