local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)
local PlayerHighlighter = require(ClientModuleDirectory.PlayerHighlighter)
local SystemMessage = require(ClientModuleDirectory.Chat.SystemMessage)

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
        SystemMessage.send("ROUND STARTING" , Color3.fromRGB(9, 134, 16) , true)

    end)


end 

return StateChangeManager 