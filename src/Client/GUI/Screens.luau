local localPlayer = game.Players.LocalPlayer
local Root = localPlayer.PlayerScripts
local playerGui = localPlayer.PlayerGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Camera = game.Workspace.CurrentCamera

local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local Screens = {}

Screens.general = nil
Screens.gameHUD = nil
Screens.intermissionHUD = nil
Screens.touchControls = nil

function Screens.init()

    ReplicatedStorage:WaitForChild("GuiAssets")

    Screens.general = playerGui:WaitForChild("General")
    Screens.gameHUD = playerGui:WaitForChild("InGameHud")
    Screens.intermissionHUD = playerGui:WaitForChild("IntermissionHud")
    Screens.touchControls = playerGui:WaitForChild("CustomTouchControls")

    Screens.gameHUD.Enabled = (ClientStateTracker.getState() == "ACTIVE")
    Screens.intermissionHUD.Enabled = not Screens.gameHUD.Enabled

    ClientStateTracker.connectIntermission(function()
        Screens.intermissionHUD.Enabled = true
        Screens.gameHUD.Enabled = false
    end)

    ClientStateTracker.connectActive(function()
        Screens.intermissionHUD.Enabled = false
        Screens.gameHUD.Enabled = true
    end)

end

function Screens:getGeneralSize()

    if Screens.general then
        return Screens.general.AbsoluteSize
    else
        return Camera.ViewportSize
    end
    
    
end

return Screens