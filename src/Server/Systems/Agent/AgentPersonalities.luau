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
			wanderRadius = 10 + math.random(-1, 1),
			wanderTime = 0.35 + jitter(0.03),
			subGoalWeight = 0.97 + jitter(0.01),
			forwardBiasWeight = 0.08 + jitter(0.02),
			forwardBiasPower = 0.30 + jitter(0.05),
			threatRadius = 12.0 + jitter(0.5), -- tightened
			aggression = 0.08 + jitter(0.03),
			scoreNoiseAmp = 0.06,
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
			wanderRadius = 26 + math.random(-2, 2),
			wanderTime = 0.14 + jitter(0.02),
			subGoalWeight = 0.82 + jitter(0.02),
			forwardBiasWeight = 0.38 + jitter(0.03),
			forwardBiasPower = 0.85 + jitter(0.08),
			threatRadius = 9.0 + jitter(0.5),
			aggression = 0.55 + jitter(0.05),
			scoreNoiseAmp = 0.12,
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
			wanderRadius = 20 + math.random(-2, 2),
			wanderTime = 0.18 + jitter(0.02),
			subGoalWeight = 0.88 + jitter(0.02),
			forwardBiasWeight = 0.22 + jitter(0.03),
			forwardBiasPower = 0.55 + jitter(0.06),
			threatRadius = 10.5 + jitter(0.6),
			aggression = 0.35 + jitter(0.05),
			scoreNoiseAmp = 0.09,
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
			wanderRadius = 34 + math.random(-2, 2),
			wanderTime = 0.14 + jitter(0.02),
			subGoalWeight = 0.80 + jitter(0.02),
			forwardBiasWeight = 0.30 + jitter(0.03),
			forwardBiasPower = 0.70 + jitter(0.08),
			threatRadius = 11.0 + jitter(0.6),
			aggression = 0.22 + jitter(0.05),
			scoreNoiseAmp = 0.11,
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
			wanderRadius = 9 + math.random(-1, 1),
			wanderTime = 0.42 + jitter(0.04),
			subGoalWeight = 0.99 + jitter(0.01),
			forwardBiasWeight = 0.06 + jitter(0.02),
			forwardBiasPower = 0.25 + jitter(0.05),
			threatRadius = 14.0 + jitter(0.8), -- still higher than others, but not 20+
			aggression = 0.06 + jitter(0.03),
			scoreNoiseAmp = 0.04,
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
			wanderRadius = 28 + math.random(-2, 2),
			wanderTime = 0.12 + jitter(0.02),
			subGoalWeight = 0.78 + jitter(0.03),
			forwardBiasWeight = 0.42 + jitter(0.03),
			forwardBiasPower = 0.95 + jitter(0.10),
			threatRadius = 8.5 + jitter(0.5),
			aggression = 0.60 + jitter(0.05),
			scoreNoiseAmp = 0.14,
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
			wanderRadius = 24 + math.random(-1, 1),
			wanderTime = 0.20 + jitter(0.02),
			subGoalWeight = 0.94 + jitter(0.02),
			forwardBiasWeight = 0.20 + jitter(0.03),
			forwardBiasPower = 0.55 + jitter(0.06),
			threatRadius = 11.5 + jitter(0.6),
			aggression = 0.45 + jitter(0.05),
			scoreNoiseAmp = 0.07,
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
			wanderRadius = 38 + math.random(-4, 4),
			wanderTime = 0.10 + jitter(0.05), -- was 0.01; this keeps chaos without micro-twitching
			subGoalWeight = 0.62 + jitter(0.12),
			forwardBiasWeight = 0.28 + jitter(0.20),
			forwardBiasPower = 1.05 + jitter(0.35),
			threatRadius = 9.0 + jitter(2.0),
			aggression = 0.35 + jitter(0.35),
			scoreNoiseAmp = 0.22,
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
			wanderRadius = math.random(8, 40),
			wanderTime = math.random(10, 45) / 100, -- 0.10-0.45
			subGoalWeight = math.random(60, 100) / 100, -- 0.60-1.00
			forwardBiasWeight = math.random(0, 55) / 100, -- 0.00-0.55
			forwardBiasPower = math.random(25, 160) / 100, -- 0.25-1.60
			threatRadius = math.random(7, 16), -- tightened from 5-25
			aggression = math.random(0, 65) / 100, -- capped
			scoreNoiseAmp = math.random(5, 35) / 100, -- 0.05-0.35
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
