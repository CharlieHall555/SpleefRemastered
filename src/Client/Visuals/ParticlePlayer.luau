export type EmitterPlayer = {
    part: Part,
    emitter: ParticleEmitter,
    inUse: boolean,
    endTime: number
}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Config = require(ClientModuleDirectory.Config)
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local EmitterDefs = require(ClientModuleDirectory.EmitterDefs)

local ParticlePlayer = {}

local activePlayers: { EmitterPlayer } = {}
local idlePlayers: { EmitterPlayer } = {}
local queuedEmits: { { defName: string, position: Vector3, overrides: {}? } } = {}

local visible = true

local function applyEmitterDef(emitter: ParticleEmitter, def: {}): nil
    -- Core
    if def.Brightness ~= nil then emitter.Brightness = def.Brightness end
    if def.Color ~= nil then emitter.Color = def.Color end
    if def.LightEmission ~= nil then emitter.LightEmission = def.LightEmission end
    if def.LightInfluence ~= nil then emitter.LightInfluence = def.LightInfluence end
    if def.LockedToPart ~= nil then emitter.LockedToPart = def.LockedToPart end
    if def.TimeScale ~= nil then emitter.TimeScale = def.TimeScale end

    -- Lifetime & Rate
    if def.Lifetime ~= nil then emitter.Lifetime = def.Lifetime end
    if def.Rate ~= nil then emitter.Rate = def.Rate end
    if def.Speed ~= nil then emitter.Speed = def.Speed end
    if def.SpreadAngle ~= nil then emitter.SpreadAngle = def.SpreadAngle end

    -- Shape
    if def.EmissionDirection ~= nil then emitter.EmissionDirection = def.EmissionDirection end
    if def.Shape ~= nil then emitter.Shape = def.Shape end
    if def.ShapeInOut ~= nil then emitter.ShapeInOut = def.ShapeInOut end
    if def.ShapeStyle ~= nil then emitter.ShapeStyle = def.ShapeStyle end

    -- Size & Transparency
    if def.Size ~= nil then emitter.Size = def.Size end
    if def.Transparency ~= nil then emitter.Transparency = def.Transparency end

    -- Rotation & Movement
    if def.Rotation ~= nil then emitter.Rotation = def.Rotation end
    if def.RotSpeed ~= nil then emitter.RotSpeed = def.RotSpeed end
    if def.Drag ~= nil then emitter.Drag = def.Drag end
    if def.Acceleration ~= nil then emitter.Acceleration = def.Acceleration end

    -- Visual
    if def.Texture ~= nil then emitter.Texture = def.Texture end
    if def.ZOffset ~= nil then emitter.ZOffset = def.ZOffset end

    -- Enabled handled at play time
end

local function newPlayer(): EmitterPlayer
    local part = Instance.new("Part")
    part.Transparency = 1
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored = true
    part.CanCollide = false

    local emitter = Instance.new("ParticleEmitter")
    emitter.Enabled = false
    emitter.Rate = 0

    emitter.Parent = part

    return {
        part = part,
        emitter = emitter,
        inUse = false,
        endTime = 0
    }
end

local function getMaxLifetime(range: NumberRange?): number
    if not range then
        return 0
    end
    return math.max(range.Min, range.Max)
end

function ParticlePlayer.setVisible(value: boolean): nil
    visible = value
end

function ParticlePlayer.getVisible(): boolean
    return visible
end

function ParticlePlayer.init(): nil
    local count = Config.N_EMITTER_PLAYERS or Config.INITIAL_EMITTER_POOL or 16
    local perFrame = Config.EMITTERS_PER_FRAME or 50

    local made = 0
    for i = 1, count do
        table.insert(idlePlayers, newPlayer())
        made += 1
        if made >= perFrame then
            made = 0
            task.wait()
        end
    end

    RunService.Heartbeat:Connect(function(dt)
        -- Recycle finished players
        local now = time()
        for i = #activePlayers, 1, -1 do
            local p = activePlayers[i]
            if now >= p.endTime then
                p.emitter.Enabled = false
                p.part.Parent = nil
                p.inUse = false
                table.remove(activePlayers, i)
                table.insert(idlePlayers, p)
            end
        end

        -- Drain queue
        while #queuedEmits > 0 and #idlePlayers > 0 do
            local req = table.remove(queuedEmits, 1)
            ParticlePlayer.queueEmission(req.defName, req.position, req.overrides)
        end
    end)
end

function ParticlePlayer.queueEmission(defName: string, position: Vector3, amount: number, overrides: {}?): nil
    overrides = overrides or {}

    if #idlePlayers == 0 then
        table.insert(queuedEmits, { defName = defName, position = position, overrides = overrides, amount = amount })
        return
    end

    local def = EmitterDefs[defName]
    if not def then
        warn("Emitter def missing: " .. tostring(defName))
        return
    end

    local player = table.remove(idlePlayers, 1) :: EmitterPlayer
    player.inUse = true
    table.insert(activePlayers, player)

    -- Parent and position
    player.part.Parent = Workspace
    player.part.Position = position

    -- Configure emitter
    applyEmitterDef(player.emitter, def)
    if overrides then
        applyEmitterDef(player.emitter, overrides)
    end

    -- Determine lifetime for cleanup
    local lifetimeRange = overrides.Lifetime or def.Lifetime or player.emitter.Lifetime
    local maxLife = getMaxLifetime(lifetimeRange)
    local buffer = 0.1

    if visible then
        if amount and amount > 0 then
            -- Emit fixed number of particles
            player.emitter:Emit(amount)
            player.emitter.Enabled = false
        else
            -- Fallback: continuous emitter
            player.emitter.Enabled = true
        end
    end

    -- Track end time so the Heartbeat loop recycles the player
    player.endTime = time() + maxLife + buffer
end

return ParticlePlayer