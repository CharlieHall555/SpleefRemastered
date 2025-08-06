local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local ClientSideStateTracker = {}

export type ClientSideState = "IN_ROUND" | "ROUND_STARTING" | "INTERMISSION"

-- current client-side state
local state: ClientSideState = "INTERMISSION"

-- user-registered callbacks for each state
local transitions: {
    onIN_ROUND: (() -> ())?,
    onROUND_STARTING: (() -> ())?,
    onINTERMISSION: (() -> ())?,
} = {}

-- initialize tracker and listen for server state changes
function ClientSideStateTracker.init(): nil
    ClientSideStateTracker.changeState("INTERMISSION")
    RemoteEventHandler.newEventConnection("CHANGE_STATE", ClientSideStateTracker.receivedStateChange)
end

-- when server tells us to change state
function ClientSideStateTracker.receivedStateChange(newState: ClientSideState): nil
    if newState ~= state then
        ClientSideStateTracker.changeState(newState)
    end
end

-- update local state and fire any bound callbacks
function ClientSideStateTracker.changeState(newState: ClientSideState): nil
    if state == newState then 
        return 
    end
    print("STATECHANGE: " .. newState)
    state = newState
    local callback = transitions["on" .. newState]
    if callback then
        callback()
    end
end

function ClientSideStateTracker.getState(): ClientSideState
    return state
end

function ClientSideStateTracker.connectIntermission(fn: () -> ())
    transitions.onINTERMISSION = fn
end

function ClientSideStateTracker.connectRoundStarting(fn: () -> ())
    transitions.onROUND_STARTING = fn
end

function ClientSideStateTracker.connectInRound(fn: () -> ())
    transitions.onIN_ROUND = fn
end

return ClientSideStateTracker