local Ammo = {}

local TweenService = game:GetService("TweenService")

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local RoundStatus = require(ClientModuleDirectory.Gui.RoundStatus)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)

local AFK_ELIMINATION_TIME = 25
local ALERT_TIME = 5

local AFKGui: Frame?

local AFKWarning = {}

function AFKWarning.onProfileLoaded()
    AFKGui = GuiAssets:WaitForChild("InGame"):WaitForChild("AFKWarning"):Clone()
    AFKGui.Parent = Screens.gameHUD
    AFKGui.Visible = false

    UserSessionVariables.setOnUpdateCallback(function(valueName, newValue)

        local timeLeft = AFK_ELIMINATION_TIME - newValue

        if timeLeft < ALERT_TIME then
            AFKGui.Visible = true
        else
            AFKGui.Visible = false
        end

        AFKGui.Timer.Text = "Eliminating In " .. tostring(math.max(math.ceil(timeLeft), 0)) .. " Seconds: "

    end , "afkTime")

    ClientStateTracker.connectActive(function()
        AFKGui.Visible = false
    end)

end

return AFKWarning
