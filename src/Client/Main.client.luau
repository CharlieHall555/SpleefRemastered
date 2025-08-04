local Root = script.Parent
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientLoader = require(Root.Core.ClientLoader)
ClientLoader.init()

local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
RemoteEventHandler.FireOnServer("PLAYER_LOADED")

local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)
HitBoxManager.setUpCallback("Block" , function(otherPart)

    print(otherPart)

end)