local ServerLoader = require(game:GetService("ServerScriptService").Core.ServerLoader)
ServerLoader.init()

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local RoundSystem = require(ModuleDirectory.RoundSystem)
RoundSystem.main()  

--[[local ThrowableManager = require(ModuleDirectory.ThrowableManager)

while true do

    ThrowableManager.newThrowable(Vector3.new(-100 , 20 , -100) , Vector3.new(math.random(), math.random() , math.random()) , "snowball")
    
    task.wait(0)
    
end]]--
