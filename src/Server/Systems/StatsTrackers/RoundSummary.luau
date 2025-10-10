local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local BlockDestructionTracker = require(ModuleDirectory.Gameplay.BlockDestructionTracker)
local PlayerDeathDetector = require(ModuleDirectory.Round.PlayerDeathDetector)
local EliminationTracker = require(ModuleDirectory.Stats.EliminationTracker)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local WinnerDetection = require(ModuleDirectory.Stats.WinnerDetection)
local CoinsManager = require(ModuleDirectory.Monetization.CoinManager)
local LevelController = require(ModuleDirectory.LevelSystem.LevelController)
local EconomyAnalytics = require(ModuleDirectory.Analytics.EconomyAnalytics)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local RoundSummary = {}

export type EndSummary = {
    timeAlive: number,
    blocksDestroyed: number,
    eliminations: number,
    coinsGained: number, -- total coins granted (base + winnerBonus)
    xpGained: number,
    winnerBonus: number -- explicit coin win bonus granted
}



-- Utility: safe table length
local function count(list)
    if typeof(list) == "table" then
        return #list
    end
    return 0
end

-- Utility: server time (fallback)
local function now()
    if workspace.GetServerTimeNow then
        return workspace:GetServerTimeNow()
    end
    return time()
end

-- Clamp helper
local function clamp(n, lo, hi)
    return math.max(lo, math.min(hi, n))
end

-- === Rewards design ===
-- Coins: performance-focused (blocks, eliminations), with explicit win bonus.
local function calcBaseCoins(timeAlive: number, blocksDestroyed: number, eliminations: number): number
    local bd = clamp(blocksDestroyed, 0, 600)
    local elims = clamp(eliminations, 0, 50)
    local tAlive = clamp(timeAlive, 0, 600)

    local coins = 0
    coins += bd * 0.05 -- 10 blocks = 1 coin
    coins += elims * 5 -- 10 coins ber elim
    coins += math.floor(tAlive / 10) -- every 10s alive = 1 coin (low weight)

    return math.max(0, math.floor(coins))
end

-- Winner bonus: explicit and separate from base. To preserve previous doubling behavior, set bonus = base.
local function calcCoinWinBonus(baseCoins: number): number
    return math.max(10, baseCoins)
end

-- XP: participation-first (time), flat win bonus so losers still progress.
local function calcXp(winner: boolean, timeAlive: number, blocksDestroyed: number, eliminations: number): number
    local bd = clamp(blocksDestroyed, 0, 600)
    local elims = clamp(eliminations, 0, 50)
    local tAlive = clamp(timeAlive, 0, 600)

    local xp = 0
    xp += math.floor(tAlive / 5) -- every 5s alive = 1 XP (steady drip)
    xp += bd * 0.2
    xp += elims * 5
    if winner then
        xp += 50 -- flat win bonus
    end

    return math.max(0, math.floor(xp))
end

function RoundSummary.onRoundEnd(round: RoundSystem.Round, winner: Player?)
    local roundEnd = now()

    for _, eachPlayer in ipairs(round.startingPlayers or {}) do
        if eachPlayer and eachPlayer.Parent then
            local isWinner = (winner == eachPlayer)

            local deathTime
            pcall(function()
                deathTime = PlayerDeathDetector.getDeathTime(eachPlayer)
            end)
            local aliveUntil = deathTime or roundEnd
            local tAlive = math.max(0, (aliveUntil - round.startTime))
            tAlive = math.min(tAlive, roundEnd - round.startTime)

            local blocks = count(BlockDestructionTracker.getBlocksDestroyedByPlayer(eachPlayer))
            local elims = count(EliminationTracker.getElimationsFor(eachPlayer))

            -- Compute rewards (coins use explicit winner bonus)
            local baseCoins = calcBaseCoins(tAlive, blocks, elims)
            local winnerBonus = isWinner and calcCoinWinBonus(baseCoins) or 0
            local coinsCollected = SessionVariables.getValue(eachPlayer, "coinsCollected") or 0

            local coinMultiplier = CoinsManager.getMultiplier(eachPlayer)

            local totalCoins = baseCoins + winnerBonus + coinsCollected

            local xpGained = calcXp(isWinner, tAlive, blocks, elims)

            totalCoins = CoinsManager.giveCoins(eachPlayer, totalCoins)
            LevelController.giveXp(eachPlayer , xpGained)
            EconomyAnalytics.logCoinsTransaction(eachPlayer , totalCoins , "Source" , "Gameplay")


            local summary: EndSummary = {
                timeAlive = tAlive,
                blocksDestroyed = blocks,
                eliminations = elims,
                coinsGained = totalCoins,
                xpGained = xpGained,
                winnerBonus = math.floor(winnerBonus * coinMultiplier),
                coinsCollected = math.floor(coinsCollected * coinMultiplier),
                rouundLength = roundEnd - round.startTime
            }

            RemoteEventHandler.FireOnClient(eachPlayer, "ROUND_SUMMARY", summary)
        end
    end
end

-- Suggestions:
-- - Consider surfacing baseCoins in the summary if you want the client UI to break down coins further.

return RoundSummary
