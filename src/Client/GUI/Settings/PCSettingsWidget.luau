local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local MusicPlayer = require(ClientModuleDirectory.Sound.MusicPlayer)
local Shop = require(ClientModuleDirectory.Gui.Shop.Main)
local DailyRewards = require(ClientModuleDirectory.Gui.DailyRewardsGui)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)
local RewardsData = require(ClientModuleDirectory.RewardsData)

local PCSettingsWidget = {}

local widgetGui: Frame?

local rotateInfo = TweenInfo.new(
    0.8, -- Time
    Enum.EasingStyle.Quad, -- EasingStyle
    Enum.EasingDirection.InOut, -- EasingDirection
    -1, -- RepeatCount (negative = infinite)
    true, -- Reverses
    0.1 -- DelayTime
)

local SOUND_ON_IMAGE = "rbxassetid://102335554495793"
local SOUND_OFF_IMAGE = "rbxassetid://108653430274728"
local MUSIC_ON_IMAGE = "rbxassetid://110651581351042"
local MUSIC_OFF_IMAGE = "rbxassetid://92620108688852"

local soundToggleButton: TextButton?
local ShopButton : TextButton?
local RewardsButton : TextButton?
local musicToggleButton: TextButton?
local soundIcon: ImageLabel?
local musicIcon: ImageLabel?

local RewardsStar : ImageLabel?

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

    if ShopButton then
        
        ShopButton.Clickable.Activated:Connect(function(inputObject, clickCount)
            
            if Shop.getVisible() then
                Shop.hide()
            else
                Shop.show()
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

function PCSettingsWidget.setStarVisible(value : boolean)
    if RewardsStar then
        RewardsStar.Visible = value
    end
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

    ShopButton = widgetGui.Shop
    RewardsButton = widgetGui.Rewards
    RewardsStar = widgetGui.Rewards.Star

    local starTween = TweenService:Create(RewardsStar, rotateInfo, {Rotation = 72})
    starTween:Play()

    
    musicToggleButton = widgetGui.Music.Clickable
    musicIcon = widgetGui.Music.ImageLabel

    ClientStateTracker.connectActive(function()
        ShopButton.Visible = false
        RewardsButton.Visible = false
    end)

    ClientStateTracker.connectIntermission(function()
        ShopButton.Visible = true
        RewardsButton.Visible = true
    end)

    setInitialIcons()
    bindToggleSignals()
    bindButtons()

    RewardsButton.Clickable.Activated:Connect(function()
        if DailyRewards.getGui().Visible then
            DailyRewards.hide()
        else    
            DailyRewards.show()
        end
    end)

    RewardsStar.Visible = DailyRewards.hasClaimable()

    DailyRewards.connectOnClaimableChanged(function(claimable)
        
        RewardsStar.Visible = claimable
        if claimable then
            if ClientStateTracker.getState() == "INTERMISSION" then
                local DING_SOUND = "rbxassetid://75368614305052"
		        SoundPlayer.playSound(DING_SOUND)
            end
        end

    end)

end

return PCSettingsWidget
