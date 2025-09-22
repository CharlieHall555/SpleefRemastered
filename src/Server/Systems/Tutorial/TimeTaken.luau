local TimeTaken = {}

-- internal storage of start times per player
local startTimes: { [Player]: number } = {}

-- Start or reset the timer for a player
function TimeTaken.start(player: Player)
	if not player then
		warn("[TimeTaken] Tried to start with invalid player")
		return
	end
	startTimes[player.UserId] = os.time()
end

-- Get the time elapsed since start() was called for this player
-- Returns 0 if no start time exists
function TimeTaken.get(player: Player): number
	if not player then
		return 0
	end
	local start = startTimes[player.UserId]
	if start then
		return os.time() - start
	else
		return 0
	end
end

-- Optional cleanup if the player leaves
function TimeTaken.clear(player: Player)
	startTimes[player.UserId] = nil
end

return TimeTaken
