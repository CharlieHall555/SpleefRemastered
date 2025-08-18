local Root = game.Players.LocalPlayer.PlayerScripts
local LocalPlayer = game.Players.LocalPlayer
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local TransitionFrame: Frame?

local tweenInfo = TweenInfo.new(
	0.5, -- time
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.In
)

local current: Tween?

local Transition = {}

function Transition.onLoaded()
	TransitionFrame = GuiAssets:WaitForChild("TransitionFrame", 6)
	assert(TransitionFrame, "TransitionFrame Missing.")

	TransitionFrame.Parent = LocalPlayer.PlayerGui.General
	TransitionFrame.Visible = false

	ClientStateTracker.connectRoundStarting(function()
		current = Transition.show()
	end)

	ClientStateTracker.connectActive(function()
		task.spawn(function()
			if current and current.PlaybackState == Enum.PlaybackState.Playing then
				current.Completed:Wait()
			end
			current = Transition.hide()
		end)
	end)
end

local TweenService = game:GetService("TweenService")

function Transition.show(): Tween
	TransitionFrame.Position = UDim2.fromScale(0.5, -0.5)
	TransitionFrame.Visible = true

	local tween = TweenService:Create(TransitionFrame, tweenInfo, { Position = UDim2.fromScale(0.5, 0.5) })
	tween:Play()
	return tween
end

function Transition.hide(): Tween
	local tween = TweenService:Create(TransitionFrame, tweenInfo, { Position = UDim2.fromScale(0.5, -0.5) })
	tween:Play()

	tween.Completed:Once(function()
		TransitionFrame.Visible = false
	end)
	return tween
end

return Transition
