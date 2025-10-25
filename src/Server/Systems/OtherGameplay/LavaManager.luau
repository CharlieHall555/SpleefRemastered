local LavaPart: Part

local LavaManager = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local RunService = game:GetService("RunService")
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)

local lava = nil
local frameCounter = 0

local function safeKill(Char) 
	local humanoid = Char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

function LavaManager.init()
	ServerHitBoxManager.setUpCallback("Lava", function(player, otherPart)

		if SessionVariables.getValue(player , "inTutorial") == true then
			
			local tutorialMap = TeleportManager.getMap(player)
			if tutorialMap then	
				TeleportManager.teleport(player , tutorialMap.OriginPosition + Vector3.new(0 , 50 , 0) , true)
			elseif player.Character then
				safeKill(player.Character)
			end

		elseif  RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "PREPARING" then
			if player.Character == nil then
				return
			end
			safeKill(player.Character)
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
