-- ServerConstants.lua
-- Global constants that ALWAYS replicate to clients

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerConstants = {}

local default = {
	infiniteAmmo = false,
	ammoRegenInterval = 0
}

local cache: { [string]: any } = {}

local function cloneIfTable(v: any)
	if typeof(v) == "table" then
		return table.clone(v)
	end
	return v
end

local function replicateAllToPlayer(player: Player)
	for key, value in pairs(cache) do
		RemoteEventHandler.FireOnClient(player, "SERVER_CONSTANT_UPDATED", key, value, true)
	end
end

function ServerConstants.init()
	-- init defaults once
	for k, v in pairs(default) do
		if cache[k] == nil then
			cache[k] = cloneIfTable(v)
		end
	end

	-- send full snapshot when player signals loaded
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
		replicateAllToPlayer(player)
	end)
end

function ServerConstants.getValue(valueName: string): any
	return cloneIfTable(cache[valueName])
end

function ServerConstants.setValue(valueName: string, value: any)
	cache[valueName] = cloneIfTable(value)

	-- ALWAYS replicate changes to everyone
	RemoteEventHandler.FireOnAllClients("SERVER_CONSTANT_UPDATED", valueName, cache[valueName], false)
end

function ServerConstants.incrementValue(valueName: string, amount: any)
	local current = ServerConstants.getValue(valueName)

	if typeof(current) == "number" and typeof(amount) == "number" then
		ServerConstants.setValue(valueName, current + amount)
	else
		warn("Tried to increment non-number server constant: " .. valueName)
	end
end

function ServerConstants.resetValue(valueName: string)
	local dv = default[valueName]
	if dv == nil then
		warn("No default exists for constant: " .. valueName)
		return
	end
	ServerConstants.setValue(valueName, dv)
end

function ServerConstants.resetAll()
	for k, dv in pairs(default) do
		ServerConstants.setValue(k, dv)
	end
end

return ServerConstants
