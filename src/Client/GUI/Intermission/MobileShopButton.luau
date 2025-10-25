local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local Shop = require(ClientModuleDirectory.Gui.Shop.Main)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local MobileSettingsWidget = require(ClientModuleDirectory.Gui.MobileSettingsWidget)

local MobileShopButton = {}

local ButtonGUI: Frame?

local onClick

function MobileShopButton.onLoaded()
	if PlatformDetector.getPlatform() ~= "MOBILE" then
		return
	end

	ButtonGUI = GuiAssets:WaitForChild("Intermission"):WaitForChild("MobileShopButton")
	ButtonGUI.Visible = true
	ButtonGUI.Parent = Screens.touchControls
	ButtonGUI.Clickable.Activated:Connect(function(inputObject, clickCount)
		if Shop.getVisible() then
            Shop.hide()
        else
            Shop.show()
        end
	end)

    ClientStateTracker.connectIntermission(function()
        ButtonGUI.Visible = true
    end)

    ClientStateTracker.connectActive(function()
        ButtonGUI.Visible = false
    end)

    ClientStateTracker.connectTutorial(function()
        ButtonGUI.Visible = false
    end)

end

return MobileShopButton
