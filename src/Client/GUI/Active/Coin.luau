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

local CoinGui: Frame?

local Coin = {}

function Coin.onProfileLoaded()
    CoinGui = GuiAssets:WaitForChild("InGame"):WaitForChild("Coins")
    CoinGui.Parent = Screens.gameHUD

    CoinGui.Count.Text = tostring(UserSessionVariables.getValue("coinsCollected") or 0)
    CoinGui.Visible = true

    UserSessionVariables.setOnUpdateCallback(function(valueName, newValue)
        CoinGui.Count.Text = tostring(newValue or 0)
    end, "coinsCollected")

end

return Coin
