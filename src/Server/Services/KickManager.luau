
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerPositionTracker = require(ModuleDirectory.Player.PlayerPositionTracker)

local KickManager = {}

function KickManager.init()
    
end

function KickManager.safeKick(player : Player , reason : string) : nil
    reason = reason or "You have been kicked."
    PlayerPositionTracker.removePlayer(player)
    player:Kick(reason)
end

return KickManager