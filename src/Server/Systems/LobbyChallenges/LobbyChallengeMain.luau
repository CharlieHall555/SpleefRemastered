local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ChallengeStart = require(ModuleDirectory.Challenge.ChallengeStart)
local ChallengeEnd = require(ModuleDirectory.Challenge.ChallengeEnd)
local ChallengeLoop = require(ModuleDirectory.Challenge.ChallengeLoop)

local ChallengeSnowball = require(ModuleDirectory.Challenge.ChallengeSnowball)

local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)

export type challengeState = {
	timeRunning: number,
}

local LobbyChallengeMain = {}

local active = false
local challengeType = ""
local challengeState: challengeState = {
	timeRunning = 0,
}

local validChallenges = {
	"FIND_SNOWBALLS",
}

local function selectRandomChallenge()
	local random = validChallenges[math.random(1, #validChallenges)]
	return random
end

function LobbyChallengeMain.start()
	active = true
	challengeType = selectRandomChallenge()
	challengeState = {
		timeRunning = 0,
	}

	local startFun = ChallengeStart[challengeType]

	if startFun then
		startFun(challengeState)
	end
end

function LobbyChallengeMain.stop()
	active = false
	challengeType = ""

	local endFun = ChallengeEnd[challengeType]

	if endFun then
		endFun(challengeState)
	end
end

function LobbyChallengeMain.init()
	RemoteEventHandler.newEventConnection("QUERY_LOBBY_CHALLENGE", function(player)
		if active then
			return {
				challengeType = challengeType,
			}
		else
			return nil
		end
	end)

	RunService.Stepped:Connect(function(deltaTime)
		if active then
			challengeState.timeRunning = challengeState.timeRunning + deltaTime
			local loopFun = ChallengeLoop[challengeType]
			if loopFun then
				loopFun(challengeState, deltaTime)
			end
		end
	end)

	ServerHitBoxManager.setUpCallback("CHALLENGE_SNOWBALL", function(player, otherPart)
		if active and challengeType == "FIND_SNOWBALLS" then
			LobbyChallengeMain.event("PLAYER_FOUND_SNOWBALL", player)
			local snowballId = otherPart:GetAttribute("Id")
			if snowballId then
				ChallengeSnowball.destroyById(snowballId)
			end
		end
	end)
end

function LobbyChallengeMain.event(eventType: string, player: Player, data: any?)
	if eventType == "PLAYER_FOUND_SNOWBALL" and active and challengeType == "FIND_SNOWBALLS" then
		SessionVariables.incrementValue(player, "snowballsFound", 1)
	end
end

return LobbyChallengeMain
