local Root = game.Players.LocalPlayer.PlayerScripts
local LocalPlayer = game.Players.LocalPlayer
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local ParticleText = require(ClientModuleDirectory.Gui.ParticleText)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserInputService = game:GetService("UserInputService")

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

	RemoteEventHandler.newEventConnection("AMMO_GAINED", function(Amount)
		if PlatformDetector.getPlatform() == "PC" and lastMousePos then
			local RandomXSpeed = ((math.random() - 0.5) / 5)
			local RandomYSpeed = 1

			Amount = "+" .. tostring(Amount)

			local newText = ParticleText.new(
				LocalPlayer.PlayerGui.General,
				Amount,
				"rbxassetid://91214120728139",
				lastMousePos,
				Vector2.new(RandomXSpeed, RandomYSpeed)
			)
		end
	end)
end

return MiscBindings
