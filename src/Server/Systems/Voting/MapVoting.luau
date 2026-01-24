local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ServerConstants = require(ModuleDirectory.ServerConstants)

local MapVoting = {}

local votesCast: { [number]: number } = {}
local choices: { [number]: string } = {}

local onEndVote: ((winningChoice: string) -> ())? = nil
local endTime: number = 0
local voteRunning = false

local function resetVotes()
	table.clear(votesCast)
end

local function tally(): { [number]: number }
	local output: { [number]: number } = {}

	for choiceIndex in pairs(choices) do
		output[choiceIndex] = 0
	end

	for _, choiceVoted in pairs(votesCast) do
		if output[choiceVoted] ~= nil then
			output[choiceVoted] += 1
		end
	end

	return output
end

-- (optional) throttle tally updates to avoid remote spam
local lastTallySent = 0
local TALLY_THROTTLE = 0.1

local function updateTallies(force: boolean?)
	if not voteRunning then
		return
	end

	local now = tick()
	if not force and (now - lastTallySent) < TALLY_THROTTLE then
		return
	end
	lastTallySent = now

	RemoteEventHandler.FireOnAllClients("VOTE_TALLY_UPDATED", tally())
end

local function recieveVote(player: Player, voteN: number)
	if typeof(voteN) ~= "number" then
		warn("Invalid Vote:", voteN)
		return
	end
	if not voteRunning then
		return
	end
	if tick() >= endTime then
		return
	end
	if choices[voteN] == nil then
		warn("Vote out of range:", voteN)
		return
	end

	votesCast[player.UserId] = voteN
	updateTallies(true)
end

function MapVoting.setChoices(values: { [number]: string })
	choices = values
	RemoteEventHandler.FireOnAllClients("VOTE_CHOICES_SET", choices)
	updateTallies()
end

function MapVoting.getResult(): string
	local tallies = tally()

	local bestCount = -1
	local bestChoices: { number } = {}

	for choiceIndex, count in pairs(tallies) do
		if count > bestCount then
			bestCount = count
			bestChoices = { choiceIndex }
		elseif count == bestCount then
			table.insert(bestChoices, choiceIndex)
		end
	end

	if #bestChoices == 0 then
		warn("MapVoting: No choices set.")
		return nil
	end

	local winningIndex = bestChoices[math.random(1, #bestChoices)]
	return choices[winningIndex]
end

function MapVoting.setEndCallback(callback: (winningChoice: string) -> ())
	onEndVote = callback
end

function MapVoting.startVote(voteLength: number)
	if voteRunning then
		warn("Already vote running")
		return
	end
	if next(choices) == nil then
		warn("MapVoting: startVote called with no choices.")
		return
	end

	resetVotes()
	voteRunning = true
	endTime = tick() + voteLength
	RemoteEventHandler.FireOnAllClients("START_VOTE" , voteLength)

	updateTallies(true) -- send initial 0-0-0 to clients

	task.spawn(function()
		while tick() < endTime do
			task.wait()
		end

		voteRunning = false

		local result = MapVoting.getResult()
		RemoteEventHandler.FireOnAllClients("END_VOTE" , choices)

		if onEndVote then
			onEndVote(result)
		end
	end)
end

function MapVoting.init()
	RemoteEventHandler.newEventConnection("SEND_VOTE", recieveVote)
end

return MapVoting
