local CharacterGeneration = {}

local OutfitsFolder = game:GetService("ServerStorage"):WaitForChild("Outfits") -- a folder of folders



local dummyTemplate : Model 

function CharacterGeneration.init()
    dummyTemplate = game:GetService("ReplicatedStorage"):WaitForChild("Resources"):WaitForChild("Dummy")
end

local function selectRandomOutfit() : Folder
    local outfits = OutfitsFolder:GetChildren()
    local randomIndex = math.random(1, #outfits)
    return outfits[randomIndex]
end


function CharacterGeneration.generateDummy() : Model
    local out = dummyTemplate:Clone()
    out.Parent = game.Workspace
    out:AddTag("AGENT")
    local s , r = pcall(function()
        for _ , each : BasePart in out:GetChildren() do
            if each:IsA("BasePart") then
                each:SetNetworkOwner(nil)
            end
        end
    end)
    if not s then
        warn(r)
    end
    
    -- Apply random outfit
    local outfit = selectRandomOutfit()
    for _, item in outfit:GetChildren() do
        if item:IsA("BodyColors") or item:IsA("Pants") or item:IsA("Shirt") or item:IsA("Accessory") then
            local clone = item:Clone()
            clone.Parent = out
        end
    end
    
    return out
end

return CharacterGeneration