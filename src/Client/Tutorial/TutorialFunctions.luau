local LocalPlayer = game.Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Ammo = require(ClientModuleDirectory.Gui.Ammo)
local HighlightBlocks = require(ClientModuleDirectory.HighlightBlocks)
local AbilityBar = require(ClientModuleDirectory.Gui.AbilityBar)


local TutorialFunctions = {}

local onStep3 = false
local onStep5 = false
local MAX_STEPS = 100000
local SELECTION_DISTANCE : number = 25

TutorialFunctions.START4 = function()
    Ammo.setArrowVisible(true)
end

TutorialFunctions.END4 = function()
    Ammo.setArrowVisible(false)
end

TutorialFunctions.START3 = function()
    onStep3 = true
    local counter = 0
    while onStep3 and counter <= MAX_STEPS do
        HighlightBlocks.within(SELECTION_DISTANCE)
        counter += 1
        task.wait()
    end
end

TutorialFunctions.END3 = function()
    HighlightBlocks.reset()
    onStep3 = false
end

TutorialFunctions.START5 = function()
    onStep5 = true
    local counter = 0
    while onStep5 and counter <= MAX_STEPS do
        HighlightBlocks.outside(SELECTION_DISTANCE)
        counter += 1
        task.wait()
    end
end

TutorialFunctions.END5 = function()
    HighlightBlocks.reset()
    onStep5 = false
end

TutorialFunctions.START6 = function()
    AbilityBar.setArrowVisible(true)
end

TutorialFunctions.END6 = function()
    AbilityBar.setArrowVisible(false)
end

return TutorialFunctions