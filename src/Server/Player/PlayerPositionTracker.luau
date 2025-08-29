local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RunService = game:GetService("RunService")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Configurations = require(game:GetService("ServerScriptService").ServerConfigurations)
local Players = game:GetService("Players")

local PlayerPositionTracker = {}

-- State
local lastUpdateTime = {} -- [userId] = timestamp
local unresponsivePlayers = {} -- set: [userId] = true
local cache = {} -- [userId] = Vector3

-- Threshold cached for performance
local UNRESPONSIVE_THRESHOLD = Configurations.UNRESPONSIVE_CLIENT_THRESHOLD

Players.PlayerAdded:Connect(function(player)
    
    local uid = player.UserId

    cache[uid] = cache[uid] or nil
    lastUpdateTime[uid] = lastUpdateTime[uid] or 0
    unresponsivePlayers[uid] = nil  -- ensure clean slate

end)

function PlayerPositionTracker.removePlayer(player)
	local uid = player.UserId
	if player.character then
		player.character.PrimaryPart:SetNetworkOwner(player)
	end
	lastUpdateTime[uid] = nil
	cache[uid] = nil
	unresponsivePlayers[uid] = nil
end

-- Cleanup when a player leaves
Players.PlayerRemoving:Connect(PlayerPositionTracker.removePlayer)

-- Helper to mark player responsive again (with optional debounce if desired)
local function restoreNetworkOwnership(player)
	if not player then
		return
	end
	local character = player.Character
	if not character or not character.PrimaryPart then
		return
	end

	-- Only restore if they were previously considered unresponsive
	if unresponsivePlayers[player.UserId] then
		-- Set network owner safely
		pcall(function()
			character.PrimaryPart:SetNetworkOwner(player)
		end)
		unresponsivePlayers[player.UserId] = nil
	end
end

function PlayerPositionTracker.init(): nil
	RemoteEventHandler.newEventConnection("UpdatePlayerPosition", function(player, newPosition)
		if not player then
			return
		end
		local uid = player.UserId

		cache[uid] = newPosition
		lastUpdateTime[uid] = time()

		-- If previously marked unresponsive, restore ownership
		if unresponsivePlayers[uid] then
			restoreNetworkOwnership(player)
		end
	end)

	RunService.Heartbeat:Connect(function(deltaT)
		local now = time()
		for playerId, lastTime in pairs(lastUpdateTime) do
			local timeDelta = now - lastTime
			if timeDelta > UNRESPONSIVE_THRESHOLD then
				local player = Players:GetPlayerByUserId(playerId)
				if player then
					local character = player.Character
					if character and character.PrimaryPart then
						-- If not already marked unresponsive, do it
						if not unresponsivePlayers[playerId] then
							-- Clear network ownership so server simulates
							pcall(function()
								character.PrimaryPart:SetNetworkOwner(nil)
                                warn("Player Unresponsive, UserId:", playerId)
							end)
							unresponsivePlayers[playerId] = true
						end
					end
				else
					-- Player left; cleanup
					lastUpdateTime[playerId] = nil
					cache[playerId] = nil
					unresponsivePlayers[playerId] = nil
					warn("Removed player from tracking tables because they are no longer present. UserId:", playerId)
				end
			end
		end
	end)
end

-- Safe accessor: returns stored position or nil
function PlayerPositionTracker.getPosition(player)
	if not player then
		return nil
	end
	return cache[player.UserId]
end

return PlayerPositionTracker
