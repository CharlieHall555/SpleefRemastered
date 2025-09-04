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

local RespawnsGui: Frame?

function Respawns.onProfileLoaded()
	RespawnsGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("Respawns")
	RespawnsGui.Parent = Screens.intermissionHUD
	RespawnsGui.Visible = true

	RespawnsGui.Count.Text = TextUtilities.formatCurrency(UserProfile.getValue("respawns"))

	UserProfile.setOnUpdateCallback(function(valueName, newValue)
		RespawnsGui.Count.Text = TextUtilities.formatCurrency(newValue)
	end, "Respawns")

	ClientStateTracker.connectIntermission(function()
		RespawnsGui.Visible = true
	end)

	ClientStateTracker.connectTutorial(function()
		RespawnsGui.Visible = false
	end)

	if PlatformDetector.getPlatform() == "MOBILE" then
	
		RespawnsGui.AnchorPoint = Vector2.new(RespawnsGui.AnchorPoint.X , 1)
		local touchButtonsGui = TouchButtons.getGui()
		
		local yScale = touchButtonsGui.Position.Y.Scale - touchButtonsGui.Size.Y.Scale

		RespawnsGui.Position = UDim2.new(UDim.new(1 , 0) , UDim.new(yScale , 0))
		RespawnsGui.UIScale.Scale = 1.2

	end

end

return Respawns
