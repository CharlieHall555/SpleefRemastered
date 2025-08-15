local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)

local AlertSystemBindings = {}

function AlertSystemBindings.init()
    
    RemoteEventHandler.newEventConnection("PLAYER_DIED" , function(playerWhoDied : Player)
        
        AlertSystem.addAlert(playerWhoDied.DisplayName .. " Died")

    end)

end

return AlertSystemBindings