local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local localPlayer = game.Players.LocalPlayer
local ClientKnockback = {}
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local function getMass(char: Model)
	local o = 0
	for _, each in char:GetChildren() do
		if o:IsA("Part") or o:IsA("MeshPart") or o:isA("BasePart") then
			o += each:getMass()
		end
	end
	return
end

local function isAirborne(h: Humanoid): boolean
	-- FloorMaterial is the fast/typical check; state checks are a fallback
	if h.FloorMaterial == Enum.Material.Air then
		return true
	end
	local s = h:GetState()
	return s == Enum.HumanoidStateType.Freefall
		or s == Enum.HumanoidStateType.Jumping
		or s == Enum.HumanoidStateType.FallingDown
end

local AIR_MULTIPLIER = 0.14
local HIGHLIGHT_NAME = "HitFlash"
local FLASH_TIME = 0.25
local HOLD_TIME = 0.05

local function removeExisting(character: Model)
	local existing = character:FindFirstChild(HIGHLIGHT_NAME)
	if existing and existing:IsA("Highlight") then
		existing:Destroy()
	end
end

local function playHitFlashOn(playerTarget: Player)
	local character = playerTarget.Character
	if not character then
		return
	end

	removeExisting(character)

	local highlight = Instance.new("Highlight")
	highlight.Name = HIGHLIGHT_NAME
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.fromRGB(255, 70, 70)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.Parent = character

	local tweenIn = TweenService:Create(
		highlight,
		TweenInfo.new(FLASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FillTransparency = 0.35, OutlineTransparency = 0 }
	)

	local tweenOut = TweenService:Create(
		highlight,
		TweenInfo.new(FLASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ FillTransparency = 1, OutlineTransparency = 1 }
	)

	tweenIn:Play()
	tweenIn.Completed:Wait()

	task.wait(HOLD_TIME)

	tweenOut:Play()
	tweenOut.Completed:Wait()

	if highlight then
		highlight:Destroy()
	end
end

function ClientKnockback.knockback(dir: Vector3, power: number)
	local character = player.Character
	if not character then return end

	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end

	-- Safety: ignore zero/near-zero directions
	if dir.Magnitude < 1e-3 then return end

	local dirUnit = dir.Unit

	local finalDeltaV = power
	if isAirborne(humanoid) then
		finalDeltaV *= AIR_MULTIPLIER
	end

	local mass = rootPart.AssemblyMass
	local impulse = dirUnit * (finalDeltaV * mass)

	-- Optional micro-lift to reduce ground friction stickiness (tune or remove)
	impulse += Vector3.new(0, mass * 15, 0) -- ~4 studs/s upward Δv

	rootPart:ApplyImpulse(impulse)

end

function ClientKnockback.init()
	RemoteEventHandler.newEventConnection("KNOCKBACK", ClientKnockback.knockback)

	RemoteEventHandler.newEventConnection("KNOCKBACK_ANIMATION", function(playerTarget: Player) -- and sound
		if playerTarget and playerTarget.Character then
			SoundPlayer.queuePositionalSound("rbxassetid://146163534", playerTarget.Character.PrimaryPart.Position) -- knockback sound.
		end

		if not playerTarget or playerTarget == localPlayer then
			return
		end
		playHitFlashOn(playerTarget)
	end)
end

return ClientKnockback
