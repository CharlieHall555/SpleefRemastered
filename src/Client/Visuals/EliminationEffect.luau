local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ParticleText = require(ClientModuleDirectory.Gui.ParticleText)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local EliminationEffect = {}

local function calcMidScreen(): Vector2
	local container = Screens.general
	if container and container.AbsoluteSize then
		local s = container.AbsoluteSize
		return Vector2.new(s.X * 0.5, s.Y * 0.5)
	end

	local cam = workspace.CurrentCamera
	if cam then
		local v = cam.ViewportSize
		return Vector2.new(v.X * 0.5, v.Y * 0.5)
	end

	-- Last-resort fallback
	return Vector2.new(0, 0)
end

local function fireEffect()
	local randomX = (math.random() - 0.5) / 5
	local randomY = 1

	local opts: ParticleText.ParticleTextOptions = {
		image = "rbxassetid://111822138056370",
		speed = Vector2.new(randomX, randomY),
		color = Color3.fromRGB(255, 255, 255), -- optional highlight color
		size = UDim2.fromScale(0.15, 0.15),
	}

    SoundPlayer.playSound("rbxassetid://8595984380" , {volume = 0.35 , playbackSpeed = 1.1})
	ParticleText.new(Screens.general, "Elimination", calcMidScreen(), opts)
end

function EliminationEffect.init()
	RemoteEventHandler.newEventConnection("ELIMINATION", function(playerKilled: Player)
		fireEffect()
	end)

	task.spawn(function()
		while true do
			wait(1)
			fireEffect()
		end
	end)
end

return EliminationEffect
