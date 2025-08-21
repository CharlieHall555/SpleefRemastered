local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer
local ToolBarUtilities = require(ClientModuleDirectory.Gui.ToolBarUtilities)

local SpectateButton : Frame

local SpectateButton = {}

function SpectateButton.onLoaded()
    SpectateButton = GuiAssets:WaitForChild("Spectate"):WaitForChild("SpectateButton")
    SpectateButton.Parent = Screens.intermissionHUD
    SpectateButton.Visible = true
    local AnchorPoint = ToolBarUtilities.hotBarAnchorPoint(true)
    if AnchorPoint == nil then
        print("NOOO")
        AnchorPoint = 0.7
    end
    SpectateButton.Size = UDim2.fromScale(SpectateButton.Size.X.Scale , AnchorPoint)
end

function SpectateButton.show()
    SpectateButton.Visible = true
end

function SpectateButton.getGui()
    return SpectateButton
end


function SpectateButton.hide()
    SpectateButton.Visible = false
end

return SpectateButton