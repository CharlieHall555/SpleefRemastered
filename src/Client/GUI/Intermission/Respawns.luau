local Respawns = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local TextUtilities = require(ClientModuleDirectory.TextUtilities)

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
end

return Respawns
