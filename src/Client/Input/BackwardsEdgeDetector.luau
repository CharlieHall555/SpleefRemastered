--this will be called externally
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local blockRaycast = RaycastParams.new()
blockRaycast.FilterType = Enum.RaycastFilterType.Exclude
blockRaycast.IgnoreWater = true
blockRaycast.CollisionGroup = "CG_BLOCK_SELECTION"

local BackwardsEdgeDetector = {}

-- Casts a ray from behind the player's HumanoidRootPart downwards
-- Returns the Part hit, or nil if nothing
function BackwardsEdgeDetector.getBlockBehind(distance : number): Part?
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
    if not hrp then
        return nil
    end

    -- position just behind the player
    local backOffset = -hrp.CFrame.LookVector * distance -- 2 studs behind
    local origin = hrp.Position + backOffset + Vector3.new(0, 2, 0)

    -- cast down from that point
    local direction = Vector3.new(0, -6, 0)
    local result = workspace:Raycast(origin, direction, blockRaycast)

    if result and result.Instance and result.Instance:IsA("BasePart") then
        return result.Instance
    end

    return nil
end

return BackwardsEdgeDetector