local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local AlertSystem = {}

local TIME_TO_DISAPPEAR = 5

local alertTemplate : Frame? -- clone this on new alert

function AlertSystem.init()
	--Screens.general -- this will be parent for guis
	if PlatformDetector.getPlatform() == "MOBILE" then
		alertTemplate = GuiAssets:WaitForChild("AlertSystem"):WaitForChild("MobileAlert")
	else
		alertTemplate = GuiAssets:WaitForChild("AlertSystem"):WaitForChild("Alert")
	end

end

function AlertSystem.show(alertText : TextLabel)
	
	local newAlert = alertTemplate:Clone()
	newAlert.Parent = Screens.general
	local alertTextLabel : TextLabel = newAlert.AlertText
	alertTextLabel.Text = alertText

	newAlert.CloseButton.Clickable.Activated:Connect(function()
		newAlert:Destroy()
	end)
end



return AlertSystem
