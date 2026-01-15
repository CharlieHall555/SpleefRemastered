local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local PlayTimeTracker = require(ModuleDirectory.Player.PlayTimeTracker)
local RewardData = require(ModuleDirectory.Systems.Rewards.RewardData)
local CoinManager = require(ModuleDirectory.Services.Monetization.CoinManager)
local EconomyAnalytics = require(ModuleDirectory.Services.Analytics.EconomyAnalytics)

local RewardsMain = {}

local SECONDS_PER_DAY = 86400

local function dayIndexUTC(unix: number): number
    return math.floor(unix / SECONDS_PER_DAY)
end

local function isDifferentDay(lastTimestamp: number): boolean
    if type(lastTimestamp) ~= "number" or lastTimestamp <= 0 then
        return true
    end
    local now = DateTime.now().UnixTimestamp
    return dayIndexUTC(now) ~= dayIndexUTC(lastTimestamp)
end

local function getCurrentDayUTC(): string
    -- "!%A" returns weekday in UTC; normalize to UPPER_SNAKE style
    return string.upper(os.date("!%A"))
end

local lastResetDay = dayIndexUTC(DateTime.now().UnixTimestamp)

function RewardsMain.init()
    -- Midnight UTC daily reset loop
    task.spawn(function()
        while true do
            task.wait(30)
            local nowUTC = DateTime.now().UnixTimestamp
            local today = dayIndexUTC(nowUTC)
            if today ~= lastResetDay then
                lastResetDay = today
                RewardsMain.resetRewards()
            end
        end
    end)

    -- Query current UTC weekday (e.g., "MONDAY")
    RemoteEventHandler.newEventConnection("QUERY_DAY", function(_player)
        return getCurrentDayUTC()
    end)

    -- Per-session init for a player
    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        local lastSession = PlayerData.getLastRewardSession(player) or 0
        if lastSession == 0 or isDifferentDay(lastSession) then
            PlayerData.setClaimedRewards(player, {})
            PlayerData.setLastRewardSession(player, DateTime.now().UnixTimestamp)
            PlayTimeTracker.resetPlayTime(player)
        end
    end)

    -- Attempt to claim a reward tier (1..n) for the current day
    RemoteEventHandler.newEventConnection("CLAIM_REWARD", function(player: Player, tier: number)
        if type(tier) ~= "number" or tier < 1 then
            return
        end

        local claimedRewards = PlayerData.getClaimedRewards(player) or {}
        if table.find(claimedRewards, tier) then
            return
        end

        local currentDay = getCurrentDayUTC()

        local requiredPlayTime = RewardData[tier]
        if type(requiredPlayTime) ~= "number" then
            return
        end

        local playTime = PlayTimeTracker.getPlayTime(player) or 0
        if playTime < requiredPlayTime then
            return
        end

        local dailyRewards = RewardData[currentDay]
        if type(dailyRewards) ~= "table" then
            return
        end

        local reward = dailyRewards[tier]
        if type(reward) ~= "table" then
            return
        end

        local currency = reward.currency
        local amount = tonumber(reward.amount) or 0
        if amount <= 0 then
            return
        end

        if currency == "COINS" then
            CoinManager.giveCoins(player, amount)
            EconomyAnalytics.logCoinsTransaction(player, amount, "Source", "TimedReward")
        elseif currency == "LIVES" then
            PlayerData.incrementRespawns(player, amount)
        else
            return
        end

        table.insert(claimedRewards, tier)
        PlayerData.setClaimedRewards(player, claimedRewards)
    end)
end

function RewardsMain.resetRewards()
    for _, eachPlayer in ipairs(Players:GetPlayers()) do
        if eachPlayer and eachPlayer.Parent then
            PlayerData.setLastRewardSession(eachPlayer, DateTime.now().UnixTimestamp)
            PlayerData.setClaimedRewards(eachPlayer, {})
            PlayTimeTracker.resetPlayTime(eachPlayer)
        end
    end
    RemoteEventHandler.FireOnAllClients("DAILY_REWARDS_RESET", getCurrentDayUTC())
end

return RewardsMain
