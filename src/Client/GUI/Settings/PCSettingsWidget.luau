local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local PCSettingsWidget = {}

local WidgetGUI: Frame?

local soundOnImage = "rbxassetid://102335554495793"
local soundOffImage = "rbxassetid://108653430274728"

local musicToggleButton: TextButton?

local musicToggleButton: TextButton?

local soundToggleButton: TextButton?
local soundIcon: ImageLabel?

function PCSettingsWidget.onLoaded()
	if PlatformDetector.getPlatform() ~= "PC" then
		return
	end

	WidgetGUI = GuiAssets:WaitForChild("Settings"):WaitForChild("SettingWidget")
	WidgetGUI.Visible = true
	WidgetGUI.Parent = Screens.general

    soundToggleButton = WidgetGUI.Sound.Clickable
    soundIcon = WidgetGUI.Sound.ImageLabel


	if SoundPlayer.getIsMuted() then
		soundIcon.Image = soundOnImage
	else
		soundIcon.Image = soundOffImage
	end

	
	soundToggleButton.Activated:Connect(function(inputObject, clickCount)
		if SoundPlayer.getIsMuted() then
			SoundPlayer.setInMuted(false)
			soundIcon.Image = soundOnImage
		else
			SoundPlayer.setInMuted(true)
			soundIcon.Image = soundOffImage
		end
	end)
end

return PCSettingsWidget
