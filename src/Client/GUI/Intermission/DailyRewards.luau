---@diagnostic disable: invalid-class-name
local DailyRewards = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local RewardsData = require(ClientModuleDirectory.RewardsData)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local COIN_IMAGE = "rbxassetid://99780735877626"
local LIVE_IMAGE = "rbxassetid://77250827436146"
local CLAIM_SOUND = "rbxassetid://86832085549408"

local onClaimableChanged: (claimable: boolean) -> () = function() end

local DailyRewardsGui: Frame?
local main: Frame?

local currentDay: string? = nil
local CloseButtonClickable: TextButton?

local hasClaimableNow = false

local function safeGetMainChild(index: number): Frame?
    if not main then
        return nil
    end
    local child = main[index]
    if typeof(child) == "Instance" and child:IsA("Frame") then
        return child
    end
    return nil
end

local function recomputeHasClaimable()
    local playTime = UserSessionVariables.getValue("playTime") or 0
    local claimed = UserProfile.getValue("dailyRewardClaims") or {}
    local newHasClaimable = false

    for i = 1, 3 do
        local timeRequired = RewardsData[i]
        if playTime >= timeRequired and not table.find(claimed, i) then
            newHasClaimable = true
            break
        end
    end

    if newHasClaimable ~= hasClaimableNow then
        hasClaimableNow = newHasClaimable
        onClaimableChanged(hasClaimableNow)
    end
end

function DailyRewards.hasClaimable()
    return hasClaimableNow
end

function DailyRewards.connectOnClaimableChanged(fn: (claimable: boolean) -> ())
    onClaimableChanged = fn or function() end
end

function DailyRewards.loadRewards()
    local day = currentDay or "SUNDAY"
    for i = 1, 3 do
        local givenClaimable = safeGetMainChild(i)
        if givenClaimable then
            local reward = RewardsData[day][i]
            if reward.currency == "COINS" then
                givenClaimable.Main.CurrencyImage.Image = COIN_IMAGE
                givenClaimable.Main.TextLabel.Text = "+" .. tostring(reward.amount) .. "C"
                givenClaimable.Main.TextLabel.TextColor3 = Color3.fromRGB(255, 205, 23)
            elseif reward.currency == "LIVES" then
                givenClaimable.Main.CurrencyImage.Image = LIVE_IMAGE
                givenClaimable.Main.TextLabel.Text = "+" .. tostring(reward.amount) .. " Lives"
                givenClaimable.Main.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end

function DailyRewards.refreshTimers()
    for i = 1, 3 do
        local givenClaimable = safeGetMainChild(i)
        if givenClaimable then
            local timeRequired = RewardsData[i]
            local playTime = UserSessionVariables.getValue("playTime") or 0
            local timeLeft = math.max(timeRequired - playTime, 0)

            givenClaimable.Claim.Locked.Visible = timeLeft > 0

            local minutes = math.floor(timeLeft / 60)
            local seconds = timeLeft % 60
            givenClaimable.Claim.Locked.Timer.Text = string.format("%02d:%02d", minutes, seconds)
        end
    end
end

function DailyRewards.refreshClaimed()
    local claimedRewards = UserProfile.getValue("dailyRewardClaims") or {}
    for i = 1, 3 do
        local givenClaimable = safeGetMainChild(i)
        if givenClaimable then
            local alreadyClaimed = table.find(claimedRewards, i) ~= nil
            givenClaimable.Main.CheckMark.Visible = alreadyClaimed
            givenClaimable.Claim.Visible = not alreadyClaimed
        end
    end
end

function DailyRewards.getGui()
    return DailyRewardsGui
end

function DailyRewards.init()
    task.spawn(function()
        currentDay = RemoteEventHandler.InvokeOnServer("QUERY_DAY", 5)
        if currentDay == nil then
            local fallback = os.date("!%A")
            currentDay = string.upper(fallback)
        end
    end)
end

function DailyRewards.onProfileLoaded()
    DailyRewardsGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("RewardMenu"):Clone()
    DailyRewardsGui.Parent = Screens.intermissionHUD
    DailyRewardsGui.Visible = false

    main = DailyRewardsGui:FindFirstChild("Main") :: Frame

    if PlatformDetector.getPlatform() == "MOBILE" then
        DailyRewardsGui.Size = UDim2.fromScale(0.85, 0.85)
    else
        DailyRewardsGui.Size = UDim2.fromScale(0.51, 0.584)
    end

    CloseButtonClickable = DailyRewardsGui.CloseButton.Clickable
    CloseButtonClickable.Activated:Connect(function()
        DailyRewards.hide()
    end)

    UserProfile.setOnUpdateCallback(function()
        recomputeHasClaimable()
        DailyRewards.refreshClaimed()
    end, "dailyRewardClaims")

    UserSessionVariables.setOnUpdateCallback(function()
        recomputeHasClaimable()
        DailyRewards.refreshTimers()
    end, "playTime")

    local function hookClaim(buttonIndex: number)
        local btnFrame = safeGetMainChild(buttonIndex)
        if not btnFrame then
            return
        end
        local clickable = btnFrame.Claim.Clickable
        if clickable and clickable:IsA("TextButton") then
            clickable.Activated:Connect(function()
                RemoteEventHandler.FireOnServer("CLAIM_REWARD", buttonIndex)
                SoundPlayer.playSound(CLAIM_SOUND)
            end)
        end
    end

    hookClaim(1)
    hookClaim(2)
    hookClaim(3)

    RemoteEventHandler.newEventConnection("DAILY_REWARDS_RESET", function(newDay: string)
        currentDay = newDay
        DailyRewards.loadRewards()
        DailyRewards.refreshClaimed()
        DailyRewards.refreshTimers()
        recomputeHasClaimable()
    end)

    DailyRewards.loadRewards()
    DailyRewards.refreshClaimed()
    DailyRewards.refreshTimers()
    recomputeHasClaimable()
end

function DailyRewards.show()
    if not DailyRewardsGui then
        return
    end
    DailyRewardsGui.Visible = true
    FrameSystem.setCurrent(DailyRewardsGui)
end

function DailyRewards.hide()
    if not DailyRewardsGui then
        return
    end
    DailyRewardsGui.Visible = false
    FrameSystem.setCurrent(nil)
end

return DailyRewards
