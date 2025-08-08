local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local AlertSystem = require(ClientModuleDirectory.GUI.AlertSystem)

local StateChangeManager = {}

function StateChangeManager.init()
    
    ClientStateTracker.connectRoundStarting(function()
        
    end)

    ClientStateTracker.connectIntermission(function()
        
    end)

    ClientStateTracker.connectRoundStarting(function()
        
        AlertSystem.addAlert("Round starting...")

    end)


end

return StateChangeManager 