local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local MobileSettingsWidget = {}

local WidgetGUI: Frame?

local closeButtonClickable: TextButton

local moreButtonClickable: TextButton
local musicButtonClickable: TextButton
local sfxButtonClickable: TextButton

local onClick

function MobileSettingsWidget.onLoaded()
	if PlatformDetector.getPlatform() ~= "MOBILE" then
		return
	end

	WidgetGUI = GuiAssets:WaitForChild("Settings"):WaitForChild("MobileSettingsWidget")
	WidgetGUI.Visible = false
	WidgetGUI.Parent = Screens.general

	closeButtonClickable = WidgetGUI.CloseButton.Clickable
	moreButtonClickable = WidgetGUI.MoreButton.Clickable
	musicButtonClickable = WidgetGUI.MusicButton.Clickable
	sfxButtonClickable = WidgetGUI.SFXButton.Clickable

	closeButtonClickable.Activated:Connect(function(inputObject, clickCount)
		MobileSettingsWidget.hide()
	end)
end

function MobileSettingsWidget.hide()
	WidgetGUI.Visible = false
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end


function MobileSettingsWidget.show()
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	WidgetGUI.Visible = true
end

return MobileSettingsWidget
