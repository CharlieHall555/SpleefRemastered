local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer
local ToolBarUtilities = require(ClientModuleDirectory.Gui.ToolBarUtilities)
local ScaleUtilities = require(ClientModuleDirectory.Gui.ScaleUtilities)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local SpectateButtonGUI : Frame
local SpectateButtonClickable : TextButton
local UIScale : UIScale

local onClick : (() -> ())?= nil

local BUTTON_MIN = 50

local SpectateButton = {}

function SpectateButton.onProfileLoaded()
    SpectateButtonGUI = GuiAssets:WaitForChild("Spectate"):WaitForChild("SpectateButton")
    SpectateButtonGUI.Parent = Screens.intermissionHUD
    SpectateButtonClickable = SpectateButtonGUI:WaitForChild("Clickable")
    SpectateButtonGUI.Visible = ClientStateTracker.getServerState() == "ACTIVE"
    UIScale = SpectateButtonGUI:WaitForChild("UIScale")
    local AnchorPoint = ToolBarUtilities.hotBarAnchorPoint() or 0.7
    SpectateButtonGUI.Position = UDim2.new(
        UDim.new(SpectateButtonGUI.Position.X.Scale , 0), 
        UDim.new(AnchorPoint - 0.1 , 0) 
    )

    SpectateButton.onResize()

    ClientStateTracker.connectServerStateChange(function(newState : string)
            if newState == "ACTIVE" then
            SpectateButton.show()
        else
            SpectateButton.hide()
        end
    
    end)

    SpectateButtonClickable.Activated:Connect(function(inputObject, clickCount)
        if onClick then
            onClick()
        end
    end)
end

function SpectateButton.connectOnClick(fn : () -> ()?)
    onClick = fn
end

function SpectateButton.onResize()

    if SpectateButtonGUI.AbsoluteSize.Y <= BUTTON_MIN then
        
        local newScale = ScaleUtilities.scaleForTargetOffset(
            SpectateButtonGUI.AbsoluteSize.Y,
            50,
            UIScale.Scale
        )

    end
    
end

function SpectateButton.show()
    if ClientStateTracker.getServerState() == "ACTIVE" then
        SpectateButton.Visible = true
    else
        print("couldnt show")
    end
    
end

function SpectateButton.getGui()
    return SpectateButton
end


function SpectateButton.hide()
    print("hide spectate button")
    SpectateButton.Visible = false
end

return SpectateButton