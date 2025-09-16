local LavaPart: Part

local LavaManager = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local RunService = game:GetService("RunService")
local lava = nil
local frameCounter = 0

function LavaManager.init()
	ServerHitBoxManager.setUpCallback("Lava", function(player, otherPart)
		if RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "PREPARING" then
			if player.Character == nil then
				return
			end

			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end)

	RunService.PostSimulation:Connect(function(deltaTimeSim)
		if lava == nil then 
			return 
		end

		if frameCounter > 10 then
			local partsInPart = workspace:GetPartsInPart(lava)
			frameCounter = 0
			for _ , each : Instance in partsInPart do
				local Humanoid = each.Parent:FindFirstChildOfClass("Humanoid")
				if Humanoid then
					Humanoid.Health = 0
				end
			end
		else
			frameCounter += 1
		end
		

	end)

end

function LavaManager.setLava(part : Part)
	lava = part	
end

return LavaManager
