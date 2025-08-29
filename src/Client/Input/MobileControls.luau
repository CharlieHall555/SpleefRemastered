local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)
local LocalPlayer = Players.LocalPlayer
local ActionHandler = require(ClientModuleDirectory.Input.ActionHandler)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)

local Controls

local JUMP_COOLDOWN = 0.05 -- Reduced from 0.2 for better responsiveness
local GROUND_CHECK_DISTANCE = 4 -- Raycast distance for ground detection

local TAP_LENGTH = 0.15 -- 150ms

local lastJumpTime = 0
local jumpBufferTime = 0

local MobileControls = {}

-- More reliable ground detection using raycast
local function isOnGround(): boolean
	local character = LocalPlayer.Character
	if not character then
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return false
	end

	-- Raycast downward to check for ground
	--[[local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {character}

	local raycastResult = workspace:Raycast(
		humanoidRootPart.Position,
		Vector3.new(0, -GROUND_CHECK_DISTANCE, 0),
		raycastParams
	)]]
	--

	return true
end

local function canJump(): boolean
	local character = LocalPlayer.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- Check if humanoid is in a jumpable state
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		return false
	end

	local now = time()
	local cooldownPassed = (now - lastJumpTime) >= JUMP_COOLDOWN
	local onGround = isOnGround()

	return onGround and cooldownPassed
end

local function attemptJump()
	local character = LocalPlayer.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and canJump() then
		lastJumpTime = time()
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		return true
	end
	return false
end

local function onJumpPressed()
	local now = time()

	if attemptJump() then
		return
	end
end


function MobileControls.onProfileLoaded()
	print("MobileControls Loaded")
	Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
	print(Controls)
	if PlatformDetector.getPlatform() == "MOBILE" then
		TouchButtons.setJumpCallback(onJumpPressed)
		TouchButtons.setActionCallback(ActionHandler.mainAttack)

		ClientBlockSelector.newBlockSelected = function(newBlock)
			if newBlock then
				TouchButtons.setActionToShovelIcon()
			else
				TouchButtons.setActionToSnowballIcon()
			end
		end

		local binding2 = InputHandler.bindActionEnd(Enum.UserInputType.Touch, function(action: InputHandler.InputAction)
			if action.length < TAP_LENGTH then
				ActionHandler.mainAttack()
			end
		end)
	end
end

return MobileControls
