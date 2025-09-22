local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local AbilityActionHandler = {}

function AbilityActionHandler.init()
    
    InputHandler.bindKey(Enum.KeyCode.Q , function()
        RemoteEventHandler.FireOnServer("REQUEST_ABILITY", "DASH")
    end)

end

return AbilityActionHandler