local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AlertSystem = require(ClientModuleDirectory.GUI.AlertSystem)
local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)

local MiscBindings = {}

local lightning = "rbxassetid://6994934244"

function MiscBindings.init()
    
    RemoteEventHandler.newEventConnection("PLAYER_DIED" , function(playerWhoDied : Player)
        
        SoundPlayer.playSound(lightning)

    end)

end

return MiscBindings