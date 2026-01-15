local AgentAnimations = {}

-- You can add more ids later; keep this simple for now.
-- NOTE: built-in Roblox walk/idle assets work fine, but you can swap to your own.
local animationIds = {
	idle = { "http://www.roblox.com/asset/?id=507766666", weight = 1 },
	running = { "http://www.roblox.com/asset/?id=507767714", weight = 10 },
}

-- Internal cache per humanoid so we don't reload tracks every call
local cacheByHumanoid: { [Humanoid]: {
	animator: Animator,
	tracks: { [string]: AnimationTrack },
} } = {}

local function ensureAnimator(h: Humanoid): Animator?
	local animator = h:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end

	animator = Instance.new("Animator")
	animator.Parent = h
	return animator
end

local function ensureLoaded(agent: {}): (Humanoid?, Animator?, { [string]: AnimationTrack }?)
	if not agent or not agent.humanoid then
		return nil, nil, nil
	end

	local humanoid: Humanoid = agent.humanoid
	local animator = ensureAnimator(humanoid)
	if not animator then
		return nil, nil, nil
	end

	local cached = cacheByHumanoid[humanoid]
	if cached and cached.animator == animator and cached.tracks then
		return humanoid, animator, cached.tracks
	end

	-- Load tracks
	local tracks: { [string]: AnimationTrack } = {}

	local function load(name: string)
		local info = animationIds[name]
		if not info then
			return
		end

		local anim = Instance.new("Animation")
		-- Roblox expects rbxassetid://123 format, but URL form usually works too.
		-- Convert if needed.
		local raw = info[1]
		local idNum = tostring(raw):match("id=(%d+)")
		anim.AnimationId = idNum and ("rbxassetid://" .. idNum) or raw

		local track = animator:LoadAnimation(anim)
		track.Name = name
		-- Weights are per-play call, but we store the desired weight anyway
		tracks[name] = track
	end

	load("idle")
	load("running")

	cacheByHumanoid[humanoid] = {
		animator = animator,
		tracks = tracks,
	}

	return humanoid, animator, tracks
end

local function stopAllExcept(tracks: { [string]: AnimationTrack }, keepName: string?)
	for name, tr in pairs(tracks) do
		if name ~= keepName and tr and tr.IsPlaying then
			tr:Stop(0.15)
		end
	end
end

function AgentAnimations.init()
	-- optional: nothing required; kept for API symmetry
end

function AgentAnimations.idle(agent: {})
	local humanoid, _, tracks = ensureLoaded(agent)
	if not humanoid or not tracks then
		return
	end

	local idleTrack = tracks.idle
	if not idleTrack then
		return
	end

	-- Stop running etc.
	stopAllExcept(tracks, "idle")

	if not idleTrack.IsPlaying then
		-- Slight fade makes transitions smooth
		idleTrack:Play(0.15, animationIds.idle.weight or 1, 1)
	end
end

function AgentAnimations.running(agent: {})
	local humanoid, _, tracks = ensureLoaded(agent)
	if not humanoid or not tracks then
		return
	end

	local runTrack = tracks.running
	if not runTrack then
		return
	end

	-- Stop idle etc.
	stopAllExcept(tracks, "running")

	if not runTrack.IsPlaying then
		runTrack:Play(0.1, animationIds.running.weight or 1, 1)
	end
end

return AgentAnimations
