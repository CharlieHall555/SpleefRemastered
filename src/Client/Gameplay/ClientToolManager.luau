local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local localPlayer = game.Players.LocalPlayer
local backpack = localPlayer.Backpack
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local ClientToolManager = {}

local MAX_EQUIP_ATTEMPTS = 10
local ATTEMPT_DELAY = 0.1

function ClientToolManager.init()
	ClientStateTracker.connectServerStateChange(function(newState: string)
		if newState ~= "ACTIVE" then
			return
		end

		task.spawn(function()
			local a = 0
			while a <= MAX_EQUIP_ATTEMPTS do
				local char = localPlayer.Character
				if char == nil then
					continue
				end

				local tool = char:FindFirstChild("Shovel")
				if tool then
					break
				end

				local toolInBackpack = localPlayer.Backpack:FindFirstChild("Shovel")
				if toolInBackpack then
					char.Humanoid:EquipTool(toolInBackpack)
					break
				end

				task.wait(ATTEMPT_DELAY)
			end
		end)
	end)
end

function ClientToolManager.isToolEquipped(): boolean
	local char = localPlayer.Character
	if char == nil then
		return false
	end
	local tool = char:FindFirstChild("Shovel")
	if tool then
		return true
	else
		return false
	end
end

return ClientToolManager
