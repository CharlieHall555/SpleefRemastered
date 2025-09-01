-- UserProfile.lua
-- Client-side profile cache with queued updates & filtered callbacks.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

export type CallbackFn = (valueName: string, newValue: any) -> nil
export type CallbackRec = { id: number, fn: CallbackFn, filter: string? }
export type QueueItem = { name: string, value: any }

export type UserProfile = {
    data: { [string]: any },
    loadProfile: () -> (),
    onProfileLoaded: () -> (),
    receiveFromServer: (valueName: string, newValue: any, json: boolean?) -> (),
    getValue: (valueName: string) -> any,
    setOnUpdateCallback: (callback: CallbackFn, valueNameFilter: string?) -> number,
    disconnectOnUpdateCallback: (id: number) -> (),
}

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local UserProfile: UserProfile = {} :: any
UserProfile.__index = UserProfile

-- public data bag
UserProfile.data = {} :: { [string]: any }

-- internals
local _didInit = false
local _heartbeatConn: RBXScriptConnection? = nil
local _profileEventId: string? = nil

-- O(1) queue with head/tail indices (never use # on a sparse array)
local _queue: { QueueItem? } = {}
local _qHead = 1
local _qTail = 0

local _callbacks: { [number]: CallbackRec } = {}
local _nextId = 0

-- ==== internals ====

local function _push(name: string, value: any)
    _qTail += 1
    _queue[_qTail] = { name = name, value = value }
end

local function _pop(): QueueItem?
    if _qHead <= _qTail then
        local item = _queue[_qHead]
        _queue[_qHead] = nil
        _qHead += 1
        -- occasional compaction to keep memory tidy
        if _qHead > 64 and _qHead > (_qTail - _qHead) then
            _queue = {}
            _qHead = 1
            _qTail = 0
        end
        return item
    end
    return nil
end

local function _decodeJsonSafely(payload: string): (boolean, any)
    return pcall(function()
        return HttpService:JSONDecode(payload)
    end)
end

local function _dispatch(name: string, value: any)
    for _, rec in pairs(_callbacks) do
        if rec and (rec.filter == nil or rec.filter == name) then
            local ok, err = pcall(rec.fn, name, value)
            if not ok then
                warn("[UserProfile] callback error for '", name, "': ", err)
            end
        end
    end
end

local function _beginHeartbeat()
    if _heartbeatConn then return end
    _heartbeatConn = RunService.Stepped:Connect(function()
        -- Drain the queue on the main thread
        while true do
            local item = _pop()
            if not item then break end
            UserProfile.data[item.name] = item.value
            _dispatch(item.name, item.value)
        end
    end)
end

local function _endHeartbeat()
    if _heartbeatConn then
        _heartbeatConn:Disconnect()
        _heartbeatConn = nil
    end
end

local function initialSetup(profileDataJson: string)
    local ok, decoded = _decodeJsonSafely(profileDataJson)
    if not ok then
        warn("[UserProfile] Failed to decode initial profile data; got string instead.")
        return
    end
    for k, v in decoded do
        UserProfile.data[k] = v
    end
end

-- ==== public API ====

function UserProfile.loadProfile()
    -- Example extra arg "2" retained to match existing server signature.
    local profileData = RemoteEventHandler.InvokeOnServer("QUERY_PROFILE_DATA", 2)
    if typeof(profileData) == "string" and #profileData > 0 then
        initialSetup(profileData)
    elseif profileData ~= nil then
        if typeof(profileData) == "table" then
            for k, v in profileData do
                UserProfile.data[k] = v
            end
        else
            warn("[UserProfile] Unexpected profileData type: ", typeof(profileData))
        end
    end
end

function UserProfile.onProfileLoaded()
    if _didInit then return end
    _didInit = true

    _beginHeartbeat()

    -- Listen for server-side updates
    _profileEventId = RemoteEventHandler.newEventConnection("PROFILE_UPDATE", function(valueName: string, newValue: any, json: boolean?)
        UserProfile.receiveFromServer(valueName, newValue, json)
    end)
end

function UserProfile.receiveFromServer(valueName: string, newValue: any, json: boolean?)
    if typeof(valueName) ~= "string" or valueName == "" then
        warn("[UserProfile] receiveFromServer called with invalid valueName")
        return
    end

    local value = newValue
    if json == true and typeof(newValue) == "string" then
        local ok, decoded = _decodeJsonSafely(newValue)
        if ok then
            value = decoded
        else
            warn("[UserProfile] JSON decode failed for key '", valueName, "'; storing raw string.")
        end
    end

    _push(valueName, value)
end

function UserProfile.getValue(valueName: string): any
    return UserProfile.data[valueName]
end

function UserProfile.setOnUpdateCallback(callback: CallbackFn, valueNameFilter: string?): number
    _nextId += 1
    _callbacks[_nextId] = { id = _nextId, fn = callback, filter = valueNameFilter }
    return _nextId
end

function UserProfile.disconnectOnUpdateCallback(id: number)
    _callbacks[id] = nil
end

return UserProfile
