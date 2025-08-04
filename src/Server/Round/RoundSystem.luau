local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerPool = require(ModuleDirectory.PlayerPool) -- holds the "reserve" players that are waiting for a game
local PlayersInGame = require(ModuleDirectory.PlayersInGame) -- holds the "active players currently in game"
local Timer = require(ModuleDirectory.Timer)
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

-- useful configs
--Config.ROUND_TIME , Config.REQUIRED_PLAYERS , Config.INTERMISSION_TIME

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

local intermissionTimer , roundTimer


local function buildEventContext(name : RoundEvent)
	return {
		name = name,
		timestamp = time(),
		stateAtEnqueue = state,
	}
end

function RoundSystem.init()
	PlayerPool.setOnChange(RoundSystem.onPlayerPoolChange)
	PlayersInGame.setOnChange(RoundSystem.onActivePoolChange)
	RunService.Stepped:Connect(RoundSystem.mainLoop)

	intermissionTimer = Timer.new(function()
		RoundSystem.queueEvent(buildEventContext("INTERMISSION_TIMER_ENDED"))
	end)

	roundTimer = Timer.new(function()
		RoundSystem.queueEvent(buildEventContext("ROUND_TIMER_ENDED"))
	end)

end

local currentRound : Round?


-- callbacks that are called on state change and must be completed before next state change
-- these call backs may yield thread
local transitions : {
 onSTARTING : (Round) -> (),
 onENDING : (Round) -> (),
 onACTIVE : (Round) -> (),
 onINTERMISSION : (Round) -> (),
} = {}
transitions.onSTARTING = nil
transitions.onENDING = nil
transitions.onACTIVE = nil
transitions.onINTERMISSION = nil



function RoundSystem.mainLoop(dt: number): nil
	if processorBusy then
		return
	end

	if #eventsQueue > 0 then
		processorBusy = true
		local eventToProcess: EventContext = eventsQueue[1]
		table.remove(eventsQueue, 1)
		print(eventToProcess)
		RoundSystem.processEvent(eventToProcess) -- may yield
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

	elseif state == "ACTIVE" then

		if eventToProcess.name == "ROUND_TIMER_ENDED" then
			RoundSystem.changeState("ENDING")
		end

    elseif state == "STARTING" then

		if eventToProcess.name == "STARTUP_COMPLETE" then
			if #PlayersInGame.getActivePlayers() >= Config.REQUIRED_PLAYERS then
				RoundSystem.changeState("ACTIVE")
			end		
		end

    elseif state == "ENDING" then
		if eventToProcess.name == "END_COMPLETE" then
			RoundSystem.changeState("INTERMISSION")
		end
	else
        warn("Unkown stateAtEnqueue: " .. eventToProcess.stateAtEnqueue)
    end

end

function RoundSystem.onINTERMISSION()
	
	intermissionTimer:Start(Config.INTERMISSION_TIME)

end

function RoundSystem.onSTARTING()
	
	for _ , each in PlayerPool.getActivePool() do
		PlayersInGame.addPlayer(each)
	end
	RoundSystem.queueEvent(buildEventContext("STARTUP_COMPLETE"))
	
end

function RoundSystem.onACTIVE()
	
	roundTimer:Start(Config.ROUND_TIME)


end

function RoundSystem.onENDING()
	
	PlayersInGame.clear()
	RoundSystem.queueEvent(buildEventContext("END_COMPLETE"))

end

function RoundSystem.changeState(newState : RoundState) : nil
	print("STATE CHANGE" .. newState)
	state = newState
	local transName = "on" .. newState
	local f = transitions[transName]
	if f then
		f(currentRound)
	end
	local g = RoundSystem[transName]
	if g then
		g()
	end
	
end

--Callbacks
function RoundSystem.onPlayerPoolChange(playersInPool : {Player}) 
	RoundSystem.queueEvent(buildEventContext("PLAYER_POOL_CHANGED"))

end
    

function RoundSystem.onActivePoolChange(playersInActive : {Players}) 
	RoundSystem.queueEvent(buildEventContext("ACTIVE_POOL_CHANGED"))
end

-- Connection functions
function RoundSystem.connectStart(fn: (Round) -> ())
	transitions.onSTARTING = fn
end

function RoundSystem.connectEnd(fn: (Round) -> ())
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

return RoundSystem
