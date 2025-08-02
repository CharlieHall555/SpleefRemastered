local PlayerData = {}
PlayerData.__index = PlayerData

local Datastore2 = require(game:GetService("ServerScriptService").External.DataStore2)

function PlayerData.init() end

function PlayerData.new(Player : Player) 
    local newPlayerData = {}
    newPlayerData.UserId = Player.UserId
    return newPlayerData
end

return PlayerData
