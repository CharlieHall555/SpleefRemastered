--!strict

--[[
	AgentPersonalities (3 Difficulty Tiers)

	Tiers:
	- EASY: safer, slower, reacts later, shoots/breaks less often
	- MEDIUM: balanced default
	- HARD: skirmisher-style, fast + aggressive, lower thresholds, tight threat radius
]]

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Agent = require(ModuleDirectory.Systems.Agent.Agent)

local AgentPersonalities = {}

local function createParams(spawnLocation: Vector3, params: Agent.AgentCreationParams): Agent.AgentCreationParams
	params.spawnLocation = spawnLocation
	return params
end

local function jitter(amount: number): number
	return (math.random(-100, 100) / 100) * amount
end

function AgentPersonalities.createEasy(spawnLocation: Vector3): Agent.AgentCreationParams
	-- Blend of Timid + Sentry traits (very readable / survivable)
	return createParams(spawnLocation, {
		maxHealth = 125 + math.random(-8, 8),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.38 + jitter(0.05),
			subGoalWeight = 0.98 + jitter(0.01),

			forwardBiasWeight = 0.08 + jitter(0.03),
			forwardBiasPower = 0.28 + jitter(0.06),

			-- React closer than old "across the map", but still not twitchy
			threatRadius = 19.0 + jitter(0.9),
			underThreatProxMultiplier = 2.2,

			aggression = 0.10 + jitter(0.04),
			scoreNoiseAmp = 0.05,
			noiseMagnitude = 0.12,

			movementConnectionWeight = 1.2,
			movementProximityWeight = 0.9,

			combatConnectionWeight = 2.4,
			combatProximityWeight = 1.0,

			-- Harder to "decide to fight"
			breakScoreThreshold = 0.85,
			shootScoreThreshold = 2.0,

			-- Slower actions
			breakCooldownMin = 0.55,
			breakCooldownMax = 1.9,
			shootCooldownMin = 0.45,
			shootCooldownMax = 1.6,

			idleUrgencyGain = 0.09,
			distanceWeight = 1.25,

			threatOnBlockWeight = 9,
			threatDistancePower = 1.05,
		},
	})
end

function AgentPersonalities.createMedium(spawnLocation: Vector3): Agent.AgentCreationParams
	-- Blend of Adaptive + Planner (your “normal”)
	return createParams(spawnLocation, {
		maxHealth = 102 + math.random(-6, 6),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.18 + jitter(0.03),
			subGoalWeight = 0.90 + jitter(0.02),

			forwardBiasWeight = 0.22 + jitter(0.04),
			forwardBiasPower = 0.60 + jitter(0.08),

			threatRadius = 17.5 + jitter(0.7),
			underThreatProxMultiplier = 2.1,

			aggression = 0.34 + jitter(0.07),
			scoreNoiseAmp = 0.09,
			noiseMagnitude = 0.20,

			movementConnectionWeight = 1.1,
			movementProximityWeight = 1.0,

			combatConnectionWeight = 2.0,
			combatProximityWeight = 1.25,

			breakScoreThreshold = 0.75,
			shootScoreThreshold = 1.5,

			breakCooldownMin = 0.30,
			breakCooldownMax = 1.35,
			shootCooldownMin = 0.25,
			shootCooldownMax = 1.05,

			idleUrgencyGain = 0.12,
			distanceWeight = 1.15,

			threatOnBlockWeight = 11,
			threatDistancePower = 0.9,
		},
	})
end

function AgentPersonalities.createHard(spawnLocation: Vector3): Agent.AgentCreationParams
	-- Basically your Skirmisher (best personality), with tiny tightening
	return createParams(spawnLocation, {
		maxHealth = 92 + math.random(-6, 6),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.12 + jitter(0.02),
			subGoalWeight = 0.78 + jitter(0.03),

			forwardBiasWeight = 0.44 + jitter(0.04),
			forwardBiasPower = 0.95 + jitter(0.10),

			threatRadius = 14.5 + jitter(0.6),
			underThreatProxMultiplier = 2.2,

			aggression = 0.62 + jitter(0.06),
			scoreNoiseAmp = 0.14,
			noiseMagnitude = 0.30,

			movementConnectionWeight = 0.8,
			movementProximityWeight = 1.35,

			combatConnectionWeight = 1.6,
			combatProximityWeight = 1.55,

			-- Easier to commit to breaking/shooting
			breakScoreThreshold = 0.60,
			shootScoreThreshold = 1.0,

			-- Faster action tempo
			breakCooldownMin = 0.20,
			breakCooldownMax = 0.85,
			shootCooldownMin = 0.15,
			shootCooldownMax = 0.65,

			idleUrgencyGain = 0.20,
			distanceWeight = 0.9,

			threatOnBlockWeight = 17,
			threatDistancePower = 0.6,
		},
	})
end


AgentPersonalities.Types = {
	EASY = "EASY",
	MEDIUM = "MEDIUM",
	HARD = "HARD",
}

local personalityList = {
	{ fn = AgentPersonalities.createEasy, name = AgentPersonalities.Types.EASY },
	{ fn = AgentPersonalities.createMedium, name = AgentPersonalities.Types.MEDIUM },
	{ fn = AgentPersonalities.createHard, name = AgentPersonalities.Types.HARD },
}

function AgentPersonalities.createRandom(spawnLocation: Vector3): (Agent.AgentCreationParams, string)
	local selected = personalityList[math.random(1, #personalityList)]
	return selected.fn(spawnLocation), selected.name
end

return AgentPersonalities
