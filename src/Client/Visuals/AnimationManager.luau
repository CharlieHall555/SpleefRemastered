local Players = game:GetService("Players")

local AnimationManager = {}

local animationCache: { [string]: Animation } = {}
local activeTracks: { [string]: AnimationTrack } = {}

local function toAssetId(id: string): string
	if string.sub(id, 1, 13) == "rbxassetid://" then
		return id
	end
	return "rbxassetid://" .. id
end

local function getAnimator(humanoid: Humanoid): Animator?
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function getAnimation(id: string): Animation
	local key = toAssetId(id)
	local cached = animationCache[key]
	if cached and cached.Parent ~= nil then
		return cached
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = key
	animationCache[key] = anim
	return anim
end

function AnimationManager.playAnimation(animId: string , looped : boolean): AnimationTrack?
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil
	end

	local character = localPlayer.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then
		return nil
	end

	local animator = getAnimator(humanoid)
	if not animator then
		return nil
	end

	local key = toAssetId(animId)
	local animation = getAnimation(animId)

	-- stop the currently active track if it exists
	local existingTrack = activeTracks[key]
	if existingTrack and existingTrack.IsPlaying then
		existingTrack:Stop()
		activeTracks[key] = nil
	end

	-- load and play new track
	local success, result = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not success then
		warn("Failed to load animation: " .. tostring(result))
		return nil
	end

	local track = result :: AnimationTrack
    if looped then
        track.Looped = looped
    end
	activeTracks[key] = track

	-- clear from active when it stops naturally
	track.Stopped:Connect(function()
		if activeTracks[key] == track then
			activeTracks[key] = nil
		end
	end)

	track:Play()
	return track
end

return AnimationManager
