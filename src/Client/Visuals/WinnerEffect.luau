local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Players = game:GetService("Players")
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local LocalPlayer = Players.LocalPlayer
local UIParticleEmitter = require(ClientModuleDirectory.Libs.UIParticleEmitter)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local TweenService = game:GetService("TweenService")
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local SummaryWidget = require(ClientModuleDirectory.Gui.SummaryWidget)

local WinnerEffect = {}

local winnerWidget: Frame?
local label: TextLabel
local particleTemplate: ImageLabel?
local hook1: Frame
local hook2: Frame



-- helper to create a configured emitter
local function createEmitter(hook: Frame, color: Color3): any
	local emitter = UIParticleEmitter.new(hook, particleTemplate)
	emitter.Orientation = "VELOCITY_PARALLEL"
	emitter.RotSpeed = NumberRange.new(0)
	emitter.Rate = 0
	emitter.Color = color
	emitter.ZOffset = 9
	emitter.Size = Vector2.new(0.5, 0.5)
	emitter.Lifetime = NumberRange.new(1.0, 1.6)
	emitter.xSpeed = NumberRange.new(0, 0)
	emitter.ySpeed = NumberRange.new(150, 220)
	emitter.SpreadAngle = NumberRange.new(0, 360)
	emitter.Acceleration = Vector2.new(0, -120)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(0.55, 0.35),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	return emitter
end

local emitter1
local emitter2
local emitter3
local emitter4

-- queue + debounce for intermission-only play
local pendingWin: { name: string, player: Player? }? = nil
local playedThisIntermission = false

local function tryPlayPendingIfAllowed()
	if ClientStateTracker.getState() ~= "INTERMISSION" then
		return
	end
	if playedThisIntermission then
		return
	end
	if pendingWin then
		playedThisIntermission = true
		if pendingWin.name and pendingWin.player then
			WinnerEffect.onWin(pendingWin.name, pendingWin.player)
		else
			WinnerEffect.onNobodyWins()
		end

		pendingWin = nil
	end
end

function WinnerEffect.onProfileLoaded()
	winnerWidget = GuiAssets.Intermission:WaitForChild("winnerWidget")
	particleTemplate = GuiAssets.Intermission:WaitForChild("Particle")
	label = winnerWidget.Label
	winnerWidget.Visible = false
	winnerWidget.Parent = Screens.intermissionHUD

	hook1 = winnerWidget:WaitForChild("Hook1")
	hook2 = winnerWidget:WaitForChild("Hook2")

	-- Create emitters
	emitter1 = createEmitter(hook1, Color3.fromRGB(255, 255, 255))
	emitter2 = createEmitter(hook1, Color3.fromRGB(250, 254, 131))
	emitter3 = createEmitter(hook2, Color3.fromRGB(255, 255, 255))
	emitter4 = createEmitter(hook2, Color3.fromRGB(250, 254, 131))

	-- Event can arrive any time; only play during INTERMISSION (queued otherwise)
	RemoteEventHandler.newEventConnection("PLAYER_WON", function(playerName: string, winner: Player)
		pendingWin = { name = playerName, player = winner }
	end)

	-- When we enter intermission, reset debounce and play pending once
	ClientStateTracker.connectIntermission(function()
		playedThisIntermission = false
	end)

	SummaryWidget.connectOnClose(function()
		tryPlayPendingIfAllowed()
	end)


end

local function fireworkEffect()
	SoundPlayer.playSound("rbxassetid://9113263649")
	emitter1:Emit(15)
	emitter2:Emit(15)

	task.wait(0.5)
	SoundPlayer.playSound("rbxassetid://9113263649")
	emitter3:Emit(15)
	emitter4:Emit(15)

	task.wait(0.65)
	emitter1:Emit(15)
	emitter2:Emit(15)
	SoundPlayer.playSound("rbxassetid://9113263649")

	task.wait(0.85)
	emitter3:Emit(15)
	emitter4:Emit(15)
	SoundPlayer.playSound("rbxassetid://9113263649")
end

function WinnerEffect.onNobodyWins() end

function WinnerEffect.onWin(winnerName: string, winner: Player?)
	task.spawn(function()

		local display = (winner and winner.DisplayName) or winnerName or "Winner"
		label.Text = display .. " Won"

		-- Target is wherever the widget is placed in Studio (center/top area of intermission HUD)
		local targetPos: UDim2 = winnerWidget.Position
		local offscreenTop = UDim2.fromScale(0.5, -winnerWidget.Size.Y.Scale) -- centered, above the screen

		-- Prepare entrance: start above screen, show, then tween down to target
		winnerWidget.Visible = true
		winnerWidget.Position = offscreenTop

		SoundPlayer.playSound("rbxassetid://113939513589596", { volume = 0.4 })
		local inTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local inTween = TweenService:Create(winnerWidget, inTweenInfo, { Position = targetPos })
		inTween:Play()
		inTween.Completed:Wait()

		-- Play fireworks once the banner has landed
		fireworkEffect()

		-- Hold on-screen for a moment to let the moment land
		task.wait(2.25)

		-- Slide back up and hide
		local outTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local outTween = TweenService:Create(winnerWidget, outTweenInfo, { Position = offscreenTop })
		outTween:Play()
		outTween.Completed:Wait()

		winnerWidget.Visible = false
		-- restore to targetPos so future entrances know their destination
		winnerWidget.Position = targetPos
	end)
end

return WinnerEffect
