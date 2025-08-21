local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local LocalPlayer = game.Players.LocalPlayer
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local CelebrationTracker = {}

local onCelebrate : (()->())? = nil

local hasCelebrated = false

function CelebrationTracker.init()
    
    RemoteEventHandler.newEventConnection("CHEERED_PLAYER" , function(_ , fromPlayer)
        
        if fromPlayer == LocalPlayer then
            hasCelebrated = true
            if onCelebrate then
                onCelebrate()
            end
        end

    end)
    
    ClientStateTracker.connectServerStateChange(function(newState : string)
        if newState == "STARTING" then
            CelebrationTracker.reset()
        end
    end)

end

function CelebrationTracker.hasCelebrated()
    return hasCelebrated
end

function CelebrationTracker.reset()
    hasCelebrated = false
end

function CelebrationTracker.setOnCelebrate(fn : ()->()) : nil
    onCelebrate = fn
end


return CelebrationTracker