local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local ConfirmLeave = {}

local timerValue: number = 0

local GUI: Frame?

local skipClickable : TextButton
local stayClickable : TextButton

local onLeave : () -> () = nil

function ConfirmLeave.onProfileLoaded()
	GUI = GuiAssets:WaitForChild("Tutorial"):WaitForChild("ConfirmLeave" , 5)

	if GUI == nil then
		return
	end

	GUI.Visible = false
	GUI.Parent = Screens.general
    
	ClientStateTracker.connectTutorial(function()
		GUI.Visible = false
	end)

	ClientStateTracker.connectIntermission(function()
		GUI.Visible = false
	end)

    ClientStateTracker.connectActive(function()
		GUI.Visible = false
	end)

    skipClickable = GUI.SkipButton.Clickable
	stayClickable = GUI.StayButton.Clickable

	if skipClickable then
		skipClickable.Activated:Connect(function(inputObject, clickCount)
			if onLeave then
				onLeave()
			end
			GUI.Visible = false
		end)
	end

	if stayClickable then
		stayClickable.Activated:Connect(function(inputObject, clickCount)
			GUI.Visible = false
		end)
		
	end
end


function ConfirmLeave.show()
	GUI.Visible = true
end

function ConfirmLeave.hide()
	GUI.Visible = true
end

function ConfirmLeave.onLeave(fn : () -> ())

	onLeave = fn
	
end


return ConfirmLeave
