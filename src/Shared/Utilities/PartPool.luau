local RunService = game:GetService("RunService")
local Config 

if RunService:IsClient() then
    local root = game.Players.LocalPlayer.PlayerScripts
    local ClientModuleDirectory = require(root.ClientModuleDirectory)
    Config = require(ClientModuleDirectory.Config)
elseif RunService:IsServer() then
    Config = require(game:GetService("ServerScriptService").ServerConfigurations)
end



local PartPool = {}

local partDump : {Part} = {}

function PartPool.init()

    task.spawn(function()
        PartPool.startUp(Config.INITIAL_PART_POOL)
    end)
        
    
end

function PartPool.startUp(initial)
    local partCount = 0
    for i = 1 , initial do
        partCount += 1
        local newPart = Instance.new("Part")
        newPart.CastShadow = false
        table.insert(partDump , newPart)
        if partCount > Config.PARTS_PER_FRAME then
            task.wait()
        end
    end
    print("Part Pool Initialised.")

end

-- Removes part from the part pool and returns a part.
function PartPool.take() : (Part)?
    
    local part = partDump[1]
    table.remove(partDump , 1)
    return part
    
end

function PartPool.add(part : Part)
    table.insert(partDump , part)
end

return PartPool