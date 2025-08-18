local InGameHUD = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GUI = game:GetService("ReplicatedStorage"):WaitForChild("GUIAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)

local maxRoundTime = 0
local ammo = 0
local maxammo = 0

local InGameHUDGUI

function InGameHUD.onProfileLoaded()
	InGameHUDGUI = GUI.InGameHud
	InGameHUDGUI.Parent = localPlayer.PlayerGui
	InGameHUDGUI.Enabled = (ClientStateTracker.getState() == "ACTIVE")

	ClientStateTracker.connectActive(function()
		InGameHUDGUI.Enabled = true
	end)

	ClientStateTracker.connectIntermission(function()
		InGameHUDGUI.Enabled = false
	end)

	ClientStateTracker.connectRoundStarting(function()
		InGameHUDGUI.Enabled = false
	end)

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "PREPARING" then
			InGameHUDGUI.Main.State.Visible = true
			InGameHUDGUI.Main.State.Text = "Prepare"
			InGameHUDGUI.Main.State.Fire1.Visible = false
			InGameHUDGUI.Main.State.Fire2.Visible = false
		elseif newState == "ACTIVE" then
			InGameHUDGUI.Main.State.Visible = false
			InGameHUDGUI.Ammo.Visible = true
		end
	end)

	RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH", function(player)
		InGameHUDGUI.Main.State.Visible = true
		InGameHUDGUI.Main.State.Text = "Sudden Death"
		InGameHUDGUI.Main.State.Fire1.Visible = true
		InGameHUDGUI.Main.State.Fire2.Visible = true
	end)

	ClientAmmoTracker.setOnMaxAmmoChanged(function(maxammo)
		InGameHUDGUI.Ammo.Count.Text = 0 .. " / " .. maxammo
		InGameHUDGUI.Ammo.OutOfAmmo.Visible = true
	end)

	ClientAmmoTracker.setOnAmmoChanged(function(newAmmo, maxammo)
		InGameHUDGUI.Ammo.Count.Text = newAmmo .. " / " .. maxammo
		if newAmmo == 0 then
			InGameHUDGUI.Ammo.OutOfAmmo.Visible = true
		else
			InGameHUDGUI.Ammo.OutOfAmmo.Visible = false
		end
	end)

    ClientAmmoTracker.setOnRegenProgressChanged(function(newProgress , maxProgress)
		InGameHUDGUI.Ammo.Regen.Fillable.Size = UDim2.fromScale(newProgress / maxProgress , 1) 

        if InGameHUDGUI.Ammo.Regen.Fillable.Size.X.Scale <= 0.01 then
            InGameHUDGUI.Ammo.Regen.Fillable.UIStroke.Enabled = false
        else
            InGameHUDGUI.Ammo.Regen.Fillable.UIStroke.Enabled = true
        end
	end)

	RemoteEventHandler.newEventConnection("PREPARING_TIMER_CHANGED", function(time)
		if ClientStateTracker.getServerState() == "PREPARING" then
			InGameHUDGUI.Main.Timer.Text = math.max(0, math.floor(time))
		end
	end)
    

	RemoteEventHandler.newEventConnection("SUDDEN_DEATH_TIMER_CHANGED", function(time)
		if ClientStateTracker.getServerState() == "ACTIVE" then
			InGameHUDGUI.Main.Timer.Text = math.max(0, math.floor(time))
		end
	end)

	RemoteEventHandler.newEventConnection("ROUND_TIMER_STARTED", function(time)
		maxRoundTime = time
	end)
end

local hintCooldown = false
function InGameHUD.showHint()

	task.spawn(function()

		if hintCooldown == false then
			hintCooldown = true
			InGameHUDGUI.Hint.Visible = true
			task.wait(5)
			InGameHUDGUI.Hint.Visible = false
			task.wait(1)
			hintCooldown = false
		end
	
	end)
	
end

return InGameHUD
