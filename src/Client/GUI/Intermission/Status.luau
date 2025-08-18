local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local StatusGui = {}

local serverStateMappings = {
    INTERMISSION = "Intermission",
    STARTING = "Round Starting",
    WAITING = "Waiting for players",
    ENDING = "Round Ending",
    PREPARING = "Round Active",
    ACTIVE = "Round Active"
}

local Status : Frame?

function StatusGui.onProfileLoaded()

    Status = GuiAssets:WaitForChild("Intermission"):WaitForChild("Status")
    Status.Parent = Screens.intermissionHUD
    Status.Winner.Visible = false
    
    ClientStateTracker.connectServerStateChange(function(newState)

        Status.State.Text = serverStateMappings[newState] or ""
        
    end)

    RemoteEventHandler.newEventConnection("INTERMISSION_TIMER_CHANGED" , function(newValue)
        
        if ClientStateTracker.getState() == "INTERMISSION" then
            
            Status.Timer.Text = math.max(math.floor(newValue) , 0)

        end

    end)

    RemoteEventHandler.newEventConnection("PLAYER_WON" , function(playerName : string)
        
        Status.Winner.Visible = true
        Status.Winner.Text = "Winner: " .. playerName
        task.delay(4 , function()
            Status.Winner.Visible = false
        end)

    end)
    
    
end


return StatusGui