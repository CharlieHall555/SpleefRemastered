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



    ClientStateTracker.connectRoundStarting(function()
        

    end)


end 

return StateChangeManager 