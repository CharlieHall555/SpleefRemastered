local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local AlertSystem = require(ClientModuleDirectory.GUI.AlertSystem)
local PlayerHighlighter = require(ClientModuleDirectory.PlayerHighlighter)

local StateChangeManager = {}

function StateChangeManager.init()
    
    ClientStateTracker.connectRoundStarting(function()
        
    end)

    ClientStateTracker.connectIntermission(function()
        print("Hi")
        PlayerHighlighter.reset()
    end)

    ClientStateTracker.connectRoundStarting(function()
        
        AlertSystem.addAlert("Round starting...")

    end)


end

return StateChangeManager 