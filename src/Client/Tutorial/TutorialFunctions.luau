local LocalPlayer = game.Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Ammo = require(ClientModuleDirectory.Gui.Ammo)
local HighlightBlocks = require(ClientModuleDirectory.HighlightBlocks)
local AbilityBar = require(ClientModuleDirectory.Gui.AbilityBar)

local TutorialFunctions = {}

local onStep4 = false
local onStep6 = false
local MAX_STEPS = 100000
local SELECTION_DISTANCE: number = 25

TutorialFunctions.START5 = function()
	Ammo.setArrowVisible(true)
end

TutorialFunctions.END5 = function()
	Ammo.setArrowVisible(false)
end

TutorialFunctions.START4 = function()
	onStep4 = true
	local counter = 0
	while onStep4 and counter <= MAX_STEPS do
		HighlightBlocks.within(SELECTION_DISTANCE)
		counter += 1
		task.wait()
	end
end

TutorialFunctions.END4 = function()
	HighlightBlocks.reset()
	onStep4 = false
end

TutorialFunctions.START6 = function()
	onStep6 = true
	local counter = 0
	while onStep6 and counter <= MAX_STEPS do
		HighlightBlocks.outside(SELECTION_DISTANCE)
		counter += 1
		task.wait()
	end
end

TutorialFunctions.END6 = function()
	HighlightBlocks.reset()
	onStep6 = false
end

TutorialFunctions.START7 = function()
	AbilityBar.setArrowVisible(true)
end

TutorialFunctions.END7 = function()
	AbilityBar.setArrowVisible(false)
end

return TutorialFunctions
