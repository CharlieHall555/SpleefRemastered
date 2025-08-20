local Controls = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local SpectateGui : Frame

local onExit : (() -> ())?
local onCelebrate : (() -> ())?
local onBack : (() -> ())?
local onNext : (() -> ())?

local nextButton : TextButton?
local backButton : TextButton?
local exitButton : TextButton?
local celebrateButton : TextButton?

local playerName : TextLabel?

function Controls.onProfileLoaded()
	SpectateGui = GuiAssets:WaitForChild("Spectate"):WaitForChild("SpectateControls")
    SpectateGui.Visible = false
	SpectateGui.Parent = Screens.intermissionHUD

	celebrateButton = SpectateGui.Celebrate.Clickable
	backButton = SpectateGui.ButtonHolder["1.Right"].Clickable
	exitButton = SpectateGui.ButtonHolder["2.Spectate"].Clickable
	nextButton = SpectateGui.ButtonHolder["3.Left"].Clickable

	playerName = SpectateGui.SpectatingPlayer.Label

	celebrateButton.Activated:Connect(function(inputObject, clickCount)
		if onCelebrate then
			onCelebrate()
		end
	end)

	nextButton.Activated:Connect(function(inputObject, clickCount)
		if onNext then
			onNext()
		end
	end)

	backButton.Activated:Connect(function(inputObject, clickCount)
		if onBack then
			onBack()
		end
	end)

	exitButton.Activated:Connect(function(inputObject, clickCount)
		if onExit then
			onExit()
		end
	end)


end

function Controls.setPlayerSpectating(name : string)
	name = name or "None"
	
	playerName.Text = name

end

function Controls.show()

	SpectateGui.Visible = true

end

function Controls.hide()

	SpectateGui.Visible = false
	
end

function Controls.connectOnExit(fn : () -> ())
	onExit = fn
end

function Controls.connectOnBack(fn : () -> ())
	onBack = fn
end

function Controls.connectOnCelebrate(fn : () -> ())
	onCelebrate = fn
end

function Controls.connectOnNext(fn : () -> ())
	onNext = fn
end




return Controls
