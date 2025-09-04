local Root = game.Players.LocalPlayer.PlayerScripts
local LocalPlayer = game.Players.LocalPlayer
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local ParticleText = require(ClientModuleDirectory.Gui.ParticleText)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserInputService = game:GetService("UserInputService")
local ClientLavaManager = require(ClientModuleDirectory.ClientLavaManager)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)
local SpectateButton = require(ClientModuleDirectory.Gui.SpectateButton)
local SystemMessage = require(ClientModuleDirectory.Chat.SystemMessage)
local Transition = require(ClientModuleDirectory.Gui.Transition)
local MobileCamera = require(ClientModuleDirectory.Input.MobileCamera)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local MovementDampener = require(ClientModuleDirectory.Input.MovementDampener)
local CLientSnowballVisuals = require(ClientModuleDirectory.ClientSnowballVisuals)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local lastMousePos

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		lastMousePos = input.Position
	end
end)

local MiscBindings = {}

local lightning = "rbxassetid://6994934244"

function MiscBindings.onProfileLoaded()
	if PlatformDetector.getPlatform() == "MOBILE" then
		MobileCamera.enable()
		TouchButtons.setVisibleActionButton(true)
	end
end

function MiscBindings.init()
	RemoteEventHandler.newEventConnection("PLAYER_DIED", function(playerWhoDied: Player)
		SoundPlayer.playSound(lightning, { volume = 0.3 })
	end)

	RemoteEventHandler.newEventConnection("AMMO_GAINED", function(amount: number)
		if PlatformDetector.getPlatform() == "PC" and lastMousePos then
			local randomX = (math.random() - 0.5) / 5
			local randomY = 1

			local opts = {
				image = "rbxassetid://91214120728139",
				speed = Vector2.new(randomX, randomY),
				color = Color3.fromRGB(255, 255, 255), -- optional highlight color
			}

			ParticleText.new(LocalPlayer.PlayerGui.General, "+" .. tostring(amount), lastMousePos, opts)
		end
	end)

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "ACTIVE" and ClientStateTracker.getState() == "INTERMISSION" then
			SpectateButton.show()
		elseif newState == "INTERMISSION" then
			SpectateButton.hide()
		end
	end)

	ClientStateTracker.connectIntermission(function()
		task.wait(0.5)
		if ClientStateTracker.getServerState() == "ACTIVE" then
			SpectateButton.show()
		end
	end)

	RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH", function()
		SoundPlayer.playSound("rbxassetid://88338250840662", { volume = 0.38 })
	end)

	RemoteEventHandler.newEventConnection("PLAYER_DIED", function(died: Player, killer: Player)
		if died and killer then
			SystemMessage.send(
				killer.DisplayName .. " ELIMINATED " .. died.DisplayName,
				Color3.new(0.937254, 0.019607, 0.019607),
				true
			)
		else
			SystemMessage.send(died.DisplayName .. " DIED", Color3.new(0.788235, 0.129411, 0.043137), true)
		end

		if died == LocalPlayer then
			Transition.show()
			task.wait(1)
			Transition.hide()
		end
	end)

	RemoteEventHandler.newEventConnection("PLAYER_WON", function(playerName: string, winner: Player)
		SystemMessage.send(winner.DisplayName .. " WON", Color3.new(0.862745, 0.890196, 0.352941), true)
	end)

	ClientStateTracker.connectActive(function()
		MovementDampener.enable()
	end)

	ClientStateTracker.connectTutorial(function()
		MovementDampener.enable()
	end)

	ClientStateTracker.connectIntermission(function()
		MovementDampener.disable()
	end)

	CLientSnowballVisuals.registerTag("Target", function(hitObject)
		local parentGui = Screens.gameHUD
		local absSize = parentGui.AbsoluteSize
		local screenCenter = Vector2.new(absSize.X / 2, absSize.Y / 2)
		print("hit target")
		SoundPlayer.playSound("rbxassetid://79138466370636") -- ding sound
		local opts = {
			image = "rbxassetid://113489472341219",
			speed = Vector2.new(math.random(-50, 50) / 100, math.random(20, 50) / 100),
			color = Color3.fromRGB(
				math.random(50, 255), -- avoid too-dark colors
				math.random(50, 255),
				math.random(50, 255)
			),
			lifetime = 5,
			size = UDim2.fromScale(0.144, 0.12),
		}

		ParticleText.new(
			parentGui,
			"HIT",
			screenCenter + Vector2.new(math.random(-100, 100), math.random(-100, 100)),
			opts
		)
	end)
end

return MiscBindings
