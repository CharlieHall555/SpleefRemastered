local DailyRewards = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local RewardsData = require(ClientModuleDirectory.RewardsData)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local onClaimableChanged : (claimable : boolean) -> ()

local DailyRewardsGui: Frame?
local main: Frame

local COIN_IMAGE = "rbxassetid://99780735877626"
local LIVE_IMAGE = "rbxassetid://77250827436146"

local currentDay = nil

local CloseButtonClickable: TextButton?

function DailyRewards.loadRewards()

    for i = 1, 3 do
		local givenClaimable = main[i]
		
        local reward = RewardsData[currentDay or "SUNDAY"][i]

        if reward.currency == "COINS" then
            givenClaimable.Main.CurrencyImage.Image = COIN_IMAGE
            givenClaimable.Main.TextLabel.Text = "+" .. tostring(reward.amount) .. "C"
            givenClaimable.Main.TextLabel.TextColor3 = Color3.fromRGB(255, 205, 23)
        elseif reward.currency == "LIVES"  then
            givenClaimable.Main.CurrencyImage.Image = LIVE_IMAGE
            givenClaimable.Main.TextLabel.Text = "+" .. tostring(reward.amount) .. " Lives"
            givenClaimable.Main.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end

	end
  
end

local hasClaimableNow = false

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

	-- fire only when it changes
	if newHasClaimable ~= hasClaimableNow then
		hasClaimableNow = newHasClaimable
		onClaimableChanged(hasClaimableNow)
	end
end

function DailyRewards.hasClaimable()
	return hasClaimableNow
end

function DailyRewards.connectOnClaimableChanged(fn : (claimable : boolean) -> ())

	onClaimableChanged = fn
	
end

function DailyRewards.refreshTimers()

    for i = 1, 3 do
		local givenClaimable = main[i]
        
		local timeRequired = RewardsData[i]

        local playTime = UserSessionVariables.getValue("playTime") or 0

        local timeLeft = math.max(timeRequired - playTime, 0)

        if timeLeft <= 0 then
            givenClaimable.Claim.Locked.Visible = false
        else
            givenClaimable.Claim.Locked.Visible = true

        end

        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60

        givenClaimable.Claim.Locked.Timer.Text = string.format("%02d:%02d", minutes, seconds)

	end
    
end

function DailyRewards.refreshClaimed()
	local claimedRewards = UserProfile.getValue("dailyRewardClaims") or {}

    print("claimed = " , claimedRewards)

	for i = 1, 3 do
		local givenClaimable = main[i]
		local claimed = (table.find(claimedRewards, i) ~= nil)

		if claimed then
			givenClaimable.Main.CheckMark.Visible = true
			givenClaimable.Claim.Visible = false
		else
			givenClaimable.Main.CheckMark.Visible = false
			givenClaimable.Claim.Visible = true
		end
	end
end

function DailyRewards.getGui()
	return DailyRewardsGui
end

function DailyRewards.init()

	task.spawn(function()
		currentDay = RemoteEventHandler.InvokeOnServer("QUERY_DAY" , 5)
		if currentDay == nil then
			currentDay = os.date("!%A")
        	currentDay = string.upper(currentDay)
		end
	end)
end

function DailyRewards.onProfileLoaded()
	DailyRewardsGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("RewardMenu"):Clone()
	DailyRewardsGui.Parent = Screens.intermissionHUD
	DailyRewardsGui.Visible = false

	main = DailyRewardsGui.Main

	if PlatformDetector.getPlatform() == "MOBILE" then
		DailyRewardsGui.Size = UDim2.fromScale(0.85, 0.85)
	else
		DailyRewardsGui.Size = UDim2.fromScale(0.51, 0.584)
	end

	CloseButtonClickable = DailyRewardsGui.CloseButton.Clickable

	CloseButtonClickable.Activated:Connect(function()
		DailyRewards.hide()
	end)

	-- Hook changes (you already call refresh* here; just add recompute):
	UserProfile.setOnUpdateCallback(function()
		recomputeHasClaimable()
		DailyRewards.refreshClaimed()
	end, "dailyRewardClaims")

	UserSessionVariables.setOnUpdateCallback(function()
		recomputeHasClaimable()
		DailyRewards.refreshTimers()
	end, "playTime")

	main[1].Claim.Clickable.Activated:Connect(function(inputObject, clickCount)
		RemoteEventHandler.FireOnServer("CLAIM_REWARD", 1)
		local coinSound = "rbxassetid://86832085549408"
		SoundPlayer.playSound(coinSound) 
	end)

	main[2].Claim.Clickable.Activated:Connect(function(inputObject, clickCount)
		RemoteEventHandler.FireOnServer("CLAIM_REWARD", 2)
		local coinSound = "rbxassetid://86832085549408"
		SoundPlayer.playSound(coinSound)
	end)

	main[3].Claim.Clickable.Activated:Connect(function(inputObject, clickCount)
		RemoteEventHandler.FireOnServer("CLAIM_REWARD", 3)
		local coinSound = "rbxassetid://86832085549408"
		SoundPlayer.playSound(coinSound)
	end)

	RemoteEventHandler.newEventConnection("DAILY_REWARDS_RESET", function(newDay : string)

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
