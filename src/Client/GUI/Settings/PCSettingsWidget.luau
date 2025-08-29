local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local MusicPlayer = require(ClientModuleDirectory.Sound.MusicPlayer)

local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local PCSettingsWidget = {}

local widgetGui: Frame?

local SOUND_ON_IMAGE = "rbxassetid://102335554495793"
local SOUND_OFF_IMAGE = "rbxassetid://108653430274728"
local MUSIC_ON_IMAGE = "rbxassetid://110651581351042"
local MUSIC_OFF_IMAGE = "rbxassetid://92620108688852"

local soundToggleButton: TextButton?
local musicToggleButton: TextButton?
local soundIcon: ImageLabel?
local musicIcon: ImageLabel?

local function updateSoundIcon(isMuted: boolean)
    if not soundIcon then
        return
    end
    soundIcon.Image = isMuted and SOUND_OFF_IMAGE or SOUND_ON_IMAGE
end

local function updateMusicIcon(isEnabled: boolean)
    if not musicIcon then
        return
    end
    musicIcon.Image = isEnabled and MUSIC_ON_IMAGE or MUSIC_OFF_IMAGE
end

local function bindToggleSignals()
    MusicPlayer.connectOnToggle(function(enabled)
        updateMusicIcon(enabled)
    end)

    SoundPlayer.connectOnToggle(function(enabled)
        -- enabled here means "sound system enabled" (not muted)
        updateSoundIcon(not enabled)
    end)
end

local function bindButtons()
    if soundToggleButton then
        soundToggleButton.Activated:Connect(function()
            if SoundPlayer.getIsMuted() then
                SoundPlayer.setMuted(false)
            else
                SoundPlayer.setMuted(true)
            end
        end)
    end

    if musicToggleButton then
        musicToggleButton.Activated:Connect(function()
            if MusicPlayer.isEnabled() then
                MusicPlayer.disable()
            else
                MusicPlayer.enable()
            end
        end)
    end
end

local function setInitialIcons()
    updateSoundIcon(SoundPlayer.getIsMuted())

    local musicEnabled = true
    if MusicPlayer.isEnabled then
        musicEnabled = MusicPlayer.isEnabled()
    end
    updateMusicIcon(musicEnabled)
end

function PCSettingsWidget.onLoaded()
    if PlatformDetector.getPlatform() ~= "PC" then
        return
    end

    widgetGui = GuiAssets:WaitForChild("Settings"):WaitForChild("SettingWidget") :: Frame
    widgetGui.Visible = true
    widgetGui.Parent = Screens.general

    soundToggleButton = widgetGui.Sound.Clickable
    soundIcon = widgetGui.Sound.ImageLabel

    musicToggleButton = widgetGui.Music.Clickable
    musicIcon = widgetGui.Music.ImageLabel

    setInitialIcons()
    bindToggleSignals()
    bindButtons()
end

return PCSettingsWidget
