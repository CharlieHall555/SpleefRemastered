local Respawns = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local TextUtilities = require(ClientModuleDirectory.TextUtilities)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)

local CurrencyGui: Frame?

function Respawns.onProfileLoaded()
	CurrencyGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("CurrencyGui")
	CurrencyGui.Parent = Screens.intermissionHUD
	CurrencyGui.Visible = true

	CurrencyGui.RespawnCount.Text = TextUtilities.formatCurrency(UserProfile.getValue("respawns"))
	CurrencyGui.CoinCount.Text = TextUtilities.formatCurrency(UserProfile.getValue("coins"))

	UserProfile.setOnUpdateCallback(function(valueName, newValue)
		CurrencyGui.RespawnCount.Text = TextUtilities.formatCurrency(newValue)
	end, "respawns")

	UserProfile.setOnUpdateCallback(function(valueName, newValue)
		CurrencyGui.CoinCount.Text = TextUtilities.formatCurrency(newValue)
	end, "coins")

	ClientStateTracker.connectIntermission(function()
		CurrencyGui.Visible = true
	end)

	ClientStateTracker.connectTutorial(function()
		CurrencyGui.Visible = false
	end)

	if PlatformDetector.getPlatform() == "MOBILE" then
	
		CurrencyGui.AnchorPoint = Vector2.new(CurrencyGui.AnchorPoint.X , 1)
		local touchButtonsGui = TouchButtons.getGui()
		
		local yScale = touchButtonsGui.Position.Y.Scale - touchButtonsGui.Size.Y.Scale

		CurrencyGui.Position = UDim2.new(UDim.new(1 , 0) , UDim.new(0.3 , 0))
		CurrencyGui.UIScale.Scale = 1.2

	end

end

return Respawns
