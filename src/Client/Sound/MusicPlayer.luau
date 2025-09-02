local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local MusicPlayer = {}

local tracks = { "rbxassetid://139648518979670", "rbxassetid://114323832093188" , "rbxassetid://93649998031408" }
local trackNumber = math.random(1 , #tracks)
local soundPlayer: Sound? = nil
local enabled = true
local _endedConn: RBXScriptConnection? = nil

local _toggleListeners: { [number]: (enabled: boolean) -> nil } = {}
local _nextToggleUid = 1

local lastVolume = 0.25

local function fireToggle(enabledNow: boolean)
    local snapshot: { (boolean) -> nil } = {}
    for _, cb in pairs(_toggleListeners) do
        table.insert(snapshot, cb)
    end
    for _, cb in ipairs(snapshot) do
        cb(enabledNow)
    end
end

local function ensureSound(): Sound
    if not soundPlayer or soundPlayer.Parent == nil then
        soundPlayer = Instance.new("Sound")
        soundPlayer.Name = "MusicPlayerSound"
        soundPlayer.Looped = false
        soundPlayer.Volume = enabled and lastVolume or 0
        soundPlayer.RollOffMaxDistance = 100000
        soundPlayer.RollOffMode = Enum.RollOffMode.InverseTapered
        soundPlayer.Parent = SoundService

        if _endedConn then
            _endedConn:Disconnect()
            _endedConn = nil
        end
        _endedConn = soundPlayer.Ended:Connect(function()
            -- Always advance so muted playback continues progressing
            MusicPlayer.nextTrack()
        end)
    end
    return soundPlayer
end

local function playCurrent()
    local snd = ensureSound()
    if #tracks == 0 then
        snd:Stop()
        return
    end
    if trackNumber < 1 or trackNumber > #tracks then
        trackNumber = 1
    end
    snd.SoundId = tracks[trackNumber]
    snd.Volume = enabled and lastVolume or 0
    snd.TimePosition = 0
    snd:Play()
end

function MusicPlayer.init()
    ensureSound()
    playCurrent()
    if RunService:IsStudio() then
        MusicPlayer.disable()
    end
end

function MusicPlayer.enable()
    if enabled then
        return
    end
    enabled = true
    local snd = ensureSound()
    -- Resume at current position with previous volume
    snd.Volume = lastVolume
    if not snd.IsPlaying then
        snd:Play()
    end
    fireToggle(true)
end

function MusicPlayer.disable()
    if not enabled then
        return
    end
    enabled = false
    local snd = ensureSound()
    -- Keep playing but mute to 0 volume
    lastVolume = snd.Volume
    snd.Volume = 0
    if not snd.IsPlaying then
        snd:Play()
    end
    fireToggle(false)
end

function MusicPlayer.setVolume(newVolume: number)
    local snd = ensureSound()
    if typeof(newVolume) == "number" then
        if newVolume < 0 then
            newVolume = 0
        elseif newVolume > 10 then
            newVolume = 10
        end
        lastVolume = newVolume
        if enabled then
            snd.Volume = newVolume
        end
    end
end

function MusicPlayer.nextTrack()
    if #tracks == 0 then
        return
    end
    trackNumber += 1
    if trackNumber > #tracks then
        trackNumber = 1
    end
    playCurrent()
end

function MusicPlayer.previousTrack()
    if #tracks == 0 then
        return
    end
    trackNumber -= 1
    if trackNumber < 1 then
        trackNumber = #tracks
    end
    playCurrent()
end

function MusicPlayer.isEnabled()
    return enabled
end

function MusicPlayer.connectOnToggle(callback: (enabled: boolean) -> nil): number
    local uid = _nextToggleUid
    _nextToggleUid += 1
    _toggleListeners[uid] = callback
    return uid
end

function MusicPlayer.disconnectOnToggle(uid: number)
    _toggleListeners[uid] = nil
end

return MusicPlayer
