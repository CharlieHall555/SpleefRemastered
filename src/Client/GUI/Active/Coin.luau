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
local SessionVariables = require(ClientModuleDirectory.Variables.SessionVariables)

local CoinGui: Frame?

local Coin = {}

local current = 0

local function animateText(label: TextLabel)
	local original = label:GetAttribute("originalSize") or label.Size
	label.Size = UDim2.fromScale(original.X.Scale * 1.25, original.Y.Scale * 1.25)
	TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = original,
	}):Play()
end

function Coin.onProfileLoaded()
    CoinGui = GuiAssets:WaitForChild("InGame"):WaitForChild("Coins")
    CoinGui.Parent = Screens.gameHUD

    CoinGui.Count.Text = tostring(SessionVariables.getValue("coinsCollected") or 0)
    CoinGui.Count:SetAttribute("originalSize" , CoinGui.Count.Size)
    CoinGui.Visible = true

    SessionVariables.setOnUpdateCallback(function(valueName, newValue)
        CoinGui.Count.Text = tostring(newValue or 0)
        if newValue ~= current then
            animateText(CoinGui.Count)
        end
        current = newValue
       
    end, "coinsCollected")

end

return Coin
