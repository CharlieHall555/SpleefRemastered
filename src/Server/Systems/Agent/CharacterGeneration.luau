local CharacterGeneration = {}


local dummyTemplate : Model 

function CharacterGeneration.init()
    dummyTemplate = game:GetService("ReplicatedStorage"):WaitForChild("Resources"):WaitForChild("Dummy")
end

function CharacterGeneration.generateDummy() : Model
    local out = dummyTemplate:Clone()
    out.Parent = game.Workspace
    local s , r = pcall(function()
         out.PrimaryPart:SetNetworkOwner(nil)
    end)
    if not s then
        warn(r)
    end
    return out
end

return CharacterGeneration