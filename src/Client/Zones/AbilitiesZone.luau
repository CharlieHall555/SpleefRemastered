local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local localPlayer = game.Players.LocalPlayer
local Shop = require(ClientModuleDirectory.Gui.Shop.ShopMain)

local AbilitiesZone = {}

local Zones: Folder
local AbilityZone: Part
local lastOpenTime = 0
local cooldown = 3 -- seconds

function AbilitiesZone.onLoaded()
    
    Zones = game.Workspace:WaitForChild("Zones", 5)

    if not Zones then
        warn("AbilitiesZone: Zones folder not found in Workspace")
        return
    end

    AbilityZone = Zones:WaitForChild("Abilities", 5)

    if not AbilityZone then
        warn("AbilitiesZone: Abilities zone part not found in Zones folder")
        return
    end

    AbilityZone.Touched:Connect(function(hit: BasePart)
        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            local player = game.Players:GetPlayerFromCharacter(character)
            if player and player == localPlayer then
                local now = tick()
                if now - lastOpenTime >= cooldown then
                    lastOpenTime = now
                    if Shop.getVisible() == false then
                        Shop.openAbilitiesFrame()
                        print("Shop opened")
                    end
                else
                    -- Optional: uncomment to debug remaining cooldown
                    -- print("Cooldown active:", math.ceil(cooldown - (now - lastOpenTime)), "s left")
                end
            end
        end
    end)
end

return AbilitiesZone
