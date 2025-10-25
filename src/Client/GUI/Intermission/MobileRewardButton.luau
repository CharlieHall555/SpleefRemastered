local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local TweenService = game:GetService("TweenService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)
local DailyRewards = require(ClientModuleDirectory.Gui.DailyRewardsGui)

local MobileRewardButton = {}

local rotateInfo = TweenInfo.new(
    0.8, -- Time
    Enum.EasingStyle.Quad, -- EasingStyle
    Enum.EasingDirection.InOut, -- EasingDirection
    -1, -- RepeatCount (negative = infinite)
    true, -- Reverses
    0.1 -- DelayTime
)


local ButtonGUI: Frame?
local RewardsStar : ImageLabel?


function MobileRewardButton.onLoaded()
	if PlatformDetector.getPlatform() ~= "MOBILE" then
		return
	end

	ButtonGUI = GuiAssets:WaitForChild("Intermission"):WaitForChild("MobileRewardButton")
	ButtonGUI.Visible = true
	ButtonGUI.Parent = Screens.touchControls

    RewardsStar = ButtonGUI.Star

    RewardsStar.Visible = (UserSessionVariables.getValue("hasRewardsToClaim") or false) == true

    UserSessionVariables.setOnUpdateCallback(function(valueName, newValue)
        
        if valueName == "hasRewardsToClaim" then
            RewardsStar.Visible = (newValue == true)
        end

    end , "hasRewardsToClaim")

    local starTween = TweenService:Create(RewardsStar, rotateInfo, {Rotation = 72})
    starTween:Play()

    ClientStateTracker.connectIntermission(function()
        ButtonGUI.Visible = true
    end)

    ClientStateTracker.connectActive(function()
        ButtonGUI.Visible = false
    end)

    ButtonGUI.Clickable.Activated:Connect(function()
        DailyRewards.show()
    end)

    ClientStateTracker.connectTutorial(function()
        ButtonGUI.Visible = false
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

return MobileRewardButton
