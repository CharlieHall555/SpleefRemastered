--!strict

--[[
	AgentPersonalities (Retuned)

	Goals:
	- Less overall aggression and forward-charging.
	- Tighter threatRadius (agents react closer to danger, not across the map).
	- More readable preset names and clearer behavioral separation.
]]

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Agent = require(ModuleDirectory.Systems.Agent.Agent)

local AgentPersonalities = {}

local function createParams(spawnLocation: Vector3, params: Agent.AgentCreationParams): Agent.AgentCreationParams
	params.spawnLocation = spawnLocation
	return params
end

-- Utility: small random jitter helper
local function jitter(amount: number): number
	-- returns ~[-amount, +amount]
	return (math.random(-100, 100) / 100) * amount
end

--[[
	1) TIMID - avoids conflict, stays close, slow tempo
]]
function AgentPersonalities.createTimid(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 110 + math.random(-5, 5),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.35 + jitter(0.03),
			subGoalWeight = 0.97 + jitter(0.01),
			forwardBiasWeight = 0.08 + jitter(0.02),
			forwardBiasPower = 0.30 + jitter(0.05),
			threatRadius = 17.0 + jitter(0.5),
			underThreatProxMultiplier = 1.8,
			aggression = 0.08 + jitter(0.03),
			scoreNoiseAmp = 0.06,
			movementConnectionWeight = 1.0,
			movementProximityWeight = 0.8,
			noiseMagnitude = 0.15,
			combatConnectionWeight = 2.5,
			combatProximityWeight = 1.0,
			breakScoreThreshold = 0.8,
			shootScoreThreshold = 2.0,
			breakCooldownMin = 0.5,
			breakCooldownMax = 1.8,
			shootCooldownMin = 0.4,
			shootCooldownMax = 1.4,
			idleUrgencyGain = 0.08,
			distanceWeight = 1.2,
			threatOnBlockWeight = 6,
			threatDistancePower = 1.0
		},
	})
end


--[[
	2) BOLD - pushes forward sometimes, but not a berserker
]]
function AgentPersonalities.createBold(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 95 + math.random(-5, 5),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.14 + jitter(0.02),
			subGoalWeight = 0.82 + jitter(0.02),
			forwardBiasWeight = 0.38 + jitter(0.03),
			forwardBiasPower = 0.85 + jitter(0.08),
			threatRadius = 15.0 + jitter(0.5),
			underThreatProxMultiplier = 2.5,
			aggression = 0.55 + jitter(0.05),
			scoreNoiseAmp = 0.12,
			movementConnectionWeight = 0.9,
			movementProximityWeight = 1.2,
			noiseMagnitude = 0.25,
			combatConnectionWeight = 1.8,
			combatProximityWeight = 1.4,
			breakScoreThreshold = 0.7,
			shootScoreThreshold = 1.1,
			breakCooldownMin = 0.25,
			breakCooldownMax = 1.0,
			shootCooldownMin = 0.18,
			shootCooldownMax = 0.7,
			idleUrgencyGain = 0.18,
			distanceWeight = 1.0,
			threatOnBlockWeight = 14,
			threatDistancePower = 0.7,
		},
	})
end


--[[
	3) ADAPTIVE - your default “normal” AI
]]
function AgentPersonalities.createAdaptive(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 100 + math.random(-5, 5),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.18 + jitter(0.02),
			subGoalWeight = 0.88 + jitter(0.02),
			forwardBiasWeight = 0.22 + jitter(0.03),
			forwardBiasPower = 0.55 + jitter(0.06),
			threatRadius = 18.0 + jitter(0.6),
			underThreatProxMultiplier = 2.0,
			aggression = 0.35 + jitter(0.05),
			scoreNoiseAmp = 0.09,
			movementConnectionWeight = 1.0,
			movementProximityWeight = 1.0,
			noiseMagnitude = 0.20,
			combatConnectionWeight = 2.0,
			combatProximityWeight = 1.25,
			breakScoreThreshold = 0.75,
			shootScoreThreshold = 1.5,
			breakCooldownMin = 0.3,
			breakCooldownMax = 1.4,
			shootCooldownMin = 0.25,
			shootCooldownMax = 1.0,
			idleUrgencyGain = 0.12,
			distanceWeight = 1.15,
			threatOnBlockWeight = 10,
			threatDistancePower = 0.9,
		},
	})
end


--[[
	4) WANDERER - explores widely but avoids fights
]]
function AgentPersonalities.createWanderer(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 85 + math.random(-5, 5),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.14 + jitter(0.02),
			subGoalWeight = 0.80 + jitter(0.02),
			forwardBiasWeight = 0.30 + jitter(0.03),
			forwardBiasPower = 0.70 + jitter(0.08),
			threatRadius = 16.5 + jitter(0.6),
			underThreatProxMultiplier = 1.6,
			aggression = 0.22 + jitter(0.05),
			scoreNoiseAmp = 0.11,
			movementConnectionWeight = 1.1,
			movementProximityWeight = 0.7,
			noiseMagnitude = 0.28,
			combatConnectionWeight = 2.2,
			combatProximityWeight = 1.1,
			breakScoreThreshold = 0.85,
			shootScoreThreshold = 1.8,
			breakCooldownMin = 0.4,
			breakCooldownMax = 1.6,
			shootCooldownMin = 0.35,
			shootCooldownMax = 1.3,
			idleUrgencyGain = 0.10,
			distanceWeight = 1.1,
			threatOnBlockWeight = 7,
			threatDistancePower = 1.1,
		},
	})
end


--[[
	5) SENTRY - defensive, aware, holds ground, rarely engages
	(“Defensive” but without reacting across half the map)
]]
function AgentPersonalities.createSentry(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 145 + math.random(-6, 6),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.42 + jitter(0.04),
			subGoalWeight = 0.99 + jitter(0.01),
			forwardBiasWeight = 0.06 + jitter(0.02),
			forwardBiasPower = 0.25 + jitter(0.05),
			threatRadius = 20.0 + jitter(0.8),
			underThreatProxMultiplier = 2.8,
			aggression = 0.06 + jitter(0.03),
			scoreNoiseAmp = 0.04,
			movementConnectionWeight = 1.3,
			movementProximityWeight = 0.9,
			noiseMagnitude = 0.10,
			combatConnectionWeight = 2.3,
			combatProximityWeight = 1.0,
			breakScoreThreshold = 0.8,
			shootScoreThreshold = 2.2,
			breakCooldownMin = 0.45,
			breakCooldownMax = 1.6,
			shootCooldownMin = 0.35,
			shootCooldownMax = 1.2,
			idleUrgencyGain = 0.10,
			distanceWeight = 1.3,
			threatOnBlockWeight = 11,
			threatDistancePower = 1.1,
		},
	})
end


--[[
	6) SKIRMISHER - opportunistic, quick, but not suicidal
	(replaces “Aggressive”)
]]
function AgentPersonalities.createSkirmisher(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 90 + math.random(-5, 5),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.12 + jitter(0.02),
			subGoalWeight = 0.78 + jitter(0.03),
			forwardBiasWeight = 0.42 + jitter(0.03),
			forwardBiasPower = 0.95 + jitter(0.10),
			threatRadius = 14.5 + jitter(0.5),
			underThreatProxMultiplier = 2.2,
			aggression = 0.60 + jitter(0.05),
			scoreNoiseAmp = 0.14,
			movementConnectionWeight = 0.8,
			movementProximityWeight = 1.3,
			noiseMagnitude = 0.30,
			combatConnectionWeight = 1.6,
			combatProximityWeight = 1.5,
			breakScoreThreshold = 0.6,
			shootScoreThreshold = 1.0,
			breakCooldownMin = 0.22,
			breakCooldownMax = 0.9,
			shootCooldownMin = 0.15,
			shootCooldownMax = 0.65,
			idleUrgencyGain = 0.20,
			distanceWeight = 0.9,
			threatOnBlockWeight = 17,
			threatDistancePower = 0.6,
		},
	})
end


--[[
	7) PLANNER - tactical and deliberate, moderate aggression
]]
function AgentPersonalities.createPlanner(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 110 + math.random(-4, 4),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.20 + jitter(0.02),
			subGoalWeight = 0.94 + jitter(0.02),
			forwardBiasWeight = 0.20 + jitter(0.03),
			forwardBiasPower = 0.55 + jitter(0.06),
			threatRadius = 18.0 + jitter(0.6),
			underThreatProxMultiplier = 2.1,
			aggression = 0.45 + jitter(0.05),
			scoreNoiseAmp = 0.07,
			movementConnectionWeight = 1.2,
			movementProximityWeight = 1.0,
			noiseMagnitude = 0.18,
			combatConnectionWeight = 1.9,
			combatProximityWeight = 1.3,
			breakScoreThreshold = 0.7,
			shootScoreThreshold = 1.3,
			breakCooldownMin = 0.28,
			breakCooldownMax = 1.2,
			shootCooldownMin = 0.22,
			shootCooldownMax = 0.9,
			idleUrgencyGain = 0.14,
			distanceWeight = 1.1,
			threatOnBlockWeight = 12,
			threatDistancePower = 0.8,
		},
	})
end


--[[
	8) CHAOTIC - still unpredictable, but not “always insane fast”
]]
function AgentPersonalities.createChaotic(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = 70 + math.random(-10, 15),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = 0.10 + jitter(0.05),
			subGoalWeight = 0.62 + jitter(0.12),
			forwardBiasWeight = 0.28 + jitter(0.20),
			forwardBiasPower = 1.05 + jitter(0.35),
			threatRadius = 15.0 + jitter(2.0),
			underThreatProxMultiplier = 1.5 + jitter(1.0),
			aggression = 0.35 + jitter(0.35),
			scoreNoiseAmp = 0.22,
			movementConnectionWeight = 0.7 + jitter(0.4),
			movementProximityWeight = 0.8 + jitter(0.5),
			noiseMagnitude = 0.45,
			combatConnectionWeight = 1.5 + jitter(0.8),
			combatProximityWeight = 1.0 + jitter(0.6),
			breakScoreThreshold = 0.6 + jitter(0.4),
			shootScoreThreshold = 1.0 + jitter(0.5),
			breakCooldownMin = 0.2 + jitter(0.2),
			breakCooldownMax = 0.8 + jitter(0.7),
			shootCooldownMin = 0.15 + jitter(0.2),
			shootCooldownMax = 0.6 + jitter(0.5),
			idleUrgencyGain = 0.12 + jitter(0.15),
			distanceWeight = 0.9 + jitter(0.5),
			threatOnBlockWeight = 8 + jitter(8),
			threatDistancePower = 0.8 + jitter(0.4),
		},
	})
end

--[[
	9) WILD - fully random (kept), but threatRadius tightened range
]]
function AgentPersonalities.createWild(spawnLocation: Vector3): Agent.AgentCreationParams
	return createParams(spawnLocation, {
		maxHealth = math.random(70, 140),
		AgentConfig = {
			wanderRadius = 5,
			wanderTime = math.random(10, 45) / 100, -- 0.10-0.45
			subGoalWeight = math.random(60, 100) / 100, -- 0.60-1.00
			forwardBiasWeight = math.random(0, 55) / 100, -- 0.00-0.55
			forwardBiasPower = math.random(25, 160) / 100, -- 0.25-1.60
			threatRadius = math.random(14, 22),
			underThreatProxMultiplier = math.random(15, 30) / 10, -- 1.5-3.0
			aggression = math.random(0, 65) / 100,
			scoreNoiseAmp = math.random(5, 35) / 100, -- 0.05-0.35
			movementConnectionWeight = math.random(5, 15) / 10, -- 0.5-1.5
			movementProximityWeight = math.random(5, 15) / 10, -- 0.5-1.5
			noiseMagnitude = math.random(10, 50) / 100, -- 0.10-0.50
			combatConnectionWeight = math.random(10, 30) / 10, -- 1.0-3.0
			combatProximityWeight = math.random(8, 20) / 10, -- 0.8-2.0
			breakScoreThreshold = math.random(50, 120) / 100, -- 0.5-1.2
			shootScoreThreshold = math.random(80, 220) / 100, -- 0.8-2.2
			breakCooldownMin = math.random(15, 50) / 100, -- 0.15-0.5
			breakCooldownMax = math.random(70, 180) / 100, -- 0.7-1.8
			shootCooldownMin = math.random(10, 45) / 100, -- 0.1-0.45
			shootCooldownMax = math.random(55, 140) / 100, -- 0.55-1.4
			idleUrgencyGain = math.random(8, 25) / 100, -- 0.08-0.25
			distanceWeight = math.random(80, 150) / 100, -- 0.8-1.5
			threatOnBlockWeight = math.random(50, 200) / 10, -- 5.0-20.0
			threatDistancePower = math.random(5, 12) / 10, -- 0.5-1.2
		},
	})
end


function AgentPersonalities.createRandom(spawnLocation: Vector3): Agent.AgentCreationParams
	local personalities = {
		AgentPersonalities.createTimid,
		AgentPersonalities.createAdaptive,
		AgentPersonalities.createWanderer,
		AgentPersonalities.createSentry,
		AgentPersonalities.createBold,
		AgentPersonalities.createSkirmisher,
		AgentPersonalities.createPlanner,
		AgentPersonalities.createChaotic,
		AgentPersonalities.createWild,
	}

	local f = personalities[math.random(1, #personalities)]
	return f(spawnLocation)
end

AgentPersonalities.Types = {
	TIMID = "TIMID",
	ADAPTIVE = "ADAPTIVE",
	WANDERER = "WANDERER",
	SENTRY = "SENTRY",
	BOLD = "BOLD",
	SKIRMISHER = "SKIRMISHER",
	PLANNER = "PLANNER",
	CHAOTIC = "CHAOTIC",
	WILD = "WILD",
}

return AgentPersonalities
