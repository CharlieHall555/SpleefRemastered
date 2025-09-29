-- UserSessionVaraibles.lua
-- Client-side session variable cache with queued updates & filtered callbacks.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

export type CallbackFn = (valueName: string, newValue: any) -> ()
export type CallbackRec = { id: number, fn: CallbackFn, filter: string? }
export type QueueItem = { name: string, value: any }


local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local UserSessionVariables = {} :: any
UserSessionVariables.__index = UserSessionVariables

-- public data bag
UserSessionVariables.data = {} :: { [string]: any }

-- internals
local _didInit = false
local _heartbeatConn: RBXScriptConnection? = nil
local _sessionEventId: string? = nil

-- O(1) queue with head/tail indices
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
                warn("[UserSessionVaraibles] callback error for '", name, "': ", err)
            end
        end
    end
end

local function _beginHeartbeat()
    if _heartbeatConn then return end
    _heartbeatConn = RunService.Stepped:Connect(function()
        while true do
            local item = _pop()
            if not item then break end
            UserSessionVariables.data[item.name] = item.value
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

-- ==== public API ====

function UserSessionVariables.init()
    if _didInit then return end
    _didInit = true

    _beginHeartbeat()

    _sessionEventId = RemoteEventHandler.newEventConnection("SESSION_VARIABLE_UPDATED", function(valueName: string, newValue: any, json: boolean?)
        UserSessionVariables.receiveFromServer(valueName, newValue, json)
    end)
end

function UserSessionVariables.receiveFromServer(valueName: string, newValue: any, json: boolean?)
    if typeof(valueName) ~= "string" or valueName == "" then
        warn("[UserSessionVaraibles] receiveFromServer called with invalid valueName")
        return
    end

    local value = newValue
    if json == true and typeof(newValue) == "string" then
        local ok, decoded = _decodeJsonSafely(newValue)
        if ok then
            value = decoded
        else
            warn("[UserSessionVaraibles] JSON decode failed for key '", valueName, "'; storing raw string.")
        end
    end

    _push(valueName, value)
end

function UserSessionVariables.getValue(valueName: string): any
    return UserSessionVariables.data[valueName]
end

function UserSessionVariables.setOnUpdateCallback(callback: CallbackFn, valueNameFilter: string?): number
    _nextId += 1
    _callbacks[_nextId] = { id = _nextId, fn = callback, filter = valueNameFilter }
    return _nextId
end

function UserSessionVariables.disconnectOnUpdateCallback(id: number)
    _callbacks[id] = nil
end

return UserSessionVariables
