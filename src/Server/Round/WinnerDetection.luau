local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerDeathDetector = require(ModuleDirectory.PlayerDeathDetector)

local WinnerDetection = {}
local _rng = Random.new()

function WinnerDetection.init()
    -- no-op
end

function WinnerDetection.getWinner(playerList: { Player }): Player
    assert(playerList and #playerList > 0, "playerList must be a non-empty array")

    local alive: { Player } = {}
    local latestTime = -math.huge
    local latest: { Player } = {}

    for _, player in ipairs(playerList) do
        local deathTime = PlayerDeathDetector.getDeathTime(player)

        if deathTime == nil then
            table.insert(alive, player) -- still alive
        else
            if deathTime > latestTime then
                latestTime = deathTime
                latest = { player }
            elseif deathTime == latestTime then
                table.insert(latest, player)
            end
        end
    end

    if #alive > 0 then
        if #alive == 1 then
            return alive[1]
        else
            return alive[_rng:NextInteger(1, #alive)] -- tie-break alive players
        end
    end

    if #latest == 0 then
        return playerList[_rng:NextInteger(1, #playerList)] -- fallback
    elseif #latest == 1 then
        return latest[1]
    else
        return latest[_rng:NextInteger(1, #latest)] -- tie-break latest death
    end
end

return WinnerDetection