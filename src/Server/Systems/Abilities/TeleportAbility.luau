local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local AbilitiesDefinitions = require(ModuleDirectory.Abilities.Definitions)
local AbilitiesFunctions = require(ModuleDirectory.Abilities.Functions)
local PlayersAlive = require(ModuleDirectory.Round.PlayersInGame)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local AbilitiesEndFunctions = require(ModuleDirectory.Abilities.EndFunctions)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)


local TeleportAbility = {} 

local TELEPORT_COOLDOWN = AbilitiesDefinitions.TELEPORT.cooldown or 10

local lastTeleport = {}

function TeleportAbility.init()
    
    Players.PlayerRemoving:Connect(function(player : Player)
        lastTeleport[player.UserId] = nil
    end)

    RemoteEventHandler.newEventConnection("REQUEST_TELEPORT" , function(player : Player , block : Part)

        if os.time() - (lastTeleport[player.UserId] or 0) < TELEPORT_COOLDOWN then
            return
        end

        if player.Character == nil then
            return
        end

        lastTeleport[player.UserId] = os.time()

        local char : Model = player.Character

        char:PivotTo( 
            CFrame.new(block.Position + Vector3.new(0 , 7 , 0)) * char.PrimaryPart.CFrame.Rotation
        )

    end)

end

return TeleportAbility