local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GUI = game:GetService("ReplicatedStorage"):WaitForChild("GUIAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local Intermission = {}

local serverStateMappings = {
    INTERMISSION = "Intermission",
    STARTING = "Round Starting",
    WAITING = "Waiting for players",
    ENDING = "Round Ending",
    PREPARING = "Round Active",
    ACTIVE = "Round Active"
}

local IntermissionGUI 

function Intermission.onProfileLoaded()

    print("igu1")

    IntermissionGUI = GUI.IntermissionHud
    IntermissionGUI.Parent = localPlayer.PlayerGui
    IntermissionGUI.Enabled = (ClientStateTracker.getState() == "INTERMISSION")
    IntermissionGUI.Status.Winner.Visible = false

    ClientStateTracker.connectIntermission(function()
        
        print("change")
        print("nah")
        IntermissionGUI.Enabled = true

    end)

    ClientStateTracker.connectActive(function()
        
        print("rah")
        IntermissionGUI.Enabled = false

    end)

    ClientStateTracker.connectServerStateChange(function(newState)

        IntermissionGUI.Status.State.Text = serverStateMappings[newState] or ""
        
    end)

    RemoteEventHandler.newEventConnection("INTERMISSION_TIMER_CHANGED" , function(newValue)
        
        if ClientStateTracker.getState() == "INTERMISSION" then
            
            IntermissionGUI.Status.Timer.Text = math.max(math.floor(newValue) , 0)

        end

    end)

    RemoteEventHandler.newEventConnection("PLAYER_WON" , function(playerName : string)
        
        IntermissionGUI.Status.Winner.Visible = true
        IntermissionGUI.Status.Winner.Text = "Winner: " .. playerName
        task.delay(4 , function()
            IntermissionGUI.Status.Winner.Visible = false
        end)

    end)
    
    
end


return Intermission