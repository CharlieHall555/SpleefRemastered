local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
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

function LeaderboardUpdater.init()
    local s = pcall(function()
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
        LeaderboardUpdater.flush()
    end)
end

function LeaderboardUpdater.onPlayerJoin(player: Player)
    loadedPlayers[player.UserId] = player
    assembleRecord(player.UserId, player)
end

function LeaderboardUpdater.onPlayerLeave(player: Player)
    loadedPlayers[player.UserId] = nil
    -- keep the cached record so it flushes later; snapshot latest values once more
    local rec = leaderboardCache[player.UserId]
    if rec then
        rec.global_wins = PlayerData.getWins(player) or rec.global_wins
        rec.level = PlayerData.getLevel(player) or rec.level
    end
end

-- Call this when a player earns a win so we batch increment accurately between flushes.
function LeaderboardUpdater.incrementWins(userId: number, amount: number)
    local player = loadedPlayers[userId]
    local rec: updateRecord?

    if player then
        rec = assembleRecord(userId, player)
        rec.global_wins = PlayerData.getWins(player) or rec.global_wins
    else
        -- if player not loaded, ensure a cache entry exists to count late flushes
        rec = leaderboardCache[userId]
        if not rec then
            rec = {
                user = userId,
                new_wins = 0,
                global_wins = 0,
                level = 1
            }
            leaderboardCache[userId] = rec
        end
    end

    rec.new_wins += math.max(0, amount or 0)
end

function LeaderboardUpdater.flush()
    if RunService:IsStudio() and Config.UPDATE_LEADERBOARD_IN_STUDIO == false then
        warn("Leaderboard flush aborted, UPDATE_LEADERBOARD_IN_STUDIO is false.")
        return
    end

    if not got_key then
        return
    end

    local list: { updateRecord } = {}

    -- include everyone in cache (even if they have left)
    for _, rec in pairs(leaderboardCache) do
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
        leaderboardCache = {}
        for userId, plr in pairs(loadedPlayers) do
            assembleRecord(userId, plr)
        end
    end
end

return LeaderboardUpdater
