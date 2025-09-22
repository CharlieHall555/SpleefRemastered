local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local AbilitiesFunctions = require(ClientModuleDirectory.Abilities.Functions)

local LocalPlayer = game.Players.LocalPlayer

local ClientAbilities = {}

function ClientAbilities.init()

    RemoteEventHandler.newEventConnection("FIRE_ABILITY" , function(abil_name : string , data : {})
        
        print(abil_name)

        local callback = AbilitiesFunctions[abil_name]
        if callback then
            callback(LocalPlayer , LocalPlayer.Character , data)
        end

    end)
    
end


return ClientAbilities