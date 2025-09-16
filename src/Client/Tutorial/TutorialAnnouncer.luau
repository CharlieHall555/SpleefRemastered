local LocalPlayer = game.Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

-- SoundPlayer.getIsMuted() -- must return false to play

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local TutorialAnnouncer = {}

-- Single shared sound instance
local player: Sound? = nil
local enabled = true
local currentStep: number? = nil
local endedConn: RBXScriptConnection? = nil

-- NOTE: Only one can play at once; starting a new one stops the current.
local announcements = {
	[1] = "rbxassetid://130801387277167",
	[2] = "rbxassetid://123638584807203",
	[3] = "rbxassetid://125889490022950",
	[4] = "rbxassetid://122317867622636",
	[5] = "rbxassetid://131155859274883",
	[6] = "rbxassetid://115804709344732",
	[7] = "rbxassetid://82332077410847",
	[8] = "rbxassetid://122419461654130",
	[9] = "rbxassetid://111159947523495",
}

local function ensurePlayer()
	if player and player.Parent then
		return player
	end

	if player then
		if endedConn then
			endedConn:Disconnect()
			endedConn = nil
		end
		player:Destroy()
	end

	player = Instance.new("Sound")
	player.Name = "TutorialAnnouncer"
	player.Parent = SoundService
	player.Volume = 2
	player.RollOffMaxDistance = 100000 -- effectively global
	player.RollOffMode = Enum.RollOffMode.Inverse
	player.EmitterSize = 5
	player.Looped = false
	player.PlayOnRemove = false

	endedConn = player.Ended:Connect(function()
		currentStep = nil
	end)

	return player
end

function TutorialAnnouncer.init()
	ensurePlayer()
end


function TutorialAnnouncer.play(stepNumber: number)
	if not enabled then
		return false
	end
	if typeof(stepNumber) ~= "number" then
		warn("[TutorialAnnouncer] play called with non-number step:", stepNumber)
		return false
	end

	local id = announcements[stepNumber]
	if not id then
		warn(("[TutorialAnnouncer] No announcement for step %s"):format(tostring(stepNumber)))
		return false
	end

	-- Respect global mute
	local isMuted = false
	local ok, muteErr = pcall(function()
		isMuted = SoundPlayer.getIsMuted()
	end)
	if not ok then
		warn("[TutorialAnnouncer] SoundPlayer.getIsMuted() failed:", muteErr)
	end
	if isMuted then
		-- Stop if something is playing so it doesn't resume unexpectedly when unmuted.
		if player and player.IsPlaying then
			player:Stop()
		end
		return false
	end

	local snd = ensurePlayer()

	-- If same step is already playing, restart from the beginning for clarity.
	if snd.IsPlaying then
		snd:Stop()
	end

	-- Assign & (lightly) preload, then play
	snd.SoundId = id
	snd.TimePosition = 0
	-- Best-effort preload to reduce start latency.
	pcall(function()
		ContentProvider:PreloadAsync({ snd })
	end)

	currentStep = stepNumber
	snd:Play()
	return true
end

--- Enables the announcer (does not auto-play).
function TutorialAnnouncer.enable()
	enabled = true
end

--- Disables the announcer and stops any current playback.
function TutorialAnnouncer.disable()
	enabled = false
	if player and player.IsPlaying then
		player:Stop()
	end
	currentStep = nil
end

return TutorialAnnouncer
