local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer

local CrossHairGui : ImageLabel

local CrossHair = {}

function CrossHair.onLoaded()
    CrossHairGui = GuiAssets:WaitForChild("Input"):WaitForChild("Crosshair")
    CrossHairGui.Parent = Screens.gameHUD
    CrossHairGui.Visible = false
end

function CrossHair.show()
    CrossHairGui.Visible = true
end

function CrossHair.getGui()
    return CrossHairGui
end


function CrossHair.hide()
    CrossHairGui.Visible = false
end

return CrossHair