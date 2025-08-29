local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local playerBadgeHandler = require(ModuleDirectory.Badges.PlayerBadgeHandler)

local WinBadgeHandler = {}

-- wins → badgeId (sorted ascending by wins)
local BADGE_THRESHOLDS = {
    { wins = 1,  badgeId = 3520447514208860 },
    { wins = 5,  badgeId = 2852582519047115 },
    { wins = 10, badgeId = 1168684446175066 },
    { wins = 15, badgeId = 4390549912459342 },
    { wins = 20, badgeId = 616714331927071  },
}

function WinBadgeHandler.playerAwardedWin(player: Player, totalWins: number)
    if not player or not player.Parent then
        return
    end

    for _, t in ipairs(BADGE_THRESHOLDS) do
        if totalWins >= t.wins then
            if not playerBadgeHandler.hasBadge(player, t.badgeId) then
                playerBadgeHandler.awardBadge(player, t.badgeId)
            end
        else
            break
        end
    end
end

return WinBadgeHandler
