local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local HttpService = game:GetService("HttpService")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local isShuttingDown = false

local got_key = false

local MAX_RETRIES = 3
local RETRY_WAIT = 0.1
local UPDATE_INTERVAL = 30 * 60

local BATCH_ENDPOINT = "/leaderboard/batch"

local LEADERBOARD_API_KEY

type updateRecord = {
    user: number,
    new_wins: number,
    global_wins: number,
    level: number
}

local loadedPlayers: { [number]: Player } = {}
local leaderboardCache: { [number]: updateRecord } = {}

local LeaderboardUpdater = {}

local function assembleRecord(userId: number, player: Player): updateRecord
    local wins = PlayerData.getWins(player) or 0
    local level = PlayerData.getLevel(player) or 1
    local cache = leaderboardCache[userId]

    if not cache then
        cache = {
            user = userId,
            new_wins = 0,
            global_wins = wins,
            level = level
        }
        leaderboardCache[userId] = cache
    else
        cache.global_wins = wins
        cache.level = level
    end

    return cache
end

local function resetCache()
    for eachUserId, eachPlayer in loadedPlayers do
        leaderboardCache[eachUserId] = {
            user = eachUserId,
            new_wins = 0,
            global_wins = PlayerData.getWins(eachPlayer) or 0,
            level = PlayerData.getLevel(eachPlayer) or 1
        }
    end
end

function LeaderboardUpdater.init()

    local s , e = pcall(function()
        LEADERBOARD_API_KEY = HttpService:GetSecret("LeaderboardAPIKey")
    end)
    got_key = s

    if got_key == false then
        return
    end

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", LeaderboardUpdater.onPlayerJoin)
    Players.PlayerRemoving:Connect(LeaderboardUpdater.onPlayerLeave)

    task.spawn(function()
        while true do
            task.wait(UPDATE_INTERVAL)
            LeaderboardUpdater.flush()
        end
    end)

    game:BindToClose(function()
        isShuttingDown = true
        -- one final flush; yield here so Roblox waits (up to ~30s total)
        LeaderboardUpdater.flush()
    end)
end

function LeaderboardUpdater.onPlayerJoin(player: Player)
    loadedPlayers[player.UserId] = player
    assembleRecord(player.UserId, player)
end

function LeaderboardUpdater.onPlayerLeave(player: Player)
    loadedPlayers[player.UserId] = nil
    leaderboardCache[player.UserId] = nil
end

-- Call this when a player earns a win so we batch increment accurately between flushes.
function LeaderboardUpdater.incrementWins(userId: number, amount: number)
    local player = loadedPlayers[userId]
    if not player then
        return
    end
    local rec = assembleRecord(userId, player)
    rec.new_wins += math.max(0, amount or 0)
    rec.global_wins = (PlayerData.getWins(player) or rec.global_wins) -- keep fresh
end

function LeaderboardUpdater.flush()
    local list: { updateRecord } = {}

    -- include everyone still cached, even if they’ve left
    for _, rec in pairs(leaderboardCache) do
        -- refresh wins/level if player still present
        local plr = loadedPlayers[rec.user]
        if plr then
            rec.global_wins = PlayerData.getWins(plr) or rec.global_wins
            rec.level = PlayerData.getLevel(plr) or rec.level
        end
        table.insert(list, rec)
    end

    if #list == 0 then
        return
    end

    local requestBody = HttpService:JSONEncode(list)
    local url = (Config.LEADERBOARD_API_ENDPOINT :: string) .. BATCH_ENDPOINT

    local success = false
    local attempt = 0
    while attempt < MAX_RETRIES and not success do
        attempt += 1
        local ok, res = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["x-api-key"] = LEADERBOARD_API_KEY
                },
                Body = requestBody
            })
        end)
        if ok and res and res.Success and res.StatusCode >= 200 and res.StatusCode < 300 then
            success = true
        else
            task.wait(RETRY_WAIT * attempt)
        end
    end

    if success then
        -- after a successful push, clear cache for all records
        leaderboardCache = {}
        -- rebuild cache for currently loaded players
        for userId, plr in loadedPlayers do
            assembleRecord(userId, plr)
        end
    end
end

return LeaderboardUpdater
