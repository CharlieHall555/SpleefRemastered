local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)

local AlertSystemBindings = {}

function AlertSystemBindings.init()
    
	RemoteEventHandler.newEventConnection("RESPAWN_REFUNDED", function(amount) 
        
        local text = "Respawn failed, you have been granted " .. amount .. " Respawns."
        AlertSystem.show(text)
    
    end)
end

return AlertSystemBindings
