local localPlayer = game.Players.LocalPlayer
local Root = localPlayer.PlayerScripts
local playerGui = localPlayer.PlayerGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local Screens = {}

Screens.general = nil
Screens.gameHUD = nil
Screens.intermissionHUD = nil

function Screens.init()

    ReplicatedStorage:WaitForChild("GuiAssets")

    Screens.general = playerGui:WaitForChild("General")
    Screens.gameHUD = playerGui:WaitForChild("InGameHud")
    Screens.intermissionHUD = playerGui:WaitForChild("IntermissionHud")

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

return Screens