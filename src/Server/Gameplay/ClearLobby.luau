local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayersAlive = require(ModuleDirectory.Round.PlayersInGame)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)

local clearParams = OverlapParams.new()
clearParams.CollisionGroup = "CG_GAMEPLAY"

local ClearLobby = {}

local LobbyHitbox: Part?

function ClearLobby.init()
	LobbyHitbox = game.Workspace.Lobby:WaitForChild("LobbyHitBox")

	task.spawn(function()
		while true do

            if RoundSystem.getState() == "ACTIVE" then
                ClearLobby.clear()
            end
           

			task.wait(1)
		end
	end)
end

function ClearLobby.clear()
	if LobbyHitbox then
		local parts = workspace:GetPartsInPart(LobbyHitbox, clearParams)

		for _, eachHitbox: Part in parts do
			local char = eachHitbox.Parent
			local humanoid: Humanoid = char:FindFirstChild("Humanoid")
			if humanoid then
				local player = Players:GetPlayerFromCharacter(char)
				if player and PlayersAlive.isAlive(player) then
					humanoid.Health = 0
				end
			end
		end
	end
end

return ClearLobby
