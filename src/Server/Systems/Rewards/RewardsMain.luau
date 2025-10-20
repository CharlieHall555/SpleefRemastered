
local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Leaderstats = require(ModuleDirectory.Player.Leaderstats)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local PlayTimeTracker = require(ModuleDirectory.Player.PlayTimeTracker)
local RewardData = require(ModuleDirectory.Rewards.RewardData)
local CoinManager = require(ModuleDirectory.Monetization.CoinManager)
local EconomyAnalytics = require(ModuleDirectory.Analytics.EconomyAnalytics)


local RewardsMain = {}

local SECONDS_PER_DAY = 86400

local function isDifferentDay(lastTimestamp: number): boolean

	if type(lastTimestamp) ~= "number" or lastTimestamp <= 0 then
		return true
	end

	local now = DateTime.now().UnixTimestamp
	return math.floor(now / SECONDS_PER_DAY) ~= math.floor(lastTimestamp / SECONDS_PER_DAY)
end

local function dayIndexUTC(unix)
	return math.floor(unix / SECONDS_PER_DAY)
end

local lastResetDay = dayIndexUTC(DateTime.now().UnixTimestamp) -- on server boot

function RewardsMain.init()

    task.spawn(function()
        while true do
            task.wait(30) -- check every 30s; doesn't need to be precise
            local nowUTC = DateTime.now().UnixTimestamp
            local today = dayIndexUTC(nowUTC)
            if today ~= lastResetDay then
                lastResetDay = today
                RewardsMain.resetRewards()
            end
        end
    end)

    RemoteEventHandler.newEventConnection("QUERY_DAY" , function(player)

        local currentDay = os.date("!%A")
        currentDay = string.upper(currentDay)
        return currentDay

    end)

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
        local lastSession = PlayerData.getLastRewardSession(player) or 0

        print("last Session" , lastSession)

        if lastSession == 0 or isDifferentDay(lastSession) then
            PlayerData.setClaimedRewards(player, {})
            PlayerData.setLastRewardSession(player, os.time())
        end
    end)


    RemoteEventHandler.newEventConnection("CLAIM_REWARD", function(player, tier: number)
        local claimedRewards = PlayerData.getClaimedRewards(player) or {}

        if table.find(claimedRewards, tier) then
            return
        end

        print(RewardData)

        local currentDay = os.date("!%A")
        currentDay = string.upper(currentDay)

        print(currentDay)

        local playTime = PlayTimeTracker.getPlayTime(player)

        local requiredPlayTime = RewardData[tier]


        if playTime > requiredPlayTime then

            local dailyRewards = RewardData[currentDay]
            local reward = dailyRewards[tier]

            local currency = reward.currency
            local amount = reward.amount

            if currency == "COINS" then
                CoinManager.giveCoins(player, amount)
                EconomyAnalytics.logCoinsTransaction(player, amount, "Source", "TimedReward")
            elseif currency == "LIVES" then
                PlayerData.incrementRespawns(player, amount)
            end

            table.insert(claimedRewards, tier)
            print(claimedRewards)
            PlayerData.setClaimedRewards(player, claimedRewards)

        end
    end)
end

function RewardsMain.resetRewards()
    for _, eachPlayer in pairs(Players:GetPlayers()) do
        if eachPlayer and eachPlayer.Parent then
            PlayerData.setLastRewardSession(eachPlayer, os.time())
            PlayerData.setClaimedRewards(eachPlayer, {})
            PlayTimeTracker.resetPlayTime(eachPlayer)
        end
    end
    RemoteEventHandler.FireOnAllClients("DAILY_REWARDS_RESET" , os.date("!%A"):upper())
end

return RewardsMain
