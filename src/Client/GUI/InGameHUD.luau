local InGameHUD = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GUI = game:GetService("ReplicatedStorage"):WaitForChild("GUIAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local maxRoundTime = 0
local ammo = 0
local maxammo = 0

local InGameHUDGUI 

function InGameHUD.init()

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

    RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH" , function(player)
        
        InGameHUDGUI.Main.State.Visible = true
        InGameHUDGUI.Main.State.Text = "Sudden Death"
        InGameHUDGUI.Main.State.Fire1.Visible = true
        InGameHUDGUI.Main.State.Fire2.Visible = true




    end) 

    RemoteEventHandler.newEventConnection("SET_MAX_AMMO" , function(amount)
        
        maxammo = amount
        InGameHUDGUI.Ammo.Count.Text = ammo .. " / " .. maxammo

    end)

    RemoteEventHandler.newEventConnection("AMMO_CHANGED" , function(amount)
        
        ammo = amount
        InGameHUDGUI.Ammo.Count.Text = ammo .. " / " .. maxammo

    end)

    RemoteEventHandler.newEventConnection("PREPARING_TIMER_CHANGED" , function(time)
        if ClientStateTracker.getServerState() == "PREPARING" then
            InGameHUDGUI.Main.Timer.Text =  math.max(0 , math.floor(time))
        end
    end)

    RemoteEventHandler.newEventConnection("SUDDEN_DEATH_TIMER_CHANGED" , function(time)
        if ClientStateTracker.getServerState() == "ACTIVE" then
            InGameHUDGUI.Main.Timer.Text =  math.max(0 , math.floor(time))
        end
    end)

    RemoteEventHandler.newEventConnection("ROUND_TIMER_STARTED" , function(time)
        maxRoundTime = time
    end)
    
end


return InGameHUD