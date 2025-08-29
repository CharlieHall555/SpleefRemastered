local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local MAX_RAY = 1000
local ASSIST_ANGLE = math.rad(12)
local PLAYER_STRENGTH_MULT = 1.35

local overlapsParams = OverlapParams.new()
overlapsParams.CollisionGroup = "CG_GAMEPLAY"
overlapsParams.FilterDescendantsInstances = {}
overlapsParams.FilterType = Enum.RaycastFilterType.Exclude

local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "CG_GAMEPLAY"
raycastParams.FilterDescendantsInstances = {}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

export type AimAssistSuggestion = {
    deltaYaw: number,
    deltaPitch: number,
    strength: number
}

local AimAssistController = {}

local DEBUG = false
local _debugFolder: Folder? = nil
local _hitStamp: BasePart? = nil
local _radiusDisc: BasePart? = nil
local DISC_THICKNESS = 0.05

local TAG_BLOCK = "Block"
local TAG_PLAYER_HITBOX = "PLAYER_HITBOX"

local function calculateRadiusSize(distanceRayTravelled: number): number
    return distanceRayTravelled * math.tan(ASSIST_ANGLE)
end

local function yawPitchFromDir(v: Vector3): (number, number)
    local yaw = math.atan2(v.X, v.Z)
    local pitch = math.asin(math.clamp(v.Y, -1, 1))
    return yaw, pitch
end

local function normalizeAngle(angle: number): number
    while angle > math.pi do
        angle -= 2 * math.pi
    end
    while angle < -math.pi do
        angle += 2 * math.pi
    end
    return angle
end

local function refreshFilters()
    local excludes = {}
    local character = LocalPlayer.Character
    if character then
        table.insert(excludes, character)
    end
    overlapsParams.FilterDescendantsInstances = excludes
    raycastParams.FilterDescendantsInstances = excludes
end

local function ensureDebugObjects()
    if not _debugFolder then
        _debugFolder = Instance.new("Folder")
        _debugFolder.Name = "AimAssistDebug"
        _debugFolder.Parent = workspace
    end
    if not _hitStamp then
        local p = Instance.new("Part")
        p.Name = "HitStamp"
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.4, 0.4, 0.4)
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(255, 85, 85)
        p.Transparency = 0.2
        p.Parent = _debugFolder
        _hitStamp = p
    end
    if not _radiusDisc then
        local c = Instance.new("Part")
        c.Name = "RadiusDisc"
        c.Shape = Enum.PartType.Cylinder
        c.Anchored = true
        c.CanCollide = false
        c.CastShadow = false
        c.Material = Enum.Material.ForceField
        c.Color = Color3.fromRGB(85, 170, 255)
        c.Transparency = 0.7
        c.Size = Vector3.new(1, DISC_THICKNESS, 1)
        c.Parent = _debugFolder
        _radiusDisc = c
    end
end

local function cframeAlignYAxis(pos: Vector3, yAxis: Vector3): CFrame
    local up = yAxis.Magnitude > 0 and yAxis.Unit or Vector3.yAxis
    local right = up:Cross(Vector3.yAxis)
    if right.Magnitude < 1e-3 then
        right = up:Cross(Vector3.xAxis)
    end
    right = right.Unit
    local back = right:Cross(up)
    return CFrame.fromMatrix(pos, right, up, back)
end

local function getHitFaceCenter(part: BasePart, worldNormal: Vector3): Vector3
    local cf = part.CFrame
    local size = part.Size
    local n = cf:VectorToObjectSpace(worldNormal)
    local ax, sign = "X", (n.X >= 0) and 1 or -1
    local axAbsX, axAbsY, axAbsZ = math.abs(n.X), math.abs(n.Y), math.abs(n.Z)
    if axAbsY >= axAbsX and axAbsY >= axAbsZ then
        ax = "Y"; sign = (n.Y >= 0) and 1 or -1
    elseif axAbsZ >= axAbsX and axAbsZ >= axAbsY then
        ax = "Z"; sign = (n.Z >= 0) and 1 or -1
    end
    local offset
    if ax == "X" then
        offset = Vector3.new(sign * size.X * 0.5, 0, 0)
    elseif ax == "Y" then
        offset = Vector3.new(0, sign * size.Y * 0.5, 0)
    else
        offset = Vector3.new(0, 0, sign * size.Z * 0.5)
    end
    return cf:PointToWorldSpace(offset)
end

local function hasTag(inst: Instance, tag: string): boolean
    return CollectionService:HasTag(inst, tag)
end

local function isBlock(part: BasePart): boolean
    return hasTag(part, TAG_BLOCK)
end

local function isPlayerHitbox(part: BasePart): boolean
    return hasTag(part, TAG_PLAYER_HITBOX)
end

local function getPlayerAimPointFromHitbox(hitbox: BasePart): Vector3
    local parent = hitbox.Parent
    if parent and parent:IsA("Model") then
        local pp = parent.PrimaryPart
        if pp then
            return pp.Position
        end
    end
    return hitbox.Position
end

function AimAssistController.aimSuggestion(cameraCFrame: CFrame): AimAssistSuggestion?
    local origin = cameraCFrame.Position
    local look = cameraCFrame.LookVector

    local result = workspace:Raycast(origin, look * MAX_RAY, raycastParams)
    if not result then
        if DEBUG and _hitStamp then
            _hitStamp.Transparency = 1
        end
        if DEBUG and _radiusDisc then
            _radiusDisc.Transparency = 1
        end
        return nil
    end

    local hitPos = result.Position
    local hitPart = result.Instance :: BasePart
    local distance = (hitPos - origin).Magnitude
    local radius = calculateRadiusSize(distance)

    if DEBUG then
        ensureDebugObjects()
        _hitStamp.Position = hitPos
        _hitStamp.Transparency = 0.2
        _radiusDisc.Size = Vector3.new(math.max(0.2, radius * 2), DISC_THICKNESS, math.max(0.2, radius * 2))
        _radiusDisc.CFrame = cframeAlignYAxis(hitPos, result.Normal)
        _radiusDisc.Transparency = 0.7
    end

    local candidates = workspace:GetPartBoundsInRadius(hitPos, radius, overlapsParams)
    if #candidates == 0 then
        return nil
    end

    local playerCandidates = {}
    local blockCandidates = {}

    for _, part in ipairs(candidates) do
        if part:IsA("BasePart") then
            if isPlayerHitbox(part) then
                table.insert(playerCandidates, part)
            elseif isBlock(part) then
                table.insert(blockCandidates, part)
            end
        end
    end

    local bestTargetPoint: Vector3? = nil
    local isPlayerTarget = false
    local bestAngle = math.huge

    if #playerCandidates > 0 then
        local prioritizedPlayer: BasePart? = nil
        for _, p in ipairs(playerCandidates) do
            if p == hitPart then
                prioritizedPlayer = p
                break
            end
        end

        if prioritizedPlayer then
            bestTargetPoint = getPlayerAimPointFromHitbox(prioritizedPlayer)
            isPlayerTarget = true
        else
            for _, p in ipairs(playerCandidates) do
                local aimPoint = getPlayerAimPointFromHitbox(p)
                local dir = (aimPoint - origin).Unit
                local cosTheta = math.clamp(look:Dot(dir), -1, 1)
                local theta = math.acos(cosTheta)
                if theta < bestAngle then
                    bestAngle = theta
                    bestTargetPoint = aimPoint
                    isPlayerTarget = true
                end
            end
        end
    else
        local prioritizedBlock: BasePart? = nil
        if isBlock(hitPart) then
            for _, p in ipairs(blockCandidates) do
                if p == hitPart then
                    prioritizedBlock = p
                    break
                end
            end
        end

        local chosenBlock: BasePart? = prioritizedBlock
        local bestDist = math.huge

        if not chosenBlock then
            for _, part in ipairs(blockCandidates) do
                local dirToPart = (part.Position - origin).Unit
                local dot = math.clamp(look:Dot(dirToPart), -1, 1)
                if dot >= math.cos(ASSIST_ANGLE) then
                    local d = (part.Position - hitPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        chosenBlock = part
                    end
                end
            end
        end

        if chosenBlock then
            if chosenBlock == hitPart then
                bestTargetPoint = getHitFaceCenter(chosenBlock, result.Normal)
            else
                bestTargetPoint = chosenBlock.Position
            end
        end
    end

    if not bestTargetPoint then
        return nil
    end

    local targetDir = (bestTargetPoint - origin).Unit
    local currentYaw, currentPitch = yawPitchFromDir(look)
    local targetYaw, targetPitch = yawPitchFromDir(targetDir)

    local deltaYaw = normalizeAngle(targetYaw - currentYaw)
    local deltaPitch = targetPitch - currentPitch

    local cosTheta = math.clamp(look:Dot(targetDir), -1, 1)
    local theta = math.acos(cosTheta)
    if theta > ASSIST_ANGLE then
        return nil
    end

    local strength = 1 - (theta / ASSIST_ANGLE)
    if isPlayerTarget then
        strength = math.clamp(strength * PLAYER_STRENGTH_MULT, 0, 1)
    end

    return {
        deltaYaw = deltaYaw,
        deltaPitch = deltaPitch,
        strength = strength
    }
end

function AimAssistController.init()
    refreshFilters()
    LocalPlayer.CharacterAdded:Connect(refreshFilters)
end

function AimAssistController.setDebug(enabled: boolean)
    DEBUG = enabled
    if not DEBUG then
        if _hitStamp then
            _hitStamp.Transparency = 1
        end
        if _radiusDisc then
            _radiusDisc.Transparency = 1
        end
    else
        ensureDebugObjects()
    end
end

return AimAssistController
