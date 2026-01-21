local Root = game.Players.LocalPlayer.PlayerScripts
local LocalPlayer = game.Players.LocalPlayer
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local ParticleText = require(ClientModuleDirectory.Gui.ParticleText)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Debris = game:GetService("Debris")
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
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local ModeDetector = require(ClientModuleDirectory.Input.ModeDetector)
local VibrationService = require(ClientModuleDirectory.VibrationService)
local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)
local MouseIcon = require(ClientModuleDirectory.Gui.MouseIcon)
local MobileCamera = require(ClientModuleDirectory.Input.MobileCamera)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)
local Camera = workspace.CurrentCamera
local WeatherManager = require(ClientModuleDirectory.Weather.WeatherManager)


local MiscBindings = {}

local lightning = "rbxassetid://6994934244"

function MiscBindings.onProfileLoaded()

	if PlatformDetector.getPlatform() == "PC" then
		LocalPlayer.CameraMinZoomDistance = 0
	end

	if PlatformDetector.getPlatform() == "MOBILE" then
		MobileCamera.enable()
		TouchButtons.setVisibleActionButton(true)
	end
end

local GuiService = game:GetService("GuiService")



function MiscBindings.onSnowballGained(amount)
	local platform = PlatformDetector.getPlatform()
	local randomX = (math.random() - 0.5) / 5
	local randomY = 1
	local opts = {
		image = "rbxassetid://91214120728139", --snowball image.
		speed = Vector2.new(randomX, randomY),
		color = Color3.fromRGB(255, 255, 255),
	}
	local lastMousePos = InputHandler.getLastMousePos()
	if platform == "PC" and lastMousePos then
		ParticleText.new(LocalPlayer.PlayerGui.General, "+" .. tostring(amount), lastMousePos, opts)
	elseif platform == "MOBILE" then
		local screenPos = MobileCamera.getMobileCenterOffsetPos()
		ParticleText.new(LocalPlayer.PlayerGui.General, "+" .. tostring(amount), screenPos, opts)
	end
end



function MiscBindings.init()

	ClientBlockSelector.newBlockSelected = function(newBlock)
		ModeDetector.newBlock(newBlock)
	end
	
	RemoteEventHandler.newEventConnection("PLAYER_DIED", function(playerWhoDied: Player)
		SoundPlayer.playSound(lightning, { volume = 0.3 })
		if playerWhoDied == LocalPlayer then
			VibrationService.medium()
		end
	end)

	RemoteEventHandler.newEventConnection("AGENT_DIED", function()
		SoundPlayer.playSound(lightning, { volume = 0.3 })
	end)

	RemoteEventHandler.newEventConnection("AMMO_GAINED", MiscBindings.onSnowballGained)

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "ACTIVE" and ClientStateTracker.getState() == "INTERMISSION" then
			SpectateButton.show()
		elseif newState == "INTERMISSION" then
			SpectateButton.hide()
		end
	end)

	ClientStateTracker.connectIntermission(function()
		
	
		WeatherManager.setWeather("lobbyWeather")
		MouseIcon.reset()
	end)

	ClientStateTracker.connectIntermission(function()
		task.wait(0.25)
		if ClientStateTracker.getServerState() == "ACTIVE" and  ClientStateTracker.getState() == "INTERMISSION" then
			SpectateButton.show()
		end
	end)
	
	RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH", function()
		SoundPlayer.playSound("rbxassetid://88338250840662", { volume = 0.38 })
	end)

	RemoteEventHandler.newEventConnection("PLAYER_DIED", function(died: Player, killer: Player)

	end)

	RemoteEventHandler.newEventConnection("PLAYER_WON", function(playerName: string, winner: Player)

	

	end)

	ClientStateTracker.connectActive(function()

		if LocalPlayer.Character then
			Camera.CameraSubject = LocalPlayer.Character
			if PlatformDetector:getPlatform() == "MOBILE" then
				MobileCamera.enable()
			end
		end
		MovementDampener.enable()
	end)

	ClientStateTracker.connectTutorial(function()
		MovementDampener.enable()
	end)

	ClientStateTracker.connectIntermission(function()
		MovementDampener.disable()
	end)

	local DING = "rbxassetid://79138466370636"

	CLientSnowballVisuals.registerTag("Target", function(hitObject, snowballOwner: Player?)
		if snowballOwner and snowballOwner == LocalPlayer then
			SoundPlayer.playSound(DING) -- ding sound
		end
	end)

	local CoinSound = "rbxassetid://607665037"
	HitBoxManager.setUpCallback("COIN_PICKUP", function(part: BasePart)
		ParticlePlayer.queueEmission("coin", part.Position, 12)
		SoundPlayer.playSound(CoinSound)
	 end)

	ClientStateTracker.connectActive(function()
		TouchButtons.setVisiblePowerUpButton(true)
	end)

	ClientStateTracker.connectIntermission(function()
		TouchButtons.setVisiblePowerUpButton(false)
	end)

	RemoteEventHandler.newEventConnection("EXPLOSION", function(pos : Vector3, radius : number)
		if pos and radius then
			local explosionSound = "rbxassetid://5801257793" -- explosion sound
			SoundPlayer.queuePositionalSound(explosionSound, pos, { volume = 0.5 })
			if ParticlePlayer.getVisible() then
				local explosionEffect = Instance.new("Explosion")
				explosionEffect.Position = pos
				explosionEffect.BlastRadius = math.max(1 , radius)
				explosionEffect.BlastPressure = 0
				explosionEffect.Parent = workspace
				Debris:AddItem(explosionEffect, 5)
			end
		end
		
		

	end)

end



return MiscBindings
