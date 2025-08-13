-- HitBoxManager.lua (LocalScript)
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ClientHitBoxManager = {}

local tagCallback = {}

local hitBoxSize = 10 -- should be mirrored/validated server-side if authoritative logic depends on it

-- Single reusable hitbox
local sharedHitbox

-- Creates the hitbox part (only once)
local function createPlayerHitbox()
    if sharedHitbox then
        return sharedHitbox
    end

    local hitbox = Instance.new("Part")
    hitbox.Name = "CentralHitbox"
    hitbox.Size = Vector3.new(2, 6, 2) -- adjust to desired player volume
    hitbox.Transparency = 1
    hitbox.Color = Color3.new(0.035294, 0.635294, 0.788235)
    hitbox.Anchored = false
    hitbox.CanCollide = false
    hitbox.Massless = true
    hitbox.CastShadow = false
    hitbox.CanQuery = true
    hitbox.CanTouch = true
    hitbox.TopSurface = Enum.SurfaceType.Smooth
    hitbox.BottomSurface = Enum.SurfaceType.Smooth
    hitbox.Parent = workspace -- initial parent; will be reparented when attached

    sharedHitbox = hitbox
    return hitbox
end

-- Welds the hitbox to the character's HumanoidRootPart so it follows cleanly
local function weldToCharacter(hitbox, character)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then
        warn("Failed to find HumanoidRootPart to weld hitbox to")
        return
    end

    -- Reparent the hitbox under the character for cleanliness
    hitbox.Parent = character
    hitbox.Anchored = false

    -- Position it to match
    hitbox.CFrame = hrp.CFrame

    -- Remove any existing welds on the hitbox
    for _, child in ipairs(hitbox:GetChildren()) do
        if child:IsA("WeldConstraint") then
            child:Destroy()
        end
    end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hitbox
    weld.Part1 = hrp
    weld.Parent = hitbox
end

function ClientHitBoxManager.setUpCallback(tagName: string, callback : (otherPart : Instance) -> nil)
    -- stub: local-side callback logic can be implemented here if needed
    tagCallback[tagName] = callback
end

function ClientHitBoxManager.init()
    -- Ensure single hitbox exists
    local hitbox = createPlayerHitbox()
    ClientHitBoxManager.hitbox = hitbox

    local function attachToCharacter(character)
        weldToCharacter(hitbox, character)
    end

    player.CharacterAdded:Connect(function(character)
        attachToCharacter(character)

        character.Humanoid.Died:Once(function()
            hitbox.Anchored = true
            hitbox.Parent = nil
        end)

    end)

    -- If character already exists (script ran late)
    if player.Character then
        attachToCharacter(player.Character)
    end

    hitbox.Touched:Connect(function(otherPart)
        
        local tags = otherPart:GetTags()
        for _ , each in tags do
            local f = tagCallback[each]
            if f then 
                f(otherPart)
            end
           
        end

    end)
end

function ClientHitBoxManager.getHitbox() : Part?

    return sharedHitbox
    
end

return ClientHitBoxManager