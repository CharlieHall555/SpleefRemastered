local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerSpectateController = {}

function ServerSpectateController.onLoaded()

    RemoteEventHandler.newEventConnection("REQUEST_CHEER" , function(fromPlayer , targetPlayer)
        print("GOT REQUEST")
        RemoteEventHandler.FireOnAllClients("CHEERED_PLAYER" , targetPlayer , fromPlayer)
    
    end)

end

return ServerSpectateController