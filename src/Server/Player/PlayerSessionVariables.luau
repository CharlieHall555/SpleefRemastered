--non persistent varaibles to be stored about player that may be needed by many scripts.
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Players = game:GetService("Players")

local PlayerSessionVariables = {}

local default = {
    platform = "PC",
    coinMultiplier = 1,
    ownedGamepasses = {},
    isVip = false
}

local cache : {[number] : {}} = {}

function PlayerSessionVariables.init()
    
    Players.PlayerAdded:Connect(function(player : Player)
        PlayerSessionVariables.create(player)
    end)

    RemoteEventHandler.newEventConnection("PLAYER_LOADED" , function(player , platform)
        PlayerSessionVariables.setValue(player , "platform" , platform)
    end)

    Players.PlayerRemoving:Connect(PlayerSessionVariables.cleanup)

end

function PlayerSessionVariables.create(player : Player) 
    
    cache[player.UserId] = {
        platform = default.platform,
        coinMultiplier = default.coinMultiplier,
    }
    
end

function PlayerSessionVariables.cleanup(player : Player)
    
    cache[player.UserId] = nil
    
end


function PlayerSessionVariables.getValue(player : Player , valueName : string) : any   
    if not cache[player.UserId] then
        return nil
    end
    return cache[player.UserId][valueName] 
end

function PlayerSessionVariables.setValue(player : Player , valueName : string , value : any) : {}
    if not cache[player.UserId] then
        return nil
    end
    cache[player.UserId][valueName] = value
    RemoteEventHandler.FireOnClient(player , "SESSION_VARIABLE_UPDATED" , valueName , value , false)
end

return PlayerSessionVariables