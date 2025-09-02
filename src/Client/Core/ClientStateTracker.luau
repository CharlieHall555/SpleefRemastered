local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local ClientStateTracker = {}

local state: "ACTIVE" | "ROUND_STARTING" | "INTERMISSION" = "INTERMISSION"
local serverState: string?

local isSuddenDeath = false

-- callbacks stored per-state by uid
local _transitions = {
	ACTIVE = {} :: { [string]: () -> () },
	ROUND_STARTING = {} :: { [string]: () -> () },
	INTERMISSION = {} :: { [string]: () -> () },
}

-- server-state change callbacks (receive new serverState)
local _serverStateTransitions = {} :: { [string]: (newState : string) -> () }

-- uid -> bucket key for quick disconnect; bucket is one of the keys in _transitions or "SERVER_STATE"
local _uidToBucket: { [string]: string } = {}

local _nextId = 0
local function _newUID(): string
	_nextId += 1
	return "cs" .. tostring(_nextId)
end

local function _connect(stateName: "ACTIVE" | "ROUND_STARTING" | "INTERMISSION", fn: () -> ()): string
	assert(typeof(fn) == "function", "Callback must be a function")
	local uid = _newUID()
	_transitions[stateName][uid] = fn
	_uidToBucket[uid] = stateName
	return uid
end

local function _connectServer(fn: (newState : string) -> ()): string
	assert(typeof(fn) == "function", "Callback must be a function")
	local uid = _newUID()
	_serverStateTransitions[uid] = fn
	_uidToBucket[uid] = "SERVER_STATE"
	return uid
end

function ClientStateTracker.init(): nil
	ClientStateTracker.changeState("INTERMISSION")
	RemoteEventHandler.newEventConnection("CHANGE_STATE", ClientStateTracker.receivedStateChange)
	RemoteEventHandler.newEventConnection("SEND_SERVER_STATE", ClientStateTracker.setServerState)

	local gotState = RemoteEventHandler.InvokeOnServer("QUERY_SERVER_STATE" , 2)
	if gotState and serverState == nil then
		ClientStateTracker.setServerState(gotState)
	end

	RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH" , function()
		isSuddenDeath = true
	end)

end

function ClientStateTracker.receivedStateChange(newState: "ACTIVE" | "ROUND_STARTING" | "INTERMISSION"): nil
	if newState ~= state then
		ClientStateTracker.changeState(newState)
	end
	
end

function ClientStateTracker.getSuddenDeath() : boolean
	return isSuddenDeath
end

function ClientStateTracker.changeState(newState: "ACTIVE" | "ROUND_STARTING" | "INTERMISSION"): nil
	if state == newState then
		return
	end

	print("STATECHANGE: " .. newState)
	state = newState

	local bucket = _transitions[newState] or {}
	for _, callback in bucket do
		local ok, err = pcall(callback)
		if not ok then
			warn(("ClientStateTracker callback error (%s): %s"):format(newState, tostring(err)))
		end
	end
end

function ClientStateTracker.getState(): "ACTIVE" | "ROUND_STARTING" | "INTERMISSION"
	return state
end

function ClientStateTracker.getServerState(): string?
	return serverState
end

function ClientStateTracker.setServerState(newServerState: string): nil
	serverState = newServerState
	if newServerState == "PREPARING" then
		isSuddenDeath = false
	end
	print("SERVER STATECHANGE: " .. serverState)
	for _, callback in _serverStateTransitions do
		local ok, err = pcall(callback, newServerState)
		if not ok then
			warn(("ClientStateTracker server-state callback error: %s"):format(tostring(err)))
		end
	end
end

-- Connection helpers (return a uid you can later pass to disconnect)
function ClientStateTracker.connectIntermission(fn: () -> ()): string
	return _connect("INTERMISSION", fn)
end

function ClientStateTracker.connectRoundStarting(fn: () -> ()): string
	return _connect("ROUND_STARTING", fn)
end

function ClientStateTracker.connectActive(fn: () -> ()): string
	return _connect("ACTIVE", fn)
end

function ClientStateTracker.connectServerStateChange(fn: (newState : string) -> ()): string
	return _connectServer(fn)
end

function ClientStateTracker.disconnect(uid: string): boolean
	local bucket = _uidToBucket[uid]
	if not bucket then
		return false
	end

	if bucket == "SERVER_STATE" then
		_serverStateTransitions[uid] = nil
	else
		_transitions[bucket][uid] = nil
	end

	_uidToBucket[uid] = nil
	return true
end

return ClientStateTracker
