-- KnockbackUtilities.lua

local KnockbackUtilities = {}

local AIR_MULTIPLIER = 0.14

function KnockbackUtilities.isAirborne(h: Humanoid): boolean
    if h.FloorMaterial == Enum.Material.Air then
        return true
    end
    local s = h:GetState()
    return s == Enum.HumanoidStateType.Freefall
        or s == Enum.HumanoidStateType.Jumping
        or s == Enum.HumanoidStateType.FallingDown
end

function KnockbackUtilities.computeImpulse(rootPart: BasePart, humanoid: Humanoid?, dir: Vector3, power: number): Vector3
    if dir.Magnitude < 1e-3 then
        return Vector3.zero
    end

    local dirUnit = dir.Unit
    local finalDeltaV = power

    if humanoid and KnockbackUtilities.isAirborne(humanoid) then
        finalDeltaV *= AIR_MULTIPLIER
    end

    local mass = rootPart.AssemblyMass
    return dirUnit * (finalDeltaV * mass)
end

return KnockbackUtilities
