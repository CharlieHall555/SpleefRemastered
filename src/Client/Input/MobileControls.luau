local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Players = game:GetService("Players")
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)
local LocalPlayer = Players.LocalPlayer
local ActionHandler = require(ClientModuleDirectory.Input.ActionHandler)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)

local JUMP_COOLDOWN = 0.2

local lastJumpTime = 0

local MobileControls = {}

local function canJump(): boolean -- on floor, within cooldown
	local character = LocalPlayer.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
	local now = os.clock()
	return onGround and (now - lastJumpTime) >= JUMP_COOLDOWN
end

local function onJumpPressed()
	local character = LocalPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and canJump() then
		lastJumpTime = os.clock()
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

function MobileControls.onProfileLoaded()
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
	end
end

return MobileControls
