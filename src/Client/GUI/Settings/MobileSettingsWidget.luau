local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local MusicPlayer = require(ClientModuleDirectory.Sound.MusicPlayer)

local MobileSettingsWidget = {}

local WidgetGUI: Frame?

local closeButtonClickable: TextButton

local moreButtonClickable: TextButton
local musicButtonClickable: TextButton
local sfxButtonClickable: TextButton

local musicButtonIcon: ImageLabel
local sfxButtonIcon: ImageLabel

local onClick

local SOUND_ON_IMAGE = "rbxassetid://102335554495793"
local SOUND_OFF_IMAGE = "rbxassetid://108653430274728"
local MUSIC_ON_IMAGE = "rbxassetid://110651581351042"
local MUSIC_OFF_IMAGE = "rbxassetid://92620108688852"



local function updateSoundIcon(isMuted: boolean)
    if not sfxButtonIcon then
        return
    end
    sfxButtonIcon.Image = isMuted and SOUND_OFF_IMAGE or SOUND_ON_IMAGE
end

local function updateMusicIcon(isEnabled: boolean)
    if not musicButtonIcon then
        return
    end
    musicButtonIcon.Image = isEnabled and MUSIC_ON_IMAGE or MUSIC_OFF_IMAGE
end

local function setInitialIcons()
    updateSoundIcon(SoundPlayer.getIsMuted())

    local musicEnabled = true
    if MusicPlayer.isEnabled then
        musicEnabled = MusicPlayer.isEnabled()
    end
    updateMusicIcon(musicEnabled)
end

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

	musicButtonIcon = WidgetGUI.MusicButton.ImageLabel
	sfxButtonIcon = WidgetGUI.SFXButton.ImageLabel

	closeButtonClickable.Activated:Connect(function(inputObject, clickCount)
		MobileSettingsWidget.hide()
	end)

	musicButtonClickable.Activated:Connect(function(inputObject, clickCount)
		if MusicPlayer.isEnabled and MusicPlayer.isEnabled() then
			MusicPlayer.disable()
		else
			MusicPlayer.enable()
		end
	end)

	sfxButtonClickable.Activated:Connect(function(inputObject, clickCount)
		if SoundPlayer.getIsMuted() then
			SoundPlayer.setMuted(false)
		else
			SoundPlayer.setMuted(true)
		end
	end)

	setInitialIcons()

	MusicPlayer.connectOnToggle(function(enabled)
        updateMusicIcon(enabled)
    end)

    SoundPlayer.connectOnToggle(function(enabled)
        updateSoundIcon(not enabled)
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
