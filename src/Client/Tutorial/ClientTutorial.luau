local ContentProvider = game:GetService("ContentProvider")
local LocalPlayer = game.Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local TutorialTip = require(ClientModuleDirectory.Gui.TutorialTip)
local ConfirmLeave = require(ClientModuleDirectory.Gui.ConfirmLeave)
local TutorialData = require(ClientModuleDirectory.TutorialData)
local TutorialFunctions = require(ClientModuleDirectory.TutorialFunctions)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local currentStep = nil
local currentStepData : TutorialData.TutorialStage = {}
local currentStepChange = 0

local FALLBACK_IMAGE = "rbxassetid://117860991780103"
local ACTION_THRESHOLD = 1.5

local ClientTutorial = {}

local function timeSinceLastStep()
	return tick() - currentStepChange
end

function ClientTutorial.init()

	local toPreload = {}

	task.spawn(function()
		for _, stageData in pairs(TutorialData) do
			if table.find(toPreload, stageData.image) == nil then
				table.insert(toPreload, stageData.image)
			end
		end

		ContentProvider:PreloadAsync(toPreload)

	end)

	RemoteEventHandler.newEventConnection("START_TUTORIAL" , function(player)
		ClientTutorial.start()
	end)

	ConfirmLeave.onLeave(function()
		ClientTutorial.complete(true)
	end)

end

function ClientTutorial.nextStep()
	local end_func = TutorialFunctions["END" .. currentStep]
	if end_func then
		end_func()
	end

	currentStep += 1
	currentStepData = TutorialData[currentStep]
	currentStepChange = tick()

	if not currentStepData then
		ClientTutorial.complete(false)
	end

	ClientTutorial.showCurrent()

	local start_func = TutorialFunctions["START" .. currentStep]
	if start_func then
		start_func()
	end


	local actionRequired = currentStepData.actionToComplete
	if actionRequired == "AUTO_COMPLETE" then
		local autocompleteStep = currentStepData
		task.delay(currentStepData.autoCompleteTime or 5, function()
			ClientTutorial.onAction("AUTO_COMPLETE")
		end)
	end
end

function ClientTutorial.showCurrent()
	local stepMessage = ("(%d/%d)"):format(currentStep or 0, #TutorialData or 1) or ""

	if PlatformDetector.getPlatform() == "MOBILE" then
		TutorialTip.setText(stepMessage .. " " .. (currentStepData.messageMobile or ""))
	else
		TutorialTip.setText(stepMessage .. " " .. (currentStepData.messagePC or ""))
	end
	TutorialTip.setImage(currentStepData.image or FALLBACK_IMAGE)
end

function ClientTutorial.start()
	local SuccessSound = "rbxassetid://86832085549408"
	 --SoundPlayer.playSound(SuccessSound, { volume = 0.5 })
	currentStep = 0
	currentStepData = {}
	ClientTutorial.nextStep()
	currentStepChange = 0
	
end

function ClientTutorial.complete(skipped : boolean)
	currentStep = 0
	currentStepChange = 0
	currentStepData = {}
	if skipped == true then
		RemoteEventHandler.FireOnServer("TUTORIAL_COMPLETE" , false)
	else
		RemoteEventHandler.FireOnServer("TUTORIAL_COMPLETE" , true)
	end
	
end

function ClientTutorial.onAction(actionName : string)
	if currentStepData and actionName == currentStepData.actionToComplete then
		if actionName ~= "AUTO_COMPLETE" and timeSinceLastStep() < ACTION_THRESHOLD then
			return
		end
		if actionName ~= "AUTO_COMPLETE" then
			 --SoundPlayer.playSound("rbxassetid://1788243907", { volume = 0.5 })	
		end
		ClientTutorial.nextStep()
	end
end

return ClientTutorial