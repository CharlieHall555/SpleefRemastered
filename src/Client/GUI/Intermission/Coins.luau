local Coins = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local TextUtilities = require(ClientModuleDirectory.TextUtilities)

local CoinsGui : Frame?

function Coins.onProfileLoaded()
	CoinsGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("Coins")
	CoinsGui.Parent = Screens.intermissionHUD
	CoinsGui.Visible = false

	CoinsGui.Count.Text = TextUtilities.formatCurrency(UserProfile.getValue("coins"))

	UserProfile.setOnUpdateCallback(function(valueName, newValue)
		
		CoinsGui.Count.Text = TextUtilities.formatCurrency(newValue)

	end , "coins")

end



return Coins
