local LavaPart: Part

local LavaManager = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)

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
end

return LavaManager
