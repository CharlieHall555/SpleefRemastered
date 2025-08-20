local Controls = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local SpectateGui

function Controls.onProfileLoaded()
	SpectateGui = GuiAssets:WaitForChild("Spectate"):WaitForChild("SpectateControls")
    SpectateGui.Visible = false
	SpectateGui.Parent = Screens.intermissionHUD

end



return Controls
