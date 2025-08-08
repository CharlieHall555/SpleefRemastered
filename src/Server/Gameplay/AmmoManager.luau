local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.RoundSystem)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

-- USEFUL CONFIGS: Config.MAX_AMMO, Config.STARTING_AMMO

local AmmoManager = {}

local AmmoStore: { [number]: number } = {} -- user id to ammo

local function validatePlayer(player: Player)
	assert(player and player.UserId and player.UserId ~= 0, "Invalid player")
end

local function clampAmmo(value: number): number
	local maxAmmo = Config.MAX_AMMO or math.huge
	return math.clamp(value, 0, maxAmmo)
end

function AmmoManager.init()
	table.clear(AmmoStore)
end

function AmmoManager.startRegenLoop()
	task.spawn(function()
		while RoundSystem.getState() == "ACTIVE" do
			for userId, ammo in pairs(AmmoStore) do
				local newAmmo = clampAmmo(ammo + 1)
				if newAmmo ~= ammo then
					AmmoStore[userId] = newAmmo
				end
			end
			task.wait(Config.AMMO_REGEN_INTERVAL or 2)
		end
	end)
end

function AmmoManager.setUp(players: { Player })
	local starting = clampAmmo(Config.STARTING_AMMO or 0)
	for _, player in ipairs(players) do
		if player and player.UserId and player.UserId ~= 0 then
			AmmoStore[player.UserId] = starting
			RemoteEventHandler.FireOnClient(player , "SET_MAX_AMMO", Config.MAX_AMMO)
			RemoteEventHandler.FireOnClient(player , "AMMO_CHANGED", Config.MAX_AMMO)

		end
	end
end

function AmmoManager.getAmmo(player: Player): number?
	validatePlayer(player)
	return AmmoStore[player.UserId]
end

function AmmoManager.incrementAmmo(player: Player, value: number): nil
	validatePlayer(player)
	assert(type(value) == "number", "value must be a number")

	local userId = player.UserId
	local current = AmmoStore[userId]
	if current == nil then
		current = clampAmmo(Config.STARTING_AMMO or 0)
	end

	local newValue = clampAmmo(current + value)
	RemoteEventHandler.FireOnClient(player , "AMMO_CHANGED", newValue)
	AmmoStore[userId] = newValue
end

function AmmoManager.reset()
	table.clear(AmmoStore)
end

return AmmoManager
