local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Player = game.Players.LocalPlayer
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local InputHandler = require(ClientModuleDirectory.Input.InputHandler)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local player = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local mouse = player:GetMouse()
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserInputService

local camera : Camera? = nil

local ActionHandler = {}

function ActionHandler.init()
	local binding1 = InputHandler.bindActionStart(Enum.UserInputType.MouseButton1, ActionHandler.mainAttack)
end

local lastClickTime = 0
local HIT_COOLDOWN = 0.1
local RAY_MAX = 1000

local out_count = 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.CollisionGroup = "CG_GAMEPLAY"

local function ensureCamera(): Camera?
    if not camera or camera.Parent == nil then
        camera = workspace.CurrentCamera
    end
    return camera
end

function ActionHandler.canAttack()

	if time() - lastClickTime < HIT_COOLDOWN then
		return false
	end
	lastClickTime = time()

	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local headPart = character:FindFirstChild("Head")
	if (not rootPart) or not headPart then
		return false
	end
	if ClientStateTracker.getState() ~= "ACTIVE" then
		return false
	end

	if ClientStateTracker.getServerState() ~= "ACTIVE" then
		return false
	end

	if not character:FindFirstChild("Shovel") then
		return false
	end

	return true
end

function ActionHandler.getDirection(_action, spawnPart: BasePart, reticleGui: GuiObject?): Vector3
    local cam = ensureCamera()
    if not cam then
        return Vector3.new(0, 0, -1)
    end

    -- Make sure we don't hit our own character
    if spawnPart and spawnPart.Parent then
        rayParams.FilterDescendantsInstances = { spawnPart.Parent }
    else
        rayParams.FilterDescendantsInstances = {}
    end

    -- 1) Work out the SCREEN POINT to ray through
    local screenX: number, screenY: number

    if reticleGui then
        -- Use the actual reticle position (important for over-shoulder or offset reticles on MOBILE)
        local absPos = reticleGui.AbsolutePosition
        local absSize = reticleGui.AbsoluteSize
        screenX = absPos.X + absSize.X * 0.5
        screenY = absPos.Y + absSize.Y * 0.5
    elseif PlatformDetector.getPlatform() == "PC" and mouse then
        -- Mouse position on PC
        screenX = mouse.X
        screenY = mouse.Y
    else
        -- Fallback to center of the screen
        local center = cam.ViewportSize * 0.5
        screenX = center.X
        screenY = center.Y
    end

    -- 2) Build a world ray from CAMERA through the screen point (reticle)
    local unitRay = cam:ViewportPointToRay(screenX, screenY)

    -- 3) Find a target point along that ray (prioritize real hit, otherwise a far point)
    local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * RAY_MAX, rayParams)
    local target: Vector3 = hit and hit.Position or (unitRay.Origin + unitRay.Direction * RAY_MAX)

    -- 4) Turn that into a direction from the projectile spawn position
    --    This ensures the projectile’s path aims to the same point the reticle ray hits.
    local fromSpawn = target - spawnPart.Position
    if fromSpawn.Magnitude < 1e-6 then
        return cam.CFrame.LookVector.Unit
    end
    return fromSpawn.Unit
end

function ActionHandler.mainAttack(action)
	if ActionHandler.canAttack() then
		local character = player.Character
		local headPart = character:FindFirstChild("Head")

		print(ClientAmmoTracker.getIsInfinite())
		print(ClientAmmoTracker.getAmmo() <= 0 and ClientAmmoTracker.getIsInfinite() == false)

		local selectedBlock =ClientBlockSelector.getSelected()

		if selectedBlock then -- destroy with spade
			local id = selectedBlock:GetAttribute("Id")
			RemoteEventHandler.FireOnServer("REQUEST_DESTROY_BLOCK", id)
			ClientDestructionHandler.predictBlockDestroy(selectedBlock)
			return
		else -- shoot
			if ClientAmmoTracker.getAmmo() <= 0 and ClientAmmoTracker.getIsInfinite() == false then
				out_count += 1
				if out_count >= 7 then
					--InGameHUD.showHint()
				end
				
				SoundPlayer.playSound("rbxassetid://9125655693")
				return
			else
				out_count = 0
			end
		end

		local direction = ActionHandler.getDirection(action, headPart)
		local playerPosition = headPart.Position
		--ClientAmmoTracker.predictIncrement(-1)
		RemoteEventHandler.FireOnServer("CREATE_SNOWBALL", playerPosition, direction)
	end
end

return ActionHandler
