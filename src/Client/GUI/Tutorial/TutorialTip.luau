local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ConfirmLeave = require(ClientModuleDirectory.Gui.ConfirmLeave)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local TutorialTip = {}

local timerValue: number = 0

local GUI: Frame?

local textLabel : TextLabel
local imageLabel : ImageLabel
local skipClickable : TextButton 

function TutorialTip.onProfileLoaded()
	GUI = GuiAssets:WaitForChild("Tutorial"):WaitForChild("TutorialTip")
	GUI.Parent = Screens.gameHUD
    
	if PlatformDetector.getScreenSize().X < 900  then
		GUI.Position = UDim2.fromScale(0.55 , GUI.Position.Y.Scale)
	end

	ClientStateTracker.connectTutorial(function()
		GUI.Visible = true
	end)

	ClientStateTracker.connectIntermission(function()
		GUI.Visible = false
	end)

    ClientStateTracker.connectActive(function()
		GUI.Visible = false
	end)

    textLabel = GUI.Label
    imageLabel = GUI.Icon.ImageLabel
	skipClickable = GUI.Skip.Clickable

	skipClickable.Activated:Connect(function(inputObject, clickCount)
		ConfirmLeave.show()
	end)
	
    GUI.Visible = ClientStateTracker.getState() == "TUTORIAL"
end

function TutorialTip.setText(text : string)
    
    textLabel.Text = text
    
end

function TutorialTip.setImage(image : string)
    
    imageLabel.Image = image

end

return TutorialTip
