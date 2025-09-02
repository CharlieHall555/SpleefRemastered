local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local KickManager = require(ModuleDirectory.Gameplay.KickManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ProfileTemplate = {
	onboardingStep = 0,
	onboardingComplete = false,
	xp = 0,
	coins = 0,
	level = 1,
	respawns = 0,
	wins = 0,
}

local ProfileService = require(game:GetService("ServerScriptService").External.ProfileStore)

local database = "PRODUCTION"

if RunService:IsStudio() then
	database = "TEST1"
else
	database = "PRODUCTION"
end

local ProfileStore = ProfileService.GetProfileStore(database, ProfileTemplate)

local profiles: { [number]: any } = {}
local loading: { [number]: boolean } = {}
local callback: (playerWhoLoaded: Player) -> nil

local PlayerData: PlayerData = {} :: any

function PlayerData.setCallback(fn: (playerWhoLoaded: Player) -> nil)
	callback = fn
end

function PlayerData.onPlayerAdded(player: Player?)
	local userId = player.UserId
	if profiles[userId] or loading[userId] then
		return
	end

	loading[userId] = true

	task.spawn(function()
		local ok, profile = pcall(function()
			return ProfileStore:LoadProfileAsync("Player_" .. userId)
		end)

		if not ok or profile == nil then
			loading[userId] = nil
			warn("Could not load user profile, user kicked.")
			if player.Parent == Players then
				KickManager.safeKick(player, "Could not load user profile, try again later.")
			end
			return
		end

		profile:AddUserId(userId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			profiles[userId] = nil
			loading[userId] = nil
			if player.Parent == Players then
				KickManager.safeKick(player, "User profile release, Possibly joined from another place?")
			end
		end)

		if player:IsDescendantOf(Players) then
			profiles[userId] = profile
			callback(player)
		else
			profile:Release()
		end

		loading[userId] = nil
	end)
end

function PlayerData.onPlayerRemoving(player: Player)
	local userId = player.UserId
	local profile = profiles[userId]
	if profile ~= nil then
		profile:Release()
	end
	profiles[userId] = nil
	loading[userId] = nil
end

function PlayerData.init(): nil
	RemoteEventHandler.newEventConnection("QUERY_PROFILE_DATA", function(player)
		if PlayerData.isProfileLoaded(player) then
			local profile = profiles[player.UserId]
			return HttpService:JSONEncode(profile.Data or {})
		end
	end)
end

function PlayerData.isProfileLoaded(player: Player): boolean
	return profiles[player.UserId] ~= nil
end

function PlayerData.getWins(player: Player): number
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return 0
	end
	return profile.Data.wins or 0
end

function PlayerData.setWins(player: Player, newValue: number): nil
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return
	end
	profile.Data.wins = newValue
	RemoteEventHandler.FireOnClient(player , "PROFILE_UPDATE", "wins", profile.Data.wins)
end

function PlayerData.incrementWins(player: Player, amount: number): nil
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return
	end
	profile.Data.wins = (profile.Data.wins or 0) + amount
	RemoteEventHandler.FireOnClient(player , "PROFILE_UPDATE", "wins", profile.Data.wins)
end

function PlayerData.getProfile(player: Player): {}
	return profiles[player.UserId]
end

function PlayerData.getXP(player: Player): number
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return 0
	end
	return profile.Data.xp or 0
end

function PlayerData.setXP(player: Player, newValue: number): nil
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return
	end
	profile.Data.xp = newValue
	RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", "xp", profile.Data.xp)

end

function PlayerData.incrementXP(player: Player, amount: number): nil
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return
	end
	profile.Data.xp = (profile.Data.xp or 0) + amount
	RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", "xp", profile.Data.xp)

end

function PlayerData.getLevel(player: Player): number
	local profile = profiles[player.UserId]
	print(profile.Data)
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return 1
	end
	return profile.Data.level or 1
end

function PlayerData.setLevel(player: Player, newValue: number): nil
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return
	end
	profile.Data.level = newValue
	RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", "level", profile.Data.level)

end

function PlayerData.incrementLevel(player: Player, amount: number): nil
	local profile = profiles[player.UserId]
	if profile == nil then
		warn(player.Name .. " profile is nil")
		return
	end
	profile.Data.level = (profile.Data.level or 1) + amount
	RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", "level", profile.Data.level)
end

function PlayerData.getCoins(player: Player): number
    local profile = profiles[player.UserId]
    if profile == nil then
        warn(player.Name .. " profile is nil")
        return 0
    end
    return profile.Data.coins or 0
end

function PlayerData.setCoins(player: Player, newValue: number): nil
    local profile = profiles[player.UserId]
    if profile == nil then
        warn(player.Name .. " profile is nil")
        return
    end
    profile.Data.coins = newValue
    RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", "coins", profile.Data.coins)
end

function PlayerData.incrementCoins(player: Player, amount: number): nil
    local profile = profiles[player.UserId]
    if profile == nil then
        warn(player.Name .. " profile is nil")
        return
    end
    profile.Data.coins = (profile.Data.coins or 0) + amount
    RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", "coins", profile.Data.coins)
end


return PlayerData
