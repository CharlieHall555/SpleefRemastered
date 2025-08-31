local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local StatusGui = {}

local state : string = "Intermission"
local timerValue : number = 0

local serverStateMappings = {
    INTERMISSION = "Intermission",
    STARTING = "Round Starting",
    WAITING = "Waiting for players",
    ENDING = "Round Ending",
    PREPARING = "Preparing",
    ACTIVE = "Round Active"
}

local Status : Frame?

function StatusGui.onProfileLoaded()

    Status = GuiAssets:WaitForChild("Intermission"):WaitForChild("Status")
    Status.Parent = Screens.intermissionHUD
    Status.Winner.Visible = false
    
    ClientStateTracker.connectServerStateChange(function(newState)

        state = serverStateMappings[newState] or ""
        Status.Label.Text = state .. " : " .. tostring(timerValue)
        
    end)

    RemoteEventHandler.newEventConnection("INTERMISSION_TIMER_CHANGED" , function(newValue)
        
        if ClientStateTracker.getState() == "INTERMISSION" then
            
            timerValue = math.max(math.floor(newValue) , 0)
            Status.Label.Text = state .. " : " .. tostring(timerValue)

        end

    end)

    RemoteEventHandler.newEventConnection("PREPARING_TIMER_CHANGED" , function(newValue)
        
        if ClientStateTracker.getState() == "INTERMISSION" and ClientStateTracker.getServerState() == "PREPARING" then
            
            timerValue = math.max(math.floor(newValue) , 0)
            Status.Label.Text = state .. " : " .. tostring(timerValue)

        end

    end)

    RemoteEventHandler.newEventConnection("SUDDEN_DEATH_TIMER_CHANGED" , function(newValue)
        
        if ClientStateTracker.getState() == "INTERMISSION" and ClientStateTracker.getServerState() == "ACTIVE" then
            
            timerValue = math.max(math.floor(newValue) , 0)
            Status.Label.Text = state .. " : " .. tostring(timerValue)

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