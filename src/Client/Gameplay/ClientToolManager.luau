local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local localPlayer = game.Players.LocalPlayer
local backpack = localPlayer.Backpack
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local ModeDetector = require(ClientModuleDirectory.Input.ModeDetector)
local AnimationManager = require(ClientModuleDirectory.AnimationManager)

local snowballIdleAnim = "rbxassetid://70913102895728"

local ClientToolManager = {}

local MAX_EQUIP_ATTEMPTS = 10
local ATTEMPT_DELAY = 0.1

local activeIdleTrack: AnimationTrack? = nil

local function makeModelVisible(model : Model , value : boolean)
	
	local parts = model:GetDescendants()
	for _ , each in parts do
		if each:IsA("BasePart") and each.Name ~= "Handle" then
			if value then
				each.Transparency = 0
			else
				each.Transparency = 1
			end
		end

	end
	
end

local function applyIdleForTool(toolName: string)
	if toolName == "Snowball" then
		if activeIdleTrack then
			activeIdleTrack:Stop()
			activeIdleTrack:Destroy()
			activeIdleTrack = nil
		end
		activeIdleTrack = AnimationManager.playAnimation(snowballIdleAnim, true)
	else
		if activeIdleTrack then
			activeIdleTrack:Stop()
			activeIdleTrack:Destroy()
			activeIdleTrack = nil
		end
	end
end

function ClientToolManager.setSnowballVisible(value: boolean)
	if localPlayer.Character then
		local snowballTool = localPlayer.Backpack:FindFirstChild("Snowball")
			or localPlayer.Character:FindFirstChild("Snowball")

		if snowballTool then
			if value then
				snowballTool.Handle.Transparency = 0
			else
				snowballTool.Handle.Transparency = 1
			end
		end
	end
end

function ClientToolManager.init()
	ModeDetector.connectModeChange(function()
		ClientToolManager.equipTool()
	end)

	ClientStateTracker.connectIntermission(function()
		ClientToolManager.equipTool()
	end)
end

function ClientToolManager.getTool()
	local char = localPlayer.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("Shovel") or char:FindFirstChild("Snowball")
end

function ClientToolManager.isToolEquipped(): boolean
	local char = localPlayer.Character
	if not char then
		return false
	end
	return char:FindFirstChild("Shovel") ~= nil or char:FindFirstChild("Snowball") ~= nil
end

function ClientToolManager.equipTool()
	print("equip")
	local char = localPlayer.Character
	if not char then
		print("return")
		return
	end

	local backShovel = char:FindFirstChild("BackShovel")

	local toolName
	if ModeDetector.getMode() == "SHOOT" and ClientStateTracker.getState() == "ACTIVE" then
		toolName = "Snowball"
		if backShovel then
			makeModelVisible(backShovel , true)
		end
	else
		toolName = "Shovel"
		if backShovel then
			makeModelVisible(backShovel , false)
		end
	end

	
	local tool = localPlayer.Backpack:FindFirstChild(toolName)

	if not tool then
		applyIdleForTool(toolName)
		print("return")
		return
	end

	local equippedTool = char:FindFirstChildOfClass("Tool")

	print("et", equippedTool, tool)

	if tool ~= equippedTool then
		char.Humanoid:UnequipTools()
		char.Humanoid:EquipTool(tool)
	end

	applyIdleForTool(toolName)
end

return ClientToolManager
