local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local RunService = game:GetService("RunService")
local ModeDetector = require(ClientModuleDirectory.Input.ModeDetector)

local BackShovel = {}

function BackShovel.init()


    RemoteEventHandler.FireOnServer("CLIENT_MODE_CHANGE" , ModeDetector.getMode()) -- stream wether the 

    ModeDetector.connectModeChange(function(newMode)
        
        RemoteEventHandler.FireOnServer("CLIENT_MODE_CHANGE" , newMode) -- stream wether the 

    end)
    
end

return BackShovel