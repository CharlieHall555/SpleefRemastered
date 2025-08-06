export type SpatialSoundPlayer = {
	part: Part,
	sound: Sound,
	inUse: boolean,
}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Config = require(ClientModuleDirectory.Config)
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local SoundPlayer = {}

local activePlayers: { SpatialSoundPlayer } = {}
local idlePlayers: { SpatialSoundPlayer } = {}
local queuedSounds: { { soundId: string, position: Vector3 } } = {}

local isMuted = false

function SoundPlayer.setInMuted(value: boolean): nil
	isMuted = value
end

function SoundPlayer.getIsMuted(): boolean
	return isMuted
end

function SoundPlayer.init()
	-- create pool of spatial players
	for i = 1, Config.N_SOUND_PLAYERS do
		local newPart = Instance.new("Part")
		newPart.Transparency = 1
		newPart.Size = Vector3.new(0.1, 0.1, 0.1)
		newPart.Anchored = true
		newPart.CanCollide = false

		local newSound = Instance.new("Sound")
		newSound.Parent = newPart
		newSound.RollOffMode = Enum.RollOffMode.Inverse
		newSound.EmitterSize = Config.SOUND_EMITTER_SIZE or 10
		newSound.MaxDistance = Config.SOUND_MAX_DISTANCE or 100

		local player: SpatialSoundPlayer = {
			part = newPart,
			sound = newSound,
			inUse = false,
		}

		table.insert(idlePlayers, player)
	end

	-- process queued sounds whenever a player frees up
	RunService.Heartbeat:Connect(function()
		if #queuedSounds > 0 and #idlePlayers > 0 then
			local req = table.remove(queuedSounds, 1)
			SoundPlayer.queuePositionalSound(req.soundId, req.position)
		end
	end)
end

function SoundPlayer.queuePositionalSound(soundId: string, position: Vector3): nil
	-- if no free players, queue request
	if #idlePlayers == 0 then
		table.insert(queuedSounds, { soundId = soundId, position = position })
		return
	end

	-- take one from idle
	local player = table.remove(idlePlayers, 1)
	player.inUse = true
	table.insert(activePlayers, player)

	-- parent and position
	player.part.Parent = Workspace
	player.part.Position = position

	-- set sound asset
	if not soundId:match("^rbxassetid://") then
		player.sound.SoundId = "rbxassetid://" .. soundId
	else
		player.sound.SoundId = soundId
	end

	-- play
	if not isMuted then
		player.sound:Play()
	end

	-- cleanup when finished
	player.sound.Ended:Connect(function()
		for idx, p in ipairs(activePlayers) do
			if p == player then
				table.remove(activePlayers, idx)
				break
			end
		end
		player.part.Parent = nil
		player.inUse = false
		table.insert(idlePlayers, player)
	end)
end

function SoundPlayer.playSound(soundId: string): nil
	-- always play immediately without pooling
	local sound = Instance.new("Sound")
	sound.Parent = SoundService

	if not soundId:match("^rbxassetid://") then
		sound.SoundId = "rbxassetid://" .. soundId
	else
		sound.SoundId = soundId
	end

	if not isMuted then
		sound:Play()
	end

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return SoundPlayer
