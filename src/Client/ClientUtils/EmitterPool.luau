local RunService = game:GetService("RunService")
local root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(root.ClientModuleDirectory)
local Config = require(ClientModuleDirectory.Config)

local EmitterPool = {}

local emitterDump: { ParticleEmitter } = {}

local function createEmitter(): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Enabled = false 
    emitter.Rate = 0 
    emitter.LightInfluence = 0
    emitter.LockedToPart = false
    emitter.FastForward(0)
    return emitter
end

function EmitterPool.init(): nil
    task.spawn(function()
        EmitterPool.startUp(Config.INITIAL_EMITTER_POOL or 0)
    end)
end

function EmitterPool.startUp(initial: number): nil
    local perFrame = Config.EMITTERS_PER_FRAME or 50
    local count = 0
    for i = 1, initial do
        count += 1
        table.insert(emitterDump, createEmitter())
        if count >= perFrame then
            count = 0
            task.wait()
        end
    end
    print("Emitter Pool Initialised.")
end

function EmitterPool.conform(emitter: ParticleEmitter, definition: {}): ParticleEmitter
    if not emitter or not definition then
        return emitter
    end

    -- Prevent mid-update emission flicker
    local wasEnabled = emitter.Enabled
    emitter.Enabled = false

    -- Core
    if definition.Brightness ~= nil then emitter.Brightness = definition.Brightness end
    if definition.Color ~= nil then emitter.Color = definition.Color end
    if definition.LightEmission ~= nil then emitter.LightEmission = definition.LightEmission end
    if definition.LightInfluence ~= nil then emitter.LightInfluence = definition.LightInfluence end
    if definition.LockedToPart ~= nil then emitter.LockedToPart = definition.LockedToPart end

    -- Lifetime & Rate
    if definition.Lifetime ~= nil then emitter.Lifetime = definition.Lifetime end
    if definition.Rate ~= nil then emitter.Rate = definition.Rate end
    if definition.Speed ~= nil then emitter.Speed = definition.Speed end
    if definition.SpreadAngle ~= nil then emitter.SpreadAngle = definition.SpreadAngle end

    -- Shape
    if definition.EmissionDirection ~= nil then emitter.EmissionDirection = definition.EmissionDirection end
    if definition.Shape ~= nil then emitter.Shape = definition.Shape end
    if definition.ShapeInOut ~= nil then emitter.ShapeInOut = definition.ShapeInOut end
    if definition.ShapeStyle ~= nil then emitter.ShapeStyle = definition.ShapeStyle end

    -- Size & Transparency
    if definition.Size ~= nil then emitter.Size = definition.Size end
    if definition.Transparency ~= nil then emitter.Transparency = definition.Transparency end

    -- Rotation & Movement
    if definition.Rotation ~= nil then emitter.Rotation = definition.Rotation end
    if definition.RotSpeed ~= nil then emitter.RotSpeed = definition.RotSpeed end
    if definition.Drag ~= nil then emitter.Drag = definition.Drag end
    if definition.Acceleration ~= nil then emitter.Acceleration = definition.Acceleration end

    -- Visual
    if definition.Texture ~= nil then emitter.Texture = definition.Texture end
    if definition.ZOffset ~= nil then emitter.ZOffset = definition.ZOffset end

    -- Timing
    if definition.TimeScale ~= nil then emitter.TimeScale = definition.TimeScale end

    -- Enabled last (use definition if provided, else restore prior state)
    if definition.Enabled ~= nil then
        emitter.Enabled = definition.Enabled
    else
        emitter.Enabled = wasEnabled
    end

    return emitter
end

-- Removes an emitter from the pool and returns it.
function EmitterPool.take(): ParticleEmitter?
    local emitter = emitterDump[1]
    if emitter == nil then
        return nil
    end
    table.remove(emitterDump, 1)
    return emitter
end

-- Returns an emitter back to the pool. Caller should detach and reset as needed.
function EmitterPool.add(emitter: ParticleEmitter): nil
    if emitter == nil then
        return
    end
    emitter.Enabled = false
    emitter.Parent = nil
    table.insert(emitterDump, emitter)
end

return EmitterPool