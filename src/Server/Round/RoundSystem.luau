local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerPool = require(ModuleDirectory.PlayerPool) -- holds the "reserve" players that are waiting for a game
local ActivePlayers = require(ModuleDirectory.ActivePlayers) -- holds the "active players currently in game"
local Timer = require(ModuleDirectory.Timer)
local RunService = game:GetService("RunService")

local activePlayerTable: ActivePlayers.ActivePlayers? = nil
-- setOnChange : (self: ActivePlayers, fn : (playerList : {Players}) -> ()) -> nil, <-- useful method calls given function on remove / add of active player.

local RoundSystem = {}

type RoundEvent = "INTERMISSION_TIMER_END"

local eventsQueue: { EventContext } = {}

export type RoundState = "STARTING" | "INTERMISSION" | "WAITING" | "ENDING" | "ACTIVE"

local state: RoundState = "INTERMISSION"

local processorBusy = false

export type Round = {
	alivePlayers: { Player },
	startTime: number,
	gamemode: string,
}

export type EventContext = {
	name: RoundEvent,
	timestamp: number,
	stateAtEnqueue: RoundState,
}

function RoundSystem.init()
	activePlayerTable = ActivePlayers.new()
	activePlayerTable:setOnChange(RoundSystem.onActivePoolChange)
	RunService.Stepped:Connect(RoundSystem.mainLoop)
end

-- callbacks that are called on state change and must be completed before next state change
-- these call backs may yield thread
local onStart: (Round) -> () = nil
local onEnd: (Round) -> () = nil
local onActive: (Round) -> () = nil
local onIntermission: (Round) -> () = nil

function RoundSystem.mainLoop(dt: number): nil
	if processorBusy then
		return
	end

	if #eventsQueue > 0 then
		processorBusy = true
		local eventToProcess: EventContext = eventsQueue[1]
		table.remove(eventsQueue, 1)
		RoundSystem.processEvent(eventToProcess) -- may yield
		processorBusy = false
	end
end

function RoundSystem.enqueue(newEvent: EventContext): nil
	table.insert(eventsQueue, newEvent)
end

function RoundSystem.processEvent(eventToProcess: EventContext): nil 

    if eventToProcess.stateAtEnqueue == "INTERMISSION" then
        
    elseif eventToProcess.stateAtEnqueue == "WAITING" then

    elseif eventToProcess.stateAtEnqueue == "ACTIVE" then

    elseif eventToProcess.stateAtEnqueue == "STARTING" then

    elseif eventToProcess.stateAtEnqueue == "ENDING" then
        warn("Unkown stateAtEnqueue: " .. eventToProcess.stateAtEnqueue)
    end

end

--Callbacks
function RoundSystem.onPlayerPoolChange(playersInPool : {Player}) 

end
    

function RoundSystem.onActivePoolChange(playersInActive : {Players}) 
end

-- Connection functions
function RoundSystem.connectStart(fn: (Round) -> ())
	onStart = fn
end

function RoundSystem.connectEnd(fn: (Round) -> ())
	onEnd = fn
end

function RoundSystem.connectActive(fn: (Round) -> ())
	onActive = fn
end

function RoundSystem.connectIntermission(fn: (Round) -> ())
	onIntermission = fn
end

return RoundSystem
