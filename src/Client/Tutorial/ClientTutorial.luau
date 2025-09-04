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

local GuiAssets = ReplicatedStorage:WaitForChild("GuiAssets")
local TutorialFolder = GuiAssets:WaitForChild("Tutorial")

local cheerSound = "rbxassetid://97118547861968"

export type TutorialStep = {
	step: number,
	name: string,
	actionToComplete: string,
	guiElement: GuiObject,
	displayTime: number?, -- auto-complete after N seconds (optional)
	delayBeforeNext: number?, -- NEW: wait this long before moving to next step after completion
	onUpdate: ((dt: number) -> ())?,
	onEnd: (() -> ())?,
}

local ClientTutorial = {} :: any

-- State
local steps: { TutorialStep } = {}
local currentStepIndex = 0
local onNewStep: (stepNumber: number) -> () = function() end
local onComplete: () -> () = function() end
local updateConn: RBXScriptConnection? = nil
local _isAdvancing = false -- guard against double-advance

-- Helpers
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
	if step.guiElement then
		step.guiElement.Visible = true
	end
end

local function hideStep(step: TutorialStep)
	if step.guiElement then
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
		local cur = steps[currentStepIndex]
		if cur and cur.onUpdate then
			cur.onUpdate(dt)
		end
	end)
end

local function endCurrentStep()
	local step = steps[currentStepIndex]
	if step and step.onEnd then
		step.onEnd()
	end
	disconnectUpdate()
end

-- NEW: advance that respects the previous step's delayBeforeNext
local function advanceFromCurrent()
	if _isAdvancing then
		return
	end
	_isAdvancing = true

	local previousStep = steps[currentStepIndex]

	if currentStepIndex > 0 and previousStep then
		hideStep(previousStep)
		endCurrentStep()
	end

	local delay = (previousStep and previousStep.delayBeforeNext) or 0

	task.delay(delay, function()
		currentStepIndex += 1
		local step = steps[currentStepIndex]

		if step then
			showStep(step)

			if step.displayTime and step.displayTime > 0 then
				task.spawn(function()
					task.wait(step.displayTime)
					ClientTutorial.onAction(step.actionToComplete)
				end)
			end

			bindUpdateForCurrentStep()
			onNewStep(currentStepIndex)
		else
			hideAll()
			onComplete()
		end

		_isAdvancing = false
	end)
end

-- Public API
function ClientTutorial.onLoaded()
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
				name = "Shoot",
				actionToComplete = "SHOOT",
				guiElement = createGuiFromTemplate("Shoot_MOBILE"),
                delayBeforeNext = 1,
			},
			{
				step = 6,
				name = "Win",
				actionToComplete = "WIN_END",
				guiElement = createGuiFromTemplate("Win"),
				displayTime = 5,
			},
			{
				step = 7,
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
				guiElement = createGuiFromTemplate("Break_PC"),
                delayBeforeNext = 1,
			},
			{
				step = 5,
				name = "Shoot",
				actionToComplete = "SHOOT",
				guiElement = createGuiFromTemplate("Break_PC"),
                delayBeforeNext = 1,

			},
			{
				step = 6,
				name = "Win",
				actionToComplete = "WIN_END",
				guiElement = createGuiFromTemplate("Win"),
				displayTime = 5,
			},
			{
				step = 7,
				name = "Complete",
				actionToComplete = "COMPLETE_END",
				guiElement = createGuiFromTemplate("Complete"),
				displayTime = 5,
			},
		}
	end
	-- Example per-frame highlights using the new callbacks
	ClientTutorial.setStepCallbacks(4, function()
		HighlightBlocks.within(30)
	end, nil)

	ClientTutorial.setOnNewStep(function(stepNumber)
		print(stepNumber)
		if stepNumber == 5 or stepNumber == 6 then
			HighlightBlocks.reset()
		end
	end)

	ClientTutorial.setStepCallbacks(5, function()
		HighlightBlocks.outside(19)
	end, nil)

	personaliseWelcome()
end

function ClientTutorial.getStep(): number
	return currentStepIndex
end

function ClientTutorial.onAction(actionName: string)
	local step = steps[currentStepIndex]
	if step and actionName == step.actionToComplete then
		advanceFromCurrent()
	end
end

function ClientTutorial.onProfileLoaded()
	ClientStateTracker.connectTutorial(function()
		if UserProfile.getValue("hasJoinedBefore") then
			return
		end
		task.spawn(function()
			task.wait(3)
			if ClientStateTracker.getState() == "TUTORIAL" then
				ClientTutorial.startTutorial()
			end
		end)
	end)

	ClientTutorial.setOnComplete(function()
		RemoteEventHandler.FireOnServer("TUTORIAL_COMPLETED")
        SoundPlayer.playSound(cheerSound) -- cheer sound
	end)
end

function ClientTutorial.startTutorial()
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
	currentStepIndex = 0
	_isAdvancing = false
	advanceFromCurrent() -- start first step (no previous step delay)
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
			if currentStepIndex == stepNumber then
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

return ClientTutorial
