local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AbilityBar = require(ClientModuleDirectory.Gui.AbilityBar)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local CooldownPredicter = require(ClientModuleDirectory.CooldownPredicter)
local RoundStatus = require(ClientModuleDirectory.Gui.RoundStatus)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)

local AbilityActionHandler = {}

function AbilityActionHandler.useAbility()
    
    if ClientStateTracker.getServerState() == "PREPARING" then
        local errorBlip = "rbxassetid://70373378044427"
		SoundPlayer.playSound(errorBlip, { volume = 1.5 })
	    RoundStatus.shakePrepare()
        return
    end

    if not(ClientStateTracker.getState() == "ACTIVE" and ClientStateTracker.getServerState() == "ACTIVE") then
        return
    end

    if (CooldownPredicter.getCooldown() > 0 or UserSessionVariables.getValue("spawnProtectionActive") or false) == true then
        local errorBlip = "rbxassetid://70373378044427"
		SoundPlayer.playSound(errorBlip, { volume = 1.5 })
        AbilityBar.shake()
        return
    end

    RemoteEventHandler.FireOnServer("REQUEST_ABILITY" , "DASH")
    
end

function AbilityActionHandler.init()
    
    InputHandler.bindKey(Enum.KeyCode.Q , function()
       AbilityActionHandler.useAbility()
    end) 

end

return AbilityActionHandler