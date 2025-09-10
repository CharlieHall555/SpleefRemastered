local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local ToolManager = require(ModuleDirectory.Gameplay.ToolManager)

local ShovelCustomization = {}

function ShovelCustomization.equipShovel(player : Player , shovelName : string)

   print("types", typeof(player) , typeof(shovelName))

    PlayerData.setShovel(player , shovelName)
    ToolManager.refreshTool(player)
    return true
    
end

return ShovelCustomization