local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local TweenService = game:GetService("TweenService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local CoinSound = "rbxassetid://607665037"



local SummaryWidget = {}

local record = {}

local onClose: (() -> ())?

local SummaryWidgetGui: Frame
local statsFrame: Frame
local countDownLabel: TextLabel
local closeButtonClickable: TextButton

local countdownNonce = 0
local currentTween: Tween? = nil
local targetPosition: UDim2? = nil
local offscreenPosition: UDim2? = nil

export type Record = {
	timeAlive: number,
	blocksDestroyed: number,
	eliminations: number,
	coinsGained: number,
	xpGained: number,
	winnerBonus: number?,
}

local TWEEN_IN = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local function startCountdown(seconds: number)
	countdownNonce += 1
	local myNonce = countdownNonce

	if not countDownLabel then
		task.spawn(function()
			task.wait(seconds)
			if countdownNonce == myNonce then
				SummaryWidget.hide()
			end
		end)
		return
	end

	countDownLabel.Visible = true
	task.spawn(function()
		local remaining = math.max(0, math.floor(seconds))
		while remaining > 0 and countdownNonce == myNonce and SummaryWidgetGui.Visible do
			countDownLabel.Text = ("Closing in %d second%s"):format(remaining, remaining == 1 and "" or "s")
			task.wait(1)
			remaining -= 1
		end

		if countdownNonce == myNonce and SummaryWidgetGui.Visible then
			countDownLabel.Text = "Closing…"
			SummaryWidget.hide()
		end
	end)
end

local function stopTween()
	if currentTween then
		currentTween:Pause()
		currentTween:Destroy()
		currentTween = nil
	end
end

local function ensurePositions()
	if not SummaryWidgetGui then
		return
	end
	if not targetPosition then
		targetPosition = SummaryWidgetGui.Position
	end
	if not offscreenPosition then
		local anchor = SummaryWidgetGui.AnchorPoint
		-- Slide from bottom: y below screen. Keep x the same as target.
		offscreenPosition = UDim2.new(targetPosition.X.Scale, targetPosition.X.Offset, 1 + anchor.Y + 0.2, 0)
	end
end

function SummaryWidget.onProfileLoaded()
	if PlatformDetector.getPlatform() == "MOBILE" then
		SummaryWidgetGui = GuiAssets.Intermission.SummaryWidgetMobile
	else
		SummaryWidgetGui = GuiAssets.Intermission.SummaryWidget
	end

	SummaryWidgetGui.Parent = Screens.intermissionHUD
	SummaryWidgetGui.Visible = false

	statsFrame = SummaryWidgetGui.Stats
	closeButtonClickable = SummaryWidgetGui.CloseButton.Clickable
	countDownLabel = SummaryWidgetGui.Timer

	ensurePositions()

	closeButtonClickable.Activated:Connect(function()
		countdownNonce += 1
		SummaryWidget.hide()
	end)

	RemoteEventHandler.newEventConnection("ROUND_SUMMARY", function(g_record: Record)
		record = g_record

		task.wait(1)

		SummaryWidget.show()
	end)
end

function SummaryWidget.connectOnClose(callback: () -> ())
	onClose = callback
end

function SummaryWidget.show()

	
	SoundPlayer.playSound(CoinSound)

	FrameSystem.setCurrent(SummaryWidgetGui)

	if not SummaryWidgetGui then
		return
	end

	statsFrame.Blocks.TextLabel.Text = tostring(record.blocksDestroyed or 0)
	statsFrame.Eliminations.TextLabel.Text = (tostring(record.eliminations or 0)) .. " KOs"
	statsFrame.TimeAlive.TextLabel.Text = tostring(math.floor(record.timeAlive or 0)) .. "s"
	SummaryWidgetGui.XpReward.Text = "+" .. tostring(record.xpGained or 0) .. "Xp"
	SummaryWidgetGui.CoinsReward.Text = "+" .. tostring(record.coinsGained or 0) .. "C"

	if record.winnerBonus and record.winnerBonus > 0 then
		SummaryWidgetGui.WinBonus.Text = "+" .. tostring(record.winnerBonus) .. "C (winner bonus)"
	else
		SummaryWidgetGui.WinBonus.Text = ""
	end

	ensurePositions()
	stopTween()

	SummaryWidgetGui.Visible = true
	if offscreenPosition then
		SummaryWidgetGui.Position = offscreenPosition
	end

	currentTween = TweenService:Create(SummaryWidgetGui, TWEEN_IN, { Position = targetPosition })
	currentTween:Play()
	currentTween.Completed:Connect(function()
		if currentTween then
			currentTween:Destroy()
			currentTween = nil
		end
	end)

	startCountdown(8)
end

function SummaryWidget.hide()
	if not SummaryWidgetGui or not SummaryWidgetGui.Visible then
		return
	end

	FrameSystem.setCurrent(nil)

	ensurePositions()
	stopTween()

	local goal = { Position = offscreenPosition }
	currentTween = TweenService:Create(SummaryWidgetGui, TWEEN_OUT, goal)
	currentTween:Play()

	if onClose then
		onClose()
	end

	currentTween.Completed:Connect(function()
		if countdownNonce then
			countdownNonce += 1
		end
		if countDownLabel then
			countDownLabel.Visible = false
		end
		SummaryWidgetGui.Visible = false
		if currentTween then
			currentTween:Destroy()
			currentTween = nil
		end
		if targetPosition then
			SummaryWidgetGui.Position = targetPosition
		end
	end)
end

return SummaryWidget
