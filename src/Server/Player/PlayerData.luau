local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ProfileManager = require(ModuleDirectory.Player.ProfileManager)

local PlayerData = {} :: any

local function getData(player: Player): any?
	if not ProfileManager.isProfileLoaded(player) then
		warn(player.Name .. " profile not loaded")
		return nil
	end
	if ProfileManager.getProfile then
		local profile = ProfileManager.getProfile(player)
		return profile and profile.Data or nil
	end

end

local function setFieldAndNotify(player: Player, fieldName: string, value: any): nil
	local ok = false
	if ProfileManager.setField then
		ok = ProfileManager.setField(player.UserId, fieldName, value)
	end
	if ok then
		RemoteEventHandler.FireOnClient(player, "PROFILE_UPDATE", fieldName, value)
	else
		warn("Failed to set field '" .. fieldName .. "' for " .. player.Name)
	end
end

function PlayerData.setCallback(fn: (playerWhoLoaded: Player) -> nil)
	if ProfileManager.setCallback then
		ProfileManager.setCallback(fn)
	end
end

function PlayerData.onPlayerAdded(player: Player)
	if ProfileManager.onPlayerAdded then
		ProfileManager.onPlayerAdded(player)
	end
end

function PlayerData.onPlayerRemoving(player: Player)
	if ProfileManager.onPlayerRemoving then
		ProfileManager.onPlayerRemoving(player)
	end
end

function PlayerData.init(): nil
	RemoteEventHandler.newEventConnection("QUERY_PROFILE_DATA", function(player: Player)
		if PlayerData.isProfileLoaded(player) then
			local data = getData(player)
			return HttpService:JSONEncode(data or {})
		end
		return HttpService:JSONEncode({})
	end)
end

function PlayerData.isProfileLoaded(player: Player): boolean
	return ProfileManager.isProfileLoaded and ProfileManager.isProfileLoaded(player) or false
end

function PlayerData.getProfile(player: Player): any?
	return getData(player)
end

function PlayerData.getWins(player: Player): number
	local data = getData(player)
	return data and (data.wins or 0) or 0
end

function PlayerData.setWins(player: Player, newValue: number): nil
	setFieldAndNotify(player, "wins", newValue)
end

function PlayerData.incrementWins(player: Player, amount: number): nil
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "wins", (data.wins or 0) + amount)
end

function PlayerData.getXP(player: Player): number
	local data = getData(player)
	return data and (data.xp or 0) or 0
end

function PlayerData.setXP(player: Player, newValue: number): nil
	setFieldAndNotify(player, "xp", newValue)
end

function PlayerData.incrementXP(player: Player, amount: number): nil
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "xp", (data.xp or 0) + amount)
end

function PlayerData.getLevel(player: Player): number
	local data = getData(player)
	return data and (data.level or 1) or 1
end

function PlayerData.setLevel(player: Player, newValue: number): nil
	setFieldAndNotify(player, "level", newValue)
end

function PlayerData.incrementLevel(player: Player, amount: number): nil
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "level", (data.level or 1) + amount)
end

function PlayerData.getRespawns(player: Player): number
	local data = getData(player)
	return data and (data.respawns or 1) or 1
end

function PlayerData.setRespawns(player: Player, newValue: number): nil
	setFieldAndNotify(player, "respawns", newValue)
end

function PlayerData.incrementRespawns(player: Player, amount: number): nil
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "respawns", (data.respawns or 1) + amount)
end

function PlayerData.getCoins(player: Player): number
	local data = getData(player)
	return data and (data.coins or 0) or 0
end

function PlayerData.setCoins(player: Player, newValue: number): nil
	setFieldAndNotify(player, "coins", newValue)
end

function PlayerData.incrementCoins(player: Player, amount: number): nil
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "coins", (data.coins or 0) + amount)
end

function PlayerData.getHasJoinedBefore(player: Player): boolean
	local data = getData(player)
	return data and (data.hasJoinedBefore == true) or false
end

function PlayerData.setHasJoinedBefore(player: Player, newValue: boolean): nil
	setFieldAndNotify(player, "hasJoinedBefore", newValue == true)
end

function PlayerData.getRoundsPlayed(player: Player): number
	local data = getData(player)
	return data and (data.roundsPlayed or 0) or 0
end

function PlayerData.setRoundsPlayed(player: Player, newValue: number): nil
	setFieldAndNotify(player, "roundsPlayed", newValue)
end

function PlayerData.incrementRoundsPlayed(player: Player, amount: number): nil
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "roundsPlayed", (data.roundsPlayed or 0) + amount)
end

function PlayerData.getShovel(player: Player): string
	local data = getData(player)
	return data and (data.shovel or "DEFAULT") or "DEFAULT"
end

function PlayerData.setShovel(player: Player, newValue: string): string
	local data = getData(player)
	if not data then
		return
	end
	setFieldAndNotify(player, "shovel", newValue)
end

return PlayerData
