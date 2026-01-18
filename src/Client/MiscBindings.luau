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


local lastMousePos

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		lastMousePos = input.Position
	end
end)

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

local function getMobileCenterOffsetPos(): Vector2
	local cam = workspace.CurrentCamera
	local viewport: Vector2 = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local inset: Vector2 = GuiService:GetGuiInset()

	local center = viewport * 0.5
	-- Offset radius (~8% width, ~6% height); tweak to taste
	local rX = viewport.X * 0.08
	local rY = viewport.Y * 0.06

	local offset = Vector2.new((math.random() * 2 - 1) * rX, (math.random() * 2 - 1) * rY)
	local pos = center + offset

	-- Clamp inside screen, respecting top inset
	local pad = 12
	local minX = math.max(pad, inset.X + pad)
	local minY = math.max(pad, inset.Y + pad)
	local maxX = viewport.X - pad
	local maxY = viewport.Y - pad

	return Vector2.new(math.clamp(pos.X, minX, maxX), math.clamp(pos.Y, minY, maxY))
end

function MiscBindings.onSnowballGained(amount)
	local platform = PlatformDetector.getPlatform()
	local randomX = (math.random() - 0.5) / 5
	local randomY = 1
	local opts = {
		image = "rbxassetid://91214120728139", --snowball image.
		speed = Vector2.new(randomX, randomY),
		color = Color3.fromRGB(255, 255, 255),
	}

	if platform == "PC" and lastMousePos then
		ParticleText.new(LocalPlayer.PlayerGui.General, "+" .. tostring(amount), lastMousePos, opts)
	elseif platform == "MOBILE" then
		local screenPos = getMobileCenterOffsetPos()
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

	RemoteEventHandler.newEventConnection("AGENT_DIED", function(playerWhoDied: Player)
		SoundPlayer.playSound(lightning, { volume = 0.3 })
		if playerWhoDied == LocalPlayer then
			VibrationService.medium()
		end
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
		if died and killer then
			SystemMessage.send(
				killer.DisplayName .. " ELIMINATED " .. died.DisplayName,
				Color3.new(0.937254, 0.019607, 0.019607),
				true
			)
		else
			SystemMessage.send(died.DisplayName .. " DIED", Color3.new(0.788235, 0.129411, 0.043137), true)
		end
	end)

	RemoteEventHandler.newEventConnection("PLAYER_WON", function(playerName: string, winner: Player)

		if playerName and winner then
			SystemMessage.send(winner.DisplayName .. " WON", Color3.new(0.862745, 0.890196, 0.352941), true)
		else
			SystemMessage.send("NOBODY " .. " WON", Color3.new(0.862745, 0.890196, 0.352941), true)
		end

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

	local DING = "rbxassetid://79138466370636"

	CLientSnowballVisuals.registerTag("Target", function(hitObject, snowballOwner: Player?)
		if snowballOwner and snowballOwner == LocalPlayer then
			SoundPlayer.playSound(DING) -- ding sound
		end
	end)

	local CoinSound = "rbxassetid://607665037"
	HitBoxManager.setUpCallback("COIN_PICKUP", function(part: BasePart)
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
