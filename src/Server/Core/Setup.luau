local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

local SetUp = {}

function SetUp.init()
 
    Players.RespawnTime = Config.RESPAWN_TIME
    
    StarterPlayer.CameraMaxZoomDistance = Config.MAX_ZOOM
    StarterPlayer.CameraMinZoomDistance = 2
    StarterPlayer.CharacterWalkSpeed = 21
    StarterPlayer.CharacterJumpPower = 60
    StarterPlayer.AutoJumpEnabled = false
    StarterPlayer.NameDisplayDistance = 0
    StarterPlayer.HealthDisplayDistance = 0

    if RunService:IsStudio() then
        
        Config.REQUIRED_PLAYERS = 1
        Config.PLAYERS_TO_END = 0
        Config.INTERMISSION_TIME = 10

    end

    

end

return SetUp