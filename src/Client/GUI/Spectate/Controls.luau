local Controls = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local StarterGui = game:GetService("StarterGui")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local CelebrationTracker = require(ClientModuleDirectory.Spectate.CelebrationTracker)
local ButtonUtilities = require(ClientModuleDirectory.Gui.ButtonUtilities)

local SpectateGui: Frame

local BUTTON_COOLDOWN = 0.1
local lastClicked = 0

local onExit: (() -> ())?
local onCelebrate: (() -> ())?
local onBack: (() -> ())?
local onNext: (() -> ())?

local nextButton: TextButton?
local backButton: TextButton?
local exitButton: TextButton?
local celebrateButton: TextButton?

local playerName: TextLabel?

local function canClick()
	if time() - lastClicked > BUTTON_COOLDOWN then
		return true
	else
		return false
	end
end

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
		if onCelebrate and canClick() and CelebrationTracker.hasCelebrated() == false then
			lastClicked = time()
			onCelebrate()
		end
	end)

	nextButton.Activated:Connect(function(inputObject, clickCount)
		if onNext and canClick() then
			lastClicked = time()

			onNext()
		end
	end)

	backButton.Activated:Connect(function(inputObject, clickCount)
		if onBack and canClick() then
			lastClicked = time()

			onBack()
		end
	end)

	exitButton.Activated:Connect(function(inputObject, clickCount)
		if onExit and canClick() then
			lastClicked = time()

			onExit()
		end
	end)

	ClientStateTracker.connectServerStateChange(function(newState : string)
		
		if newState == "STARTING" then
			ButtonUtilities.setGreyed(celebrateButton.Parent , false)
		end

	end)

	CelebrationTracker.setOnCelebrate(function()
		ButtonUtilities.setGreyed(celebrateButton.Parent , true)
	end)
		

end

function Controls.setPlayerSpectating(name: string)
	name = name or "None"

	playerName.Text = name
end

function Controls.show()
	SpectateGui.Visible = true
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end

function Controls.hide()
	SpectateGui.Visible = false
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end

function Controls.connectOnExit(fn: () -> ())
	onExit = fn
end

function Controls.connectOnBack(fn: () -> ())
	onBack = fn
end

function Controls.connectOnCelebrate(fn: () -> ())
	onCelebrate = fn
end

function Controls.connectOnNext(fn: () -> ())
	onNext = fn
end

return Controls
