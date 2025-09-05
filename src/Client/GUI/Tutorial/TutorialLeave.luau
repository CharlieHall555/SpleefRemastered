local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local TutorialLeave = {}

local timerValue: number = 0

local GUI: Frame?

function TutorialLeave.onProfileLoaded()
	GUI = GuiAssets:WaitForChild("Tutorial"):WaitForChild("Leave")
	GUI.Parent = Screens.intermissionHUD
    GUI.Visible = ClientStateTracker.getState() == "TUTORIAL"

	ClientStateTracker.connectTutorial(function()
		GUI.Visible = true
	end)

	ClientStateTracker.connectIntermission(function()
		GUI.Visible = false
	end)

	GUI.Clickable.Activated:Connect(function(inputObject, clickCount)
		if ClientStateTracker.getState() == "TUTORIAL" then
			RemoteEventHandler.FireOnServer("REQUEST_LEAVE_TUTORIAL_AREA")
		end
	end)
end

return TutorialLeave
