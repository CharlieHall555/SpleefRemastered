local Root = script.Parent
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientLoader = require(Root.Core.ClientLoader)
ClientLoader.init()

local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
RemoteEventHandler.FireOnServer("PLAYER_LOADED")

local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)


local ClientThrowableTracker = require(ClientModuleDirectory.ClientThrowableTracker)

while true do

    ClientThrowableTracker.newThrowable(Vector3.new(10 , 20 , 30) , Vector3.new(math.random(), math.random() , math.random()))
    task.wait(0.1)
    
end