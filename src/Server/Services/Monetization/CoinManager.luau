
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerSessionVariables = require(ModuleDirectory.Player.SessionVariables)


local CoinManager = {}

function CoinManager.init()
    
end

function CoinManager.takeCoins(player : Player , amount : number)

    local amount = math.min(PlayerData.getCoins(player) , amount)
    PlayerData.incrementCoins(player , -amount)
    return amount
    
end

function CoinManager.hasCoins(player : Player , amount : number) : boolean

    local currentCoins = PlayerData.getCoins(player) or 0
    return currentCoins >= amount
    
end

function CoinManager.getMultiplier(player : Player) : number
    return PlayerSessionVariables.getValue(player , "coinMultiplier") or 1
end

function CoinManager.giveCoins(player : Player , amount : number) : nil

    local multiplier = PlayerSessionVariables.getValue(player , "coinMultiplier") or 1
    amount = math.floor(amount * multiplier)

    PlayerData.incrementCoins(player , amount)
    return amount
    
end

return CoinManager