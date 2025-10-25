-- non persistent variables to be stored about player that may be needed by many scripts.
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Players = game:GetService("Players")

local PlayerSessionVariables = {}

-- Use "coinsMultiplier" to match the rest of your codebase
local default = {
	platform = "PC",
	coinsMultiplier = 1,
	ownedGamepasses = {},
	isVip = false,
	abilityActive = false,
	spawnProtectionActive = false,
	hasUsedRespawn = false,
	isDev = false,
	inGroup = false,
	playTime = 0,
}


local cache: { [number]: { [string]: any } } = {}

function PlayerSessionVariables.init()
	Players.PlayerAdded:Connect(function(player: Player)
		PlayerSessionVariables.create(player)
	end)

	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player, platform: string)
		PlayerSessionVariables.setValue(player, "platform", platform)
	end)

	Players.PlayerRemoving:Connect(PlayerSessionVariables.cleanup)
end

function PlayerSessionVariables.create(player: Player)
	local uid = player.UserId
	if not cache[uid] then
		cache[uid] = {}
	end

	for defaultKey, defaultValue in pairs(default) do
		if cache[uid][defaultKey] == nil then
			if type(defaultValue) == "table" then
				cache[uid][defaultKey] = table.clone(defaultValue)
			else
				cache[uid][defaultKey] = defaultValue
			end
		end
	end

	for key, value in pairs(cache[uid]) do
		RemoteEventHandler.FireOnClient(player, "SESSION_VARIABLE_UPDATED", key, value, true)
	end
end

function PlayerSessionVariables.cleanup(player: Player)
	cache[player.UserId] = nil
end

function PlayerSessionVariables.getValue(player: Player, valueName: string): any
	local userTbl = cache[player.UserId]
	if not userTbl then return nil end
	local v = userTbl[valueName]
	if typeof(v) == "table" then
		return table.clone(v)
	end
	return v
end

function PlayerSessionVariables.setValue(player: Player, valueName: string, value: any)
	local uid = player.UserId
	if not cache[uid] then
		PlayerSessionVariables.create(player)
	end

	cache[uid][valueName] = value

	RemoteEventHandler.FireOnClient(player, "SESSION_VARIABLE_UPDATED", valueName, cache[uid][valueName], false)
end

function PlayerSessionVariables.incrementValue(player: Player, valueName: string, amount: any)

	local value = PlayerSessionVariables.getValue(player, valueName)
	if typeof(value) == "number" and typeof(amount) == "number" then
		value = value + amount
		PlayerSessionVariables.setValue(player, valueName, value)
	else
		warn("Tried to increment non-number session variable: " .. valueName)
	end
	
end

return PlayerSessionVariables
