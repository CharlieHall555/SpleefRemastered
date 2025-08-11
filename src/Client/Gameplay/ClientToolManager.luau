local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local localPlayer = game.Players.LocalPlayer
local backpack = localPlayer.Backpack

local ClientToolManager = {}

function ClientToolManager.init()
	backpack.ChildAdded:Connect(function(child)
        print("added")
		local char = localPlayer.Character

		if child:IsA("Tool") and child:HasTag("Shovel") and char then
			if char.Humanoid then
				char.Humanoid:EquipTool(child)
			end
		end
	end)
end

return ClientToolManager
