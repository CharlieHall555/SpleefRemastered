local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local BackShovel = {}

local function makeModelVisible(model: Instance, value: boolean)
	local parts = model:GetDescendants()
	for _, each in parts do
		if each:IsA("BasePart") and each.Name ~= "Handle" then
			if value then
				each.Transparency = 0
			else
				each.Transparency = 1
			end
		end
	end
end

-- Tracks the most recent change token per player
local latestTokenByUserId: { [number]: number } = {}

function BackShovel.init()
	RemoteEventHandler.newEventConnection("CLIENT_MODE_CHANGE", function(player, newMode)
		if not player then
			return
		end

		local userId = player.UserId
		local nextToken = (latestTokenByUserId[userId] or 0) + 1
		latestTokenByUserId[userId] = nextToken

		task.delay(0.1, function()
			-- Only act if this is still the latest token for the player
			if latestTokenByUserId[userId] ~= nextToken then
				return
			end

			local character = player.Character
			if not character then
				return
			end

			local accessory = character:FindFirstChild("BackShovel")
			if not accessory then
				return
			end

			local shouldShow = false
			if newMode == "SHOOT" then
				shouldShow = true
			end
			makeModelVisible(accessory, shouldShow)
		end)
	end)

	-- Optional: tidy up tokens when players leave
	Players.PlayerRemoving:Connect(function(player)
		latestTokenByUserId[player.UserId] = nil
	end)
end

return BackShovel
