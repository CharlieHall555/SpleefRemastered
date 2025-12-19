local RoundSystem = {}

type RoundEvent =
    "INTERMISSION_TIMER_ENDED"
    | "ROUND_TIMER_ENDED"
    | "PLAYER_POOL_CHANGED"
    | "ACTIVE_POOL_CHANGED"
    | "STARTUP_COMPLETE"
    | "END_COMPLETE"
    | "PREPARING_TIMER_ENDED"

export type RoundState = "STARTING" | "PREPARING" | "INTERMISSION" | "WAITING" | "ENDING" | "ACTIVE"

export type Round = {
    startingPlayers: { Player },
    startTime: number,
    gamemode: string,
}

export type EventContext = {
    name: RoundEvent,
    timestamp: number,
    stateAtEnqueue: RoundState,
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerPool = require(ModuleDirectory.Systems.Round.PlayerPool)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local Timer = require(ModuleDirectory.Timer)
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local eventsQueue: { EventContext } = {}
local processorBusy = false

local intermissionTimer, roundTimer, preparingTimer

local state: RoundState = "INTERMISSION"
local currentRound: Round? = nil

local function buildEventContext(name: RoundEvent): EventContext
    return {
        name = name,
        timestamp = time(),
        stateAtEnqueue = state,
    }
end

local transitions = {
    onSTARTING = nil :: ((Round) -> ())?,
    onPREPARING = nil :: ((Round) -> ())?,
    onENDING = nil :: ((Round) -> ())?,
    onACTIVE = nil :: ((Round) -> ())?,
    onINTERMISSION = nil :: ((Round) -> ())?,
}

function RoundSystem.init()
    PlayerPool.setOnChange(RoundSystem.onPlayerPoolChange)
    PlayersInGame.setOnChange(RoundSystem.onActivePoolChange)
    RunService.Stepped:Connect(RoundSystem.mainLoop)

    intermissionTimer = Timer.new()
    intermissionTimer.EndCallback = function()
        RoundSystem.queueEvent(buildEventContext("INTERMISSION_TIMER_ENDED"))
    end

    roundTimer = Timer.new()
    roundTimer.EndCallback = function()
        RoundSystem.queueEvent(buildEventContext("ROUND_TIMER_ENDED"))
    end

    preparingTimer = Timer.new()
    preparingTimer.EndCallback = function()
        RoundSystem.queueEvent(buildEventContext("PREPARING_TIMER_ENDED"))
    end

    roundTimer.StepCallback = function(time: number)
        --RemoteEventHandler.FireOnAllClients("ROUND_TIMER_CHANGED" , time)
    end

    intermissionTimer.StepCallback = function(time: number)
        RemoteEventHandler.FireOnAllClients("INTERMISSION_TIMER_CHANGED", time)
    end

    -- Optional: expose preparing countdown to clients if used
    preparingTimer.StepCallback = function(time: number)
        RemoteEventHandler.FireOnAllClients("PREPARING_TIMER_CHANGED", time)
    end

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
        RemoteEventHandler.FireOnClient(player, "SEND_SERVER_STATE", state)
    end)
end

function RoundSystem.mainLoop(dt: number): nil
    if processorBusy then
        return
    end
    if #eventsQueue > 0 then
        processorBusy = true
        local eventToProcess = table.remove(eventsQueue, 1)
        RoundSystem.processEvent(eventToProcess)
        processorBusy = false
    end
end

function RoundSystem.queueEvent(newEvent: EventContext): nil
    table.insert(eventsQueue, newEvent)
end

function RoundSystem.processEvent(eventToProcess: EventContext): nil
    if state == "INTERMISSION" then
        if eventToProcess.name == "INTERMISSION_TIMER_ENDED" then
            if #PlayerPool.getActivePool() >= Config.REQUIRED_PLAYERS then
                RoundSystem.changeState("STARTING")
            else
                RoundSystem.changeState("WAITING")
            end
        end
    elseif state == "WAITING" then
        if eventToProcess.name == "PLAYER_POOL_CHANGED" then
            if #PlayerPool.getActivePool() >= Config.REQUIRED_PLAYERS then
                RoundSystem.changeState("STARTING")
            end
        end
    elseif state == "STARTING" then
        if eventToProcess.name == "STARTUP_COMPLETE" then
            if #PlayersInGame.getActivePlayers() >= Config.REQUIRED_PLAYERS then
                RoundSystem.changeState("PREPARING")
            else
                RoundSystem.changeState("ENDING")
            end
        end
    elseif state == "PREPARING" then
        if eventToProcess.name == "PREPARING_TIMER_ENDED" then
			RoundSystem.changeState("ACTIVE")
        elseif eventToProcess.name == "ACTIVE_POOL_CHANGED" then
            if #PlayersInGame.getActivePlayers() <= Config.PLAYERS_TO_END then
                RoundSystem.changeState("ENDING")
            end
        end
    elseif state == "ACTIVE" then
        if eventToProcess.name == "ROUND_TIMER_ENDED" then
            RoundSystem.changeState("ENDING")
        elseif eventToProcess.name == "ACTIVE_POOL_CHANGED" then
            if #PlayersInGame.getActivePlayers() <= Config.PLAYERS_TO_END then
                RoundSystem.changeState("ENDING")
            end
        end
    elseif state == "ENDING" then
        if eventToProcess.name == "END_COMPLETE" then
            RoundSystem.changeState("INTERMISSION")
        end
    else
        warn("Unknown state at enqueue: " .. eventToProcess.stateAtEnqueue)
    end
end

function RoundSystem.onINTERMISSION()
    intermissionTimer:Start(Config.INTERMISSION_TIME)
end

function RoundSystem.onSTARTING()
    currentRound = {
        startingPlayers = table.clone(PlayerPool.getActivePool()),
        startTime = os.clock(),
        gamemode = "Spleef",
    }
    for _, player in ipairs(PlayerPool.getActivePool()) do
        PlayersInGame.addPlayer(player , false)
    end

    RemoteEventHandler.FireOnAllClients(
        "PLAYERS_IN_GAME_CHANGED",
        #PlayersInGame.getActivePlayers(),
        #currentRound.startingPlayers
    )

end

function RoundSystem.onPREPARING()
    local prepTime = (Config.PREPARING_TIME) or 0
    if prepTime > 0 then
        preparingTimer:Start(prepTime)
    else
        RoundSystem.queueEvent(buildEventContext("PREPARING_TIMER_ENDED"))
    end
end

function RoundSystem.onACTIVE()
    roundTimer:Start(Config.MAXIMUM_ROUND_TIME)
    RemoteEventHandler.FireOnAllClients("ROUND_TIMER_STARTED" , Config.MAXIMUM_ROUND_TIME)

end

function RoundSystem.onENDING()
    -- no-op by default
end

function RoundSystem.getCurrentRound(): Round?
    return currentRound
end

function RoundSystem.changeState(newState: RoundState): nil
    state = newState
    RemoteEventHandler.FireOnAllClients("SEND_SERVER_STATE", state)
    print("new-state: " .. state)

    local handler = RoundSystem["on" .. newState]
    local callback = transitions["on" .. newState]

    if handler then
        handler()
    end

    if callback and currentRound then
        callback(currentRound)
    end

    if newState == "ENDING" then
        PlayersInGame.clear()
        RoundSystem.queueEvent(buildEventContext("END_COMPLETE"))
    elseif newState == "STARTING" then
        RoundSystem.queueEvent(buildEventContext("STARTUP_COMPLETE"))
    end
end

function RoundSystem.onPlayerPoolChange(playersInPool: { Player })
    RoundSystem.queueEvent(buildEventContext("PLAYER_POOL_CHANGED"))
end

function RoundSystem.onActivePoolChange(playersInActive: { Player })
    RoundSystem.queueEvent(buildEventContext("ACTIVE_POOL_CHANGED"))

    RemoteEventHandler.FireOnAllClients("PLAYERS_IN_GAME_CHANGED" , #playersInActive , #currentRound.startingPlayers)
end

function RoundSystem.connectStarting(fn: (Round) -> ())
    transitions.onSTARTING = fn
end

function RoundSystem.connectPreparing(fn: (Round) -> ())
    transitions.onPREPARING = fn
end

function RoundSystem.connectEnding(fn: (Round) -> ())
    transitions.onENDING = fn
end

function RoundSystem.connectActive(fn: (Round) -> ())
    transitions.onACTIVE = fn
end

function RoundSystem.connectIntermission(fn: (Round) -> ())
    transitions.onINTERMISSION = fn
end


function RoundSystem.main()
    RoundSystem.changeState("INTERMISSION")
end

function RoundSystem.getState(): RoundState
    return state
end

return RoundSystem
