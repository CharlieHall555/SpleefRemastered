local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ListUtil = require(ModuleDirectory.ListUtil)

local playerBadgeHandler = {}

-- Roblox per-player limit is effectively ~5 calls/min to CheckUserBadgesAsync.
local MAX_CALLS_PER_MINUTE_PER_PLAYER = 5
local CHUNK_SIZE = 10
local MAX_RETRIES = 3

-- Cache: badgeCache[userId][badgeId] = boolean (owned)
local badgeCache: { [number]: { [number]: boolean } } = {}

-- Per-player token bucket
local _tokens: { [number]: number } = {}
local _lastRefillAt: { [number]: number } = {}

local function _refillTokens(userId: number)
	local now = os.clock()
	local last = _lastRefillAt[userId] or now
	local elapsed = now - last
	local ratePerSec = MAX_CALLS_PER_MINUTE_PER_PLAYER / 60
	_tokens[userId] = math.min(
		MAX_CALLS_PER_MINUTE_PER_PLAYER,
		(_tokens[userId] or MAX_CALLS_PER_MINUTE_PER_PLAYER) + elapsed * ratePerSec
	)
	_lastRefillAt[userId] = now
end

local function _consumeOneTokenBlocking(userId: number)
	while true do
		_refillTokens(userId)
		if (_tokens[userId] or 0) >= 1 then
			_tokens[userId] -= 1
			return
		end
		-- wait enough to earn ~1 token
		local need = 1 - (_tokens[userId] or 0)
		local waitSec = math.max(0.05, need / (MAX_CALLS_PER_MINUTE_PER_PLAYER / 60))
		task.wait(waitSec)
	end
end

local function _playerAlive(player: Player?): boolean
	return player ~= nil and player.Parent ~= nil
end

-- Safe wrapper with retries/backoff
local function _safeCheckUserBadges(userId: number, badgeIdChunk: { number }): (boolean, { number }?)
	local attempt = 0
	while attempt < MAX_RETRIES do
		attempt += 1

		_consumeOneTokenBlocking(userId)

		local ok, result = pcall(function()
			return BadgeService:CheckUserBadgesAsync(userId, badgeIdChunk)
		end)

		if ok and typeof(result) == "table" then
			return true, result
		end

		-- Exponential backoff + small jitter
		local backoff = math.min(2 ^ attempt, 10) + math.random() * 0.5
		task.wait(backoff)
	end
	return false, nil
end

function playerBadgeHandler.init()
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", playerBadgeHandler.newPlayer)

	-- cleanup token buckets on leave
	Players.PlayerRemoving:Connect(function(plr)
		local uid = plr.UserId
		_tokens[uid] = nil
		_lastRefillAt[uid] = nil
		badgeCache[uid] = nil
	end)
end

function playerBadgeHandler.hasBadge(player: Player, badgeId: number): boolean
	local userBucket = badgeCache[player.UserId]
	if not userBucket then
		return false
	end
	return userBucket[badgeId] == true
end

function playerBadgeHandler.awardBadge(player: Player, badgeId: number): boolean
	if not _playerAlive(player) then
		return false
	end

	local userId = player.UserId
	badgeCache[userId] = badgeCache[userId] or {}

    local lastError = nil

	local attempt = 0
	while attempt < 3 do
		attempt += 1
		local ok, err = pcall(function()
			-- This call yields internally; we keep it synchronous by not spawning.
			BadgeService:AwardBadge(userId, badgeId)
		end)

		if ok then
			-- Mark as owned in cache
			badgeCache[userId][badgeId] = true
			return true
        else
            lastError = err
		end

		-- brief fixed backoff between retries
		task.wait(0.1)
	end

    warn("Failed to award .. " .. player.Name .. ", With badgeId: " .. tostring(badgeId) .. " Error: " .. tostring(lastError))
	return false
end

-- Configure your experience badge IDs here
local experienceBadges = {
	616714331927071,
	4390549912459342,
	1168684446175066,
	2852582519047115,
	3520447514208860,
}

function playerBadgeHandler.newPlayer(player: Player)
	-- initialize cache: default false until loaded
	local userId = player.UserId
	badgeCache[userId] = {}

	for _, eachBadgeId in ipairs(experienceBadges) do
		badgeCache[userId][eachBadgeId] = false
	end

	-- load in the background
	task.spawn(playerBadgeHandler.loadBadges, player)
end

function playerBadgeHandler.loadBadges(player: Player)
	if not _playerAlive(player) then
		return
	end

	local userId = player.UserId
	badgeCache[userId] = badgeCache[userId] or {}

	-- Build list of IDs we still need to resolve (unknown or false are both fine to re-check once)
	local pending: { number } = {}
	for _, id in ipairs(experienceBadges) do
		if badgeCache[userId][id] ~= true then
			table.insert(pending, id)
		end
	end
	if #pending == 0 then
		return
	end

	local chunks = ListUtil.chunkList(pending, CHUNK_SIZE)

	for _, chunk in ipairs(chunks) do
		if not _playerAlive(player) then
			return
		end

		local ok, ownedIds = _safeCheckUserBadges(userId, chunk)
		if ok and ownedIds then
			for _, ownedId in ipairs(ownedIds) do
				badgeCache[userId][ownedId] = true
			end
			-- Any IDs not returned remain false (default) in the cache
		else
			-- Optional: schedule retry later if you want
		end
	end
end

return playerBadgeHandler
