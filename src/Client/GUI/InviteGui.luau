--//====================================================
--// Imports / Services
--//====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GUIAssets = game:GetService("ReplicatedStorage").GUIAssets
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")

local InivtePopup = {}
--//====================================================
--// Local Variable
--//====================================================

--Module loaded safely variable, no connection can be made if this is false
local loadedSafely = false

local waiting = false
local canInvite = false

local InivteGUI: Frame

--//====================================================
--// Local Function
--//====================================================
local function startBreathAnimation()
	local InviteButton: TextButton? = InivteGUI:WaitForChild("Invite", 4)
	if not InviteButton then return end

	-- Reuse / create UIScale so we don't mess with Size/AnchorPoint/layout
	local scale: UIScale = InviteButton:FindFirstChildOfClass("UIScale") 
		or Instance.new("UIScale")
	scale.Parent = InviteButton
	scale.Scale = 1

	-- Prevent stacking multiple tweens
	if scale:FindFirstChild("BreathTween") then return end

	local breathInfo = TweenInfo.new(
		1.6,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		math.huge,
		true,
		0
	)

	local tween = TweenService:Create(scale, breathInfo, { Scale = 1.05 })
	tween.Name = "BreathTween"
	tween.Parent = scale
	tween:Play()

	InviteButton.AncestryChanged:Connect(function(_, parent)
		if not parent and tween.PlaybackState ~= Enum.PlaybackState.Completed then
			tween:Cancel()
		end
	end)
end

local function startUp()
	canInvite = SocialService:CanSendCallInviteAsync(LocalPlayer)

	InivteGUI = GUIAssets:WaitForChild("InviteFriend", 5)
	if InivteGUI == nil then
		error("Invite GUI Missing.")
		return
	end
    startBreathAnimation()
	InivteGUI.Parent = LocalPlayer.PlayerGui.General
end

local function onWaiting()
	task.spawn(function()
		task.wait(3)
		if waiting and canInvite then
			InivteGUI.Visible = true
		end
	end)
end

--//====================================================
--// Exposed Function
--//====================================================
function InivtePopup.onProfileLoaded()
	local s, r = pcall(startUp)
	loadedSafely = s

	if loadedSafely == false then
		return
	end

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "WAITING" then
			waiting = true
			onWaiting()
		else
			waiting = false
			InivteGUI.Visible = false
		end
	end)

	local InviteButton: TextButton? = InivteGUI:WaitForChild("Invite", 4)
	if InviteButton then
		InviteButton.Activated:Connect(function(inputObject, clickCount)
			SocialService:PromptGameInvite(LocalPlayer)
			InivteGUI.Visible = false
		end)
	end
	local CloseButton: TextButton? = InivteGUI:WaitForChild("Close", 4)
	CloseButton.Activated:Connect(function(inputObject, clickCount)
		InivteGUI.Visible = false
	end)
end

return InivtePopup
