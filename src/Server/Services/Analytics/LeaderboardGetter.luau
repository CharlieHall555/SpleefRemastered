export type returnRecord = {
	_id: number,
	overall_score: number,
	weekly_score: number,
	monthly_score: number,
	level: number,
	last_updated: string,
}

export type queryResult = {
	period: string,
	top: { returnRecord },
}

export type leaderboardEntry = {
	playerName: string,
	userId: string,
	win: number,
	level: number,
}

export type RefreshCompletedFn = (success: boolean) -> nil

local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local HttpService = game:GetService("HttpService")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local MAX_RETRIES = 3
local RETRY_WAIT = 0.1
local UPDATE_INTERVAL = 45 * 60

local GLOBAL_ENDPOINT = "/leaderboard/global"
local WEEKLY_ENDPOINT = "/leaderboard/weekly"
local MONTHLY_ENDPOINT = "/leaderboard/monthly"

local LEADERBOARD_API_KEY 

local got_key = false

local globalLeaderboard: { leaderboardEntry } = {}
local weeklyLeaderboard: { leaderboardEntry } = {}
local monthlyLeaderboard: { leaderboardEntry } = {}

local nameCache: { [number]: string } = {}

local _refreshCallbacks: { [number]: RefreshCompletedFn } = {}
local _nextCbId = 0

local LeaderboardGetter = {} :: any

local function getUsername(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end

	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and name then
		nameCache[userId] = name
		return name
	end

	local fallback = tostring(userId)
	nameCache[userId] = fallback
	return fallback
end

local function requestGet(path: string): queryResult?
	local url = (Config.LEADERBOARD_API_ENDPOINT :: string) .. path
	local attempt = 0

	while attempt < MAX_RETRIES do
		attempt += 1
		local ok, result = pcall(function()
			return HttpService:RequestAsync({
				Url = url,
				Method = "GET",
				Headers = {
					["Accept"] = "application/json",
					["x-api-key"] = LEADERBOARD_API_KEY,
				},
			})
		end)

		if ok and result and result.Success and result.StatusCode >= 200 and result.StatusCode < 300 then
			local decodeOk, data = pcall(function()
				return HttpService:JSONDecode(result.Body)
			end)
			if decodeOk and data then
				return data :: queryResult
			else
				break
			end
		else
			task.wait(RETRY_WAIT * attempt)
		end
	end

	return nil
end

local function mapToEntries(data: queryResult, which: "global" | "weekly" | "monthly"): { leaderboardEntry }
	local out: { leaderboardEntry } = {}

	for _, rec in ipairs(data.top) do
		local userId = tonumber(rec._id) or rec._id
		local wins = 0
		if which == "global" then
			wins = rec.overall_score or 0
		elseif which == "weekly" then
			wins = rec.weekly_score or 0
		else
			wins = rec.monthly_score or 0
		end

		table.insert(out, {
			playerName = getUsername(userId),
			userId = tostring(userId),
			win = wins,
			level = rec.level or 1,
		})
	end

	return out
end

local function fireRefreshCompleted(success: boolean)
	for _, fn in _refreshCallbacks do
		task.spawn(function()
			local ok = pcall(fn, success)
			if not ok then
				-- swallow callback errors
			end
		end)
	end
end

function LeaderboardGetter.refreshAll()
	local g = requestGet(GLOBAL_ENDPOINT)
	local w = requestGet(WEEKLY_ENDPOINT)
	local m = requestGet(MONTHLY_ENDPOINT)

	local allOk = (g ~= nil and w ~= nil and m ~= nil)

	if g then
		globalLeaderboard = mapToEntries(g, "global")
	end
	if w then
		weeklyLeaderboard = mapToEntries(w, "weekly")
	end
	if m then
		monthlyLeaderboard = mapToEntries(m, "monthly")
	end

	fireRefreshCompleted(allOk)
end

function LeaderboardGetter.getGlobal(): { leaderboardEntry }
	return globalLeaderboard
end

function LeaderboardGetter.getWeekly(): { leaderboardEntry }
	return weeklyLeaderboard
end

function LeaderboardGetter.getMonthly(): { leaderboardEntry }
	return monthlyLeaderboard
end

function LeaderboardGetter.connectOnRefreshCompleted(fn: RefreshCompletedFn): number
	_nextCbId += 1
	_refreshCallbacks[_nextCbId] = fn
	return _nextCbId
end

function LeaderboardGetter.disconnectOnRefreshCompleted(id: number)
	_refreshCallbacks[id] = nil
end

function LeaderboardGetter.init()

    local s , e = pcall(function()
        LEADERBOARD_API_KEY = HttpService:GetSecret("LeaderboardAPIKey")
    end)
    got_key = s

    if got_key == false then
        return
    end

	LeaderboardGetter.connectOnRefreshCompleted(function(success)
		local jsonLeaderboard = HttpService:JSONEncode({
			global = LeaderboardGetter.getGlobal(),
			weekly = LeaderboardGetter.getWeekly(),
			monthly = LeaderboardGetter.getMonthly(),
		})

		RemoteEventHandler.FireOnAllClients("GLOBAL_LEADERBOARD_UPDATE", jsonLeaderboard)
	end)

	RemoteEventHandler.newEventConnection("QUERY_GLOBAL_LEADERBOARD", function(player)
		local jsonLeaderboard = HttpService:JSONEncode({
			global = LeaderboardGetter.getGlobal(),
			weekly = LeaderboardGetter.getWeekly(),
			monthly = LeaderboardGetter.getMonthly(),
		})
		return jsonLeaderboard
	end)
	
	task.spawn(function()
		LeaderboardGetter.refreshAll()
	end)

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			LeaderboardGetter.refreshAll()
		end
	end)
end

return LeaderboardGetter
