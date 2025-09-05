-- Module: TutorialAmmo.lua
-- Purpose: Standalone ammo HUD for tutorial/intermission with arrow animation

local TutorialAmmo = {}

local TweenService = game:GetService("TweenService")
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)


-- State
local AmmoGui: Frame?
local Arrow: ImageLabel?
local _currentAmmo: number = 0
local _maxAmmo: number = 0
local _infinite: boolean = false

-- arrow tween control
local _arrowTween: Tween?
local _arrowRunning: boolean = false

-- Internal: ensure UI exists and is parented
local function ensureGui()
	if AmmoGui and AmmoGui.Parent then
		return
	end

	AmmoGui = GuiAssets:WaitForChild("Tutorial"):WaitForChild("Ammo")
	AmmoGui.Name = "TutorialAmmo"
	AmmoGui.Parent = Screens.intermissionHUD
    AmmoGui.Visible = ClientStateTracker.getState() == "TUTORIAL"

	-- find arrow
	Arrow = AmmoGui:FindFirstChild("Arrow") :: ImageLabel
	if Arrow then
		Arrow.Visible = false
	end

	-- Default visual state
	AmmoGui.OutOfAmmo.Visible = true
	if AmmoGui:FindFirstChild("UIScale") then
		AmmoGui.UIScale.Scale = 1
	end

	-- Mobile positioning tweak
	if PlatformDetector.getPlatform() == "MOBILE" then
		AmmoGui.AnchorPoint = Vector2.new(AmmoGui.AnchorPoint.X, 1)
		local touchButtonsGui = TouchButtons.getGui()
		if touchButtonsGui then
			local yScale = touchButtonsGui.Position.Y.Scale - touchButtonsGui.Size.Y.Scale
			AmmoGui.Position = UDim2.new(UDim.new(1, 0), UDim.new(yScale, 0))
		end
		if AmmoGui:FindFirstChild("UIScale") then
			AmmoGui.UIScale.Scale = 1.2
		end
	end
end

-- Internal: reflect state to GUI
local function render()
	if not AmmoGui then return end

	if _infinite then
		AmmoGui.Count.Text = "∞"
		AmmoGui.OutOfAmmo.Visible = false
	else
		AmmoGui.Count.Text = string.format("%d / %d", math.max(_currentAmmo, 0), math.max(_maxAmmo, 0))
		AmmoGui.OutOfAmmo.Visible = (_currentAmmo <= 0)
	end
end

-- Internal: arrow animation loop
local function startArrowAnimation()
	if not Arrow or _arrowRunning then return end
	_arrowRunning = true

	task.spawn(function()
		while _arrowRunning and Arrow and Arrow.Visible do
			-- left position
			local leftTween = TweenService:Create(
				Arrow,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Position = UDim2.new(Arrow.Position.X.Scale - 0.05, 0, Arrow.Position.Y.Scale, 0) }
			)
			leftTween:Play()
			leftTween.Completed:Wait()

			if not _arrowRunning or not Arrow.Visible then break end

			-- right position
			local rightTween = TweenService:Create(
				Arrow,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ Position = UDim2.new(Arrow.Position.X.Scale + 0.05, 0, Arrow.Position.Y.Scale, 0) }
			)
			rightTween:Play()
			rightTween.Completed:Wait()
		end
	end)
end

local function stopArrowAnimation()
	_arrowRunning = false
	if _arrowTween then
		_arrowTween:Cancel()
		_arrowTween = nil
	end
end

-- Public: call once after profile/screens are ready
function TutorialAmmo.onProfileLoaded()
	ensureGui()
	_currentAmmo = 0
	_maxAmmo = 0
	_infinite = false
	render()

    ClientStateTracker.connectTutorial(function()
		AmmoGui.Visible = true
	end)

	ClientStateTracker.connectIntermission(function()
		AmmoGui.Visible = false
	end)

    TutorialAmmo.setMax(20)

end

-- Public ammo methods
function TutorialAmmo.setInfinite(isInfinite: boolean)
	ensureGui()
	_infinite = isInfinite == true
	render()
end

function TutorialAmmo.set(current: number, maxAmmo: number)
	ensureGui()
	_infinite = false
	_currentAmmo = math.max(0, math.floor(current or 0))
	_maxAmmo = math.max(0, math.floor(maxAmmo or 0))
	render()
end

function TutorialAmmo.setMax(maxAmmo: number)
	ensureGui()
	_infinite = false
	_maxAmmo = math.max(0, math.floor(maxAmmo or 0))
	if _currentAmmo > _maxAmmo then
		_currentAmmo = _maxAmmo
	end
	render()
end

function TutorialAmmo.increment(delta: number)
	ensureGui()
	if _infinite then return end
	delta = math.floor(delta or 0)
	_currentAmmo = math.clamp(_currentAmmo + delta, 0, _maxAmmo)
	render()
end

function TutorialAmmo.reset()
	ensureGui()
	_infinite = false
	_currentAmmo = 0
	render()
end

-- Public arrow methods
function TutorialAmmo.setArrowVisible(isVisible: boolean)
	ensureGui()
	if not Arrow then return end

	Arrow.Visible = isVisible
	if isVisible then
		startArrowAnimation()
	else
		stopArrowAnimation()
	end
end

function TutorialAmmo.showArrow()
	TutorialAmmo.setArrowVisible(true)
end

function TutorialAmmo.hideArrow()
	TutorialAmmo.setArrowVisible(false)
end

function TutorialAmmo.getState()
	return {
		current = _currentAmmo,
		max = _maxAmmo,
		infinite = _infinite,
		gui = AmmoGui,
	}
end

return TutorialAmmo
