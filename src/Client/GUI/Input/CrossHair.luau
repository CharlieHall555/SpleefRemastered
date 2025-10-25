local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local LocalizationService = game:GetService("LocalizationService")
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer

local CrossHairGui: ImageLabel

local SMALL_SHOVEL = "rbxassetid://112984427793297"
local SMALL_SNOWBALL = "rbxassetid://91214120728139"
local CROSS_HAIR_DEFAULT = "rbxassetid://81890874267120"

local CrossHair = {}

function CrossHair.onLoaded()
	CrossHairGui = GuiAssets:WaitForChild("Input"):WaitForChild("Crosshair")
	CrossHairGui.Parent = Screens.general
	CrossHairGui.Visible = PlatformDetector.getPlatform() == "MOBILE"
    CrossHairGui.Image = SMALL_SNOWBALL
end

function CrossHair.show()
	CrossHairGui.Visible = true
end

function CrossHair.getGui()
	return CrossHairGui
end

function CrossHair.reset()
	if CrossHairGui then
		CrossHairGui.Image = SMALL_SNOWBALL
	end
end

function CrossHair.snowball()
	if CrossHairGui then
		CrossHairGui.Image = SMALL_SNOWBALL
        CrossHairGui.Size = UDim2.fromScale(0.012, 0.031)
	end
end

function CrossHair.shovel()
	if CrossHairGui then
		CrossHairGui.Image = SMALL_SHOVEL
        CrossHairGui.Size = UDim2.fromScale(0.025, 0.039)
	end
end

function CrossHair.hide()
	CrossHairGui.Visible = false
end

return CrossHair
