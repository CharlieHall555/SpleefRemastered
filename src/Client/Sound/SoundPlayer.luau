export type SpatialSoundPlayer = {
    part: Part,
    sound: Sound,
    inUse: boolean
}

export type SoundOptions = {
    volume: number?,
    playbackSpeed: number?,
    looped: boolean?
}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Config = require(ClientModuleDirectory.Config)
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local SoundData = require(script.Parent.SoundData)

local SoundPlayer = {} :: any

local activePlayers: { SpatialSoundPlayer } = {}
local idlePlayers: { SpatialSoundPlayer } = {}
local queuedSounds: { { soundId: string, position: Vector3 } } = {}

-- non-spatial sound tracking
local playingSounds: { [number]: Sound } = {}
local counter = 0
local isMuted = false

-- cache of reusable non-spatial sounds by normalized id
type CacheBucket = { idle: { Sound }, active: { Sound } }
local soundCache: { [string]: CacheBucket } = {}
local endedHandlers: { [Sound]: RBXScriptConnection } = {}

-- toggle listeners
local _toggleListeners: { [number]: (enabled: boolean) -> nil } = {}
local _nextToggleUid = 1

local function getSoundEntry(soundKey: string): (string, SoundOptions)
    local entry = SoundData[soundKey]
    if not entry then
        warn("SoundPlayer: Sound key '" .. soundKey .. "' not found in SoundData")
        return "", {}
    end
    
    local id = entry.id
    if not id:match("^rbxassetid://") then
        id = "rbxassetid://" .. id
    end
    
    local defaultOptions: SoundOptions = {
        volume = entry.volume,
        playbackSpeed = entry.playbackSpeed,
        looped = entry.looped
    }
    
    return id, defaultOptions
end

local function fireToggle(enabled: boolean)
    local snapshot: { (enabled: boolean) -> nil } = {}
    for _, cb in pairs(_toggleListeners) do
        table.insert(snapshot, cb)
    end
    for _, cb in ipairs(snapshot) do
        cb(enabled)
    end
end

local function getBucket(id: string): CacheBucket
    local bucket = soundCache[id]
    if not bucket then
        bucket = { idle = {}, active = {} }
        soundCache[id] = bucket
    end
    return bucket
end

local function createCachedSound(id: string): Sound
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Parent = SoundService
    sound:SetAttribute("cacheId", id)
    endedHandlers[sound] = sound.Ended:Connect(function()
        local pid = sound:GetAttribute("playerId")
        if typeof(pid) == "number" then
            playingSounds[pid] = nil
        end
        local cacheId = sound:GetAttribute("cacheId")
        if typeof(cacheId) == "string" then
            local bucket = soundCache[cacheId]
            if bucket then
                -- move from active to idle
                for i, s in ipairs(bucket.active) do
                    if s == sound then
                        table.remove(bucket.active, i)
                        break
                    end
                end
                table.insert(bucket.idle, sound)
            end
        end
    end)
    return sound
end

local function acquireSound(id: string): Sound
    local bucket = getBucket(id)
    local sound: Sound
    if #bucket.idle > 0 then
        sound = table.remove(bucket.idle, 1)
    else
        sound = createCachedSound(id)
    end
    table.insert(bucket.active, sound)
    return sound
end

function SoundPlayer.setMuted(value: boolean): nil
    local wasEnabled = not isMuted
    isMuted = value

    if isMuted then
        for _, eachSound: Sound in playingSounds do
            eachSound:Stop()
        end
    end

    local isEnabled = not isMuted
    if wasEnabled ~= isEnabled then
        fireToggle(isEnabled)
    end
end

function SoundPlayer.getIsMuted(): boolean
    return isMuted
end

function SoundPlayer.init()
    for _ = 1, Config.N_SOUND_PLAYERS do
        local newPart = Instance.new("Part")
        newPart.Transparency = 1
        newPart.Size = Vector3.new(0.1, 0.1, 0.1)
        newPart.Anchored = true
        newPart.CanCollide = false

        local newSound = Instance.new("Sound")
        newSound.Parent = newPart
        newSound.RollOffMode = Enum.RollOffMode.Inverse
        newSound.EmitterSize = Config.SOUND_EMITTER_SIZE or 10
        newSound.MaxDistance = Config.SOUND_MAX_DISTANCE or 100

        local player: SpatialSoundPlayer = {
            part = newPart,
            sound = newSound,
            inUse = false
        }

        table.insert(idlePlayers, player)
    end

    RunService.Heartbeat:Connect(function()
        if #queuedSounds > 0 and #idlePlayers > 0 then
            local req = table.remove(queuedSounds, 1)
            SoundPlayer.queuePositionalSound(req.soundId, req.position)
        end
    end)
end

function SoundPlayer.queuePositionalSound(soundKey: string, position: Vector3, options: SoundOptions?): nil
    local soundId, defaultOptions = getSoundEntry(soundKey)
    if soundId == "" then return end
    
    options = options or {}
    if #idlePlayers == 0 then
        table.insert(queuedSounds, { soundId = soundKey, position = position })
        return
    end

    local player: SpatialSoundPlayer = table.remove(idlePlayers, 1)
    player.inUse = true
    table.insert(activePlayers, player)

    player.part.Parent = Workspace
    player.part.Position = position

    player.sound.Volume = options.volume or defaultOptions.volume or 0.5
    player.sound.PlaybackSpeed = options.playbackSpeed or defaultOptions.playbackSpeed or 1
    player.sound.SoundId = soundId

    if not isMuted then
        player.sound:Play()
    end

    player.sound.Ended:Connect(function()
        for idx, p in ipairs(activePlayers) do
            if p == player then
                table.remove(activePlayers, idx)
                break
            end
        end
        player.part.Parent = nil
        player.inUse = false
        table.insert(idlePlayers, player)
    end)
end

function SoundPlayer.endSound(playerId: number): nil
    local sound = playingSounds[playerId]
    if sound then
        sound:Stop()
    end
end

function  SoundPlayer.playSound(soundKey: string, options: SoundOptions?): Sound
    local soundId, defaultOptions = getSoundEntry(soundKey)
    if soundId == "" then
        -- return a dummy sound to avoid errors
        local dummy = Instance.new("Sound")
        dummy.Parent = SoundService
        return dummy
    end
    
    options = options or {}

    local sound = acquireSound(soundId)

    sound.Volume = options.volume or defaultOptions.volume or 0.5
    sound.Looped = options.looped or defaultOptions.looped or false
    sound.PlaybackSpeed = options.playbackSpeed or defaultOptions.playbackSpeed or 1

    sound:SetAttribute("playerId", counter)
    playingSounds[counter] = sound
    counter += 1

    if not isMuted then
        sound:Play()
    end

    return sound
end

function SoundPlayer.connectOnToggle(callback: (enabled: boolean) -> nil): number
    local uid = _nextToggleUid
    _nextToggleUid += 1
    _toggleListeners[uid] = callback
    return uid
end

function SoundPlayer.disconnectOnToggle(uid: number): nil
    _toggleListeners[uid] = nil
end

return SoundPlayer

--[[ Suggestions:
- Consider adding a max pool size per sound id in Config to cap memory if many variants are played.
- If you need per-play 3D effects (e.g., equalizer), reset those on acquisition to avoid state carry-over.
]]
