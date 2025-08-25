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

local MobileCamera = require(ClientModuleDirectory.Input.MobileCamera)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local lastMousePos

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		lastMousePos = input.Position
	end
end)

local MiscBindings = {}

local lightning = "rbxassetid://6994934244"

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

	ClientStateTracker.connectActive(function()
		
		if PlatformDetector.getPlatform() == "MOBILE" then
			
			MobileCamera.enable()
			TouchButtons.setVisibleActionButton(true)

		end

	end)

	ClientStateTracker.connectIntermission(function()
		
		if PlatformDetector.getPlatform() == "MOBILE" then
			
			MobileCamera.disable()
			TouchButtons.setVisibleActionButton(false)
			

		end

	end)
end

return MiscBindings
