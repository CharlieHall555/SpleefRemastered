local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local MobileSettingsWidget = require(ClientModuleDirectory.Gui.MobileSettingsWidget)

local MobileSettingsButton = {}

local ButtonGUI: Frame?

local onClick

function MobileSettingsButton.onLoaded()
	if PlatformDetector.getPlatform() ~= "MOBILE" then
		return
	end

	ButtonGUI = GuiAssets:WaitForChild("Settings"):WaitForChild("SettingsButton")
	ButtonGUI.Visible = true
	ButtonGUI.Parent = Screens.touchControls
	ButtonGUI.Clickable.Activated:Connect(function(inputObject, clickCount)
		MobileSettingsWidget.show()
	end)

end

return MobileSettingsButton
