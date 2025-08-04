local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PartPool = require(ClientModuleDirectory.PartPool)

-- useful methods PartPool.add(part : Part), PartPool.take() -> Part

local ClientThrowableTracker = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {workspace:WaitForChild("Blocks")}
rayParams.IgnoreWater = true

local GRAVITY = Vector3.new(0, -15, 0)

export type Throwable = {
    position: Vector3,
    direction: Vector3,
    velocity: Vector3,
    part: Part,
}

local listThrowable: {Throwable} = {}

function ClientThrowableTracker.init()
    RunService.RenderStepped:Connect(ClientThrowableTracker.mainLoop)
end

function ClientThrowableTracker.mainLoop(deltaTime: number): nil
    for i = #listThrowable, 1, -1 do
        local throwable = listThrowable[i]
        local part = throwable.part

        local oldPosition = throwable.position
        local newVelocity = throwable.velocity + GRAVITY * deltaTime
        local newPosition = oldPosition + newVelocity * deltaTime

        local result = workspace:Raycast(oldPosition, newPosition - oldPosition, rayParams)

        if result then
            -- simple collision response: remove from simulation
            PartPool.add(part)
            part.Transparency = 1
            table.remove(listThrowable, i)
            print("destroy")
        else
            throwable.velocity = newVelocity
            throwable.position = newPosition
            part.Position = newPosition
        end
    end
end

function ClientThrowableTracker.newThrowable(startPosition: Vector3, direction: Vector3)
    local part = PartPool.take()
    if not part then part = Instance.new("Part") end

    part.Size = Vector3.new(1 , 1 , 1)
    part.Position = startPosition
    part.Velocity = Vector3.zero
    part.Color = Color3.fromRGB(255,255,255)
    part.Anchored = true
    part.CanCollide = false
    part.Shape = Enum.PartType.Ball
    part.Transparency = 0
    part.Parent = workspace

    local speed = 80
    local velocity = direction.Unit * speed

    local throwable: Throwable = {
        position = startPosition,
        direction = direction,
        velocity = velocity,
        part = part
    }

    table.insert(listThrowable, throwable)
end

return ClientThrowableTracker