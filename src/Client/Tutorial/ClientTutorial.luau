local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local HighlightBlocks = require(ClientModuleDirectory.HighlightBlocks)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local CheerEffect = require(ClientModuleDirectory.CheerEffect)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local TutorialAmmo = require(ClientModuleDirectory.Gui.TutorialAmmo)
local TutorialAnnouncer = require(ClientModuleDirectory.TutorialAnnouncer)

local GuiAssets = ReplicatedStorage:WaitForChild("GuiAssets")
local TutorialFolder = GuiAssets:WaitForChild("Tutorial")

local cheerSound = "rbxassetid://112085968457085"
local SWIPE = "rbxassetid://10128766965"

export type TutorialStep = {
	step: number,
	name: string,
	actionToComplete: string,
	guiElement: GuiObject,
	displayTime: number?, -- auto-complete after N seconds (optional)
	delayBeforeNext: number?, -- keep prompt visible for N seconds after completion (per-step)
	onUpdate: ((dt: number) -> ())?,
	onEnd: (() -> ())?,
}

local ClientTutorial = {} :: any

-- =====================
-- State
-- =====================
local steps: { TutorialStep } = {}
local currentStepIndex = 0
local onNewStep: (stepNumber: number) -> () = function() end
local onComplete: () -> () = function() end
local updateConn: RBXScriptConnection? = nil
local _isAdvancing = false -- guard against double-advance
local _enabled = true -- tutorial active toggle
local _token = 0 -- cancels pending delayed tasks when changed

local SELECTION_DISTANCE: number = 30
local STANDARD_STEP_GAP = 2.0 -- fixed delay between step UIs being SHOWN

-- =====================
-- Helpers (UI)
-- =====================
local function createGuiFromTemplate(childName: string): GuiObject
	local template = TutorialFolder:FindFirstChild(childName)
	assert(template and template:IsA("GuiObject"), ("Tutorial UI '%s' missing or wrong type"):format(childName))
	local clone = template:Clone()
	clone.Visible = false
	clone.Parent = Screens.general
	return clone
end

local function personaliseWelcome()
	local first = steps[1]
	if not first then
		return
	end
	local label = first.guiElement:FindFirstChildWhichIsA("TextLabel", true)
	local displayName = (LocalPlayer.DisplayName or LocalPlayer.Name)
	if label then
		label.Text = "Welcome " .. displayName
	elseif (first.guiElement :: any).Text then
		(first.guiElement :: any).Text = "Welcome " .. displayName
	end
end

local function showStep(step: TutorialStep)
	if step and step.guiElement then
		step.guiElement.Visible = true
	end
end

local function hideStep(step: TutorialStep)
	if step and step.guiElement then
		step.guiElement.Visible = false
	end
end

local function hideAll()
	for _, s in steps do
		hideStep(s)
	end
end

local function disconnectUpdate()
	if updateConn then
		updateConn:Disconnect()
		updateConn = nil
	end
end

local function bindUpdateForCurrentStep()
	disconnectUpdate()
	local step = steps[currentStepIndex]
	if not step or not step.onUpdate then
		return
	end
	updateConn = RunService.RenderStepped:Connect(function(dt)
		if not _enabled then
			return
		end
		local cur = steps[currentStepIndex]
		if cur and cur.onUpdate then
			cur.onUpdate(dt)
		end
	end)
end

-- =====================
-- New flow helpers
-- =====================

-- Show current step, bind updates, and schedule auto-complete if displayTime is set.
local function showCurrentStepAndBind()
	local step = steps[currentStepIndex]
	if not step then
		return
	end

	showStep(step)
	bindUpdateForCurrentStep()

	-- Auto-complete after displayTime, if provided
	if step.displayTime and step.displayTime > 0 then
		local displayToken = _token
		task.spawn(function()
			task.wait(step.displayTime)
			if _enabled and displayToken == _token and steps[currentStepIndex] == step then
				ClientTutorial.onAction(step.actionToComplete)
			end
		end)
	end

	onNewStep(currentStepIndex)
end

-- Hide and end the current step immediately
local function hideAndEndCurrent()
	local step = steps[currentStepIndex]
	if step then
		hideStep(step)
		if step.onEnd then
			step.onEnd()
		end
	end
	disconnectUpdate()
end

-- After the global gap, advance index and show next step; otherwise complete.
local function goToNextStepAfterGap(prevToken: number)
	if not _enabled or prevToken ~= _token then
		return
	end
	currentStepIndex += 1
	local step = steps[currentStepIndex]
	if step then
		showCurrentStepAndBind()
	else
		hideAll()
		onComplete()
	end
end

-- Called when a step is completed (user action or auto-complete).
-- Keeps the prompt visible for delayBeforeNext, then hides it, waits STANDARD_STEP_GAP, then shows the next step.
local function completeCurrentStep()
	if _isAdvancing or not _enabled then
		return
	end
	_isAdvancing = true

	local myToken = _token
	local thisStep = steps[currentStepIndex]
	local keepVisibleDelay = (thisStep and thisStep.delayBeforeNext) or 0

	-- Phase 1: keep the prompt visible while we wait its per-step delay
	task.delay(keepVisibleDelay, function()
		if not _enabled or myToken ~= _token then
			_isAdvancing = false
			return
		end

		-- Phase 2: hide/end current step
		hideAndEndCurrent()

		-- Phase 3: wait global gap between steps being SHOWN, then advance
		task.delay(STANDARD_STEP_GAP, function()
			_isAdvancing = false
			goToNextStepAfterGap(myToken)
		end)
	end)
end

-- =====================
-- Public API
-- =====================

function ClientTutorial.onLoaded()
	SELECTION_DISTANCE = ClientBlockSelector.getMaxSelectionDistance()

	if PlatformDetector.getPlatform() == "MOBILE" then
		steps = {
			{
				step = 1,
				name = "Welcome",
				actionToComplete = "WELCOME_END",
				guiElement = createGuiFromTemplate("Welcome"),
				displayTime = 4,
			},
			{
				step = 2,
				name = "Tutorial",
				actionToComplete = "TUTORIAL_END",
				guiElement = createGuiFromTemplate("Tutorial"),
				displayTime = 4,
			},
			{
				step = 3,
				name = "Move",
				actionToComplete = "MOVE",
				guiElement = createGuiFromTemplate("Move"),
				delayBeforeNext = 1,
			},
			{
				step = 4,
				name = "Break",
				actionToComplete = "BREAK",
				guiElement = createGuiFromTemplate("Break_MOBILE"),
				delayBeforeNext = 1,
			},
			{
				step = 5,
				name = "Ammo",
				actionToComplete = "AMMO_END",
				guiElement = createGuiFromTemplate("AmmoTIP"),
				displayTime = 4,
				delayBeforeNext = 1,
			},
			{
				step = 6,
				name = "Shoot",
				actionToComplete = "SHOOT",
				guiElement = createGuiFromTemplate("Shoot_MOBILE"),
				delayBeforeNext = 1,
			},
			{
				step = 7,
				name = "KillDummy",
				actionToComplete = "KILL_DUMMY",
				guiElement = createGuiFromTemplate("Dummy"),
				delayBeforeNext = 1,
			},
			{
				step = 8,
				name = "Win",
				actionToComplete = "WIN_END",
				guiElement = createGuiFromTemplate("Win"),
				displayTime = 5,
			},
			{
				step = 9,
				name = "Complete",
				actionToComplete = "COMPLETE_END",
				guiElement = createGuiFromTemplate("Complete"),
				displayTime = 5,
			},
		}
	else
		steps = {
			{
				step = 1,
				name = "Welcome",
				actionToComplete = "WELCOME_END",
				guiElement = createGuiFromTemplate("Welcome"),
				displayTime = 3,
			},
			{
				step = 2,
				name = "Tutorial",
				actionToComplete = "TUTORIAL_END",
				guiElement = createGuiFromTemplate("Tutorial"),
				displayTime = 5,
			},
			{
				step = 3,
				name = "Move",
				actionToComplete = "MOVE",
				guiElement = createGuiFromTemplate("Move"),
				delayBeforeNext = 1,
			},
			{
				step = 4,
				name = "Break",
				actionToComplete = "BREAK",
				guiElement = createGuiFromTemplate("Break_PC"),
				delayBeforeNext = 1,
			},
			{
				step = 5,
				name = "Ammo",
				actionToComplete = "AMMO_END",
				guiElement = createGuiFromTemplate("AmmoTIP"),
				displayTime = 6,
				delayBeforeNext = 2.5,
			},
			{
				step = 6,
				name = "Shoot",
				actionToComplete = "SHOOT",
				guiElement = createGuiFromTemplate("Shoot_PC"),
				delayBeforeNext = 1,
			},
			{
				step = 7,
				name = "KillDummy",
				actionToComplete = "KILL_DUMMY",
				guiElement = createGuiFromTemplate("Dummy"),
				delayBeforeNext = 1,
			},
			{
				step = 8,
				name = "Win",
				actionToComplete = "WIN_END",
				guiElement = createGuiFromTemplate("Win"),
				displayTime = 6,
			},
			{
				step = 9,
				name = "Complete",
				actionToComplete = "COMPLETE_END",
				guiElement = createGuiFromTemplate("Complete"),
				displayTime = 5,
			},
		}
	end

	-- Example per-frame highlight callbacks (unchanged)
	ClientTutorial.setStepCallbacks(5, function()
		TutorialAmmo.showArrow()
	end, nil)

	ClientTutorial.setStepCallbacks(4, function()
		HighlightBlocks.within(SELECTION_DISTANCE)
	end, nil)

	ClientTutorial.setOnNewStep(function(stepNumber)

		TutorialAnnouncer.play(stepNumber)

		SoundPlayer.playSound(SWIPE)
		TutorialAmmo.hideArrow()
		HighlightBlocks.reset()
	end)

	ClientTutorial.setStepCallbacks(6, function()
		HighlightBlocks.outside(SELECTION_DISTANCE)
	end, nil)

	personaliseWelcome()
end

function ClientTutorial.getStep(): number
	return currentStepIndex
end

function ClientTutorial.onAction(actionName: string)
	if not _enabled then
		return
	end
	local step = steps[currentStepIndex]
	if step and actionName == step.actionToComplete then
		completeCurrentStep()
	end
end

function ClientTutorial.onProfileLoaded()
	RemoteEventHandler.newEventConnection("START_TUTORIAL", function(player)
		task.wait(1)
		if ClientStateTracker.getState() == "TUTORIAL" then
			ClientTutorial.startTutorial()
		end
	end)

	ClientTutorial.setOnComplete(function()
		RemoteEventHandler.FireOnServer("TUTORIAL_COMPLETED")
		SoundPlayer.playSound(cheerSound)
	end)

	ClientStateTracker.connectIntermission(function()
		ClientTutorial.disable()
	end)

	ClientStateTracker.connectActive(function()
		ClientTutorial.disable()
	end)

	RemoteEventHandler.newEventConnection("DUMMY_DIED" , function(player)
		
		if ClientTutorial.getStep() == 7 then
			ClientTutorial.onAction("KILL_DUMMY")
		end

	end)
end

function ClientTutorial.startTutorial()
	_enabled = true
	_token += 1 -- invalidate any old timers

	local character = LocalPlayer.Character
	local hrp = character and character.PrimaryPart
	if hrp then
		SoundPlayer.playSound(cheerSound)
		local head = character:FindFirstChild("Head")
		local pos = (head or hrp).Position + Vector3.new(0, 4, 0)
		CheerEffect.playParticle(pos)
	end

	hideAll()
	disconnectUpdate()
	currentStepIndex = 1 -- start at first step (no initial gap)
	_isAdvancing = false
	showCurrentStepAndBind()
end

function ClientTutorial.setSteps(stepList: { TutorialStep })
	steps = {}
	for i, s in stepList do
		assert(s.guiElement and s.guiElement:IsA("GuiObject"), "Each step must include a GuiObject")
		s.step = s.step or i
		s.guiElement.Visible = false
		s.delayBeforeNext = s.delayBeforeNext or 0
		if not s.guiElement.Parent then
			s.guiElement.Parent = Screens.general
		end
		steps[i] = s
	end
	personaliseWelcome()
end

function ClientTutorial.setOnNewStep(fn: (stepNumber: number) -> ())
	onNewStep = fn or function() end
end

function ClientTutorial.setOnComplete(fn: () -> ())
	onComplete = fn or function() end
end

function ClientTutorial.setStepCallbacks(stepNumber: number, onUpdate: ((dt: number) -> ())?, onEnd: (() -> ())?)
	for _, s in steps do
		if s.step == stepNumber then
			s.onUpdate = onUpdate
			s.onEnd = onEnd
			if currentStepIndex == stepNumber and _enabled then
				bindUpdateForCurrentStep()
			end
			break
		end
	end
end

function ClientTutorial.clearCallbacksForStep(stepNumber: number)
	for _, s in steps do
		if s.step == stepNumber then
			s.onUpdate = nil
			s.onEnd = nil
			if currentStepIndex == stepNumber then
				disconnectUpdate()
			end
			break
		end
	end
end

-- Enable/Disable controls
function ClientTutorial.enable()
	if _enabled then
		return
	end
	_enabled = true
	-- If tutorial is resumed mid-step, show and rebind
	if currentStepIndex == 0 and steps[1] then
		currentStepIndex = 1
	end
	local step = steps[currentStepIndex]
	if step then
		showStep(step)
	end
	bindUpdateForCurrentStep()
end

function ClientTutorial.disable()
	if not _enabled then
		return
	end
	_enabled = false
	_token += 1 -- cancel pending timers
	hideAll()
	disconnectUpdate()
	-- do not reset currentStepIndex; re-enable will resume
end

function ClientTutorial.isEnabled(): boolean
	return _enabled
end

return ClientTutorial
