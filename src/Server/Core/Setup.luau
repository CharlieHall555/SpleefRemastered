local Players = game:GetService("Players")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)


local SetUp = {}

function SetUp.init()
 
    Players.RespawnTime = Config.RESPAWN_TIME

end

return SetUp