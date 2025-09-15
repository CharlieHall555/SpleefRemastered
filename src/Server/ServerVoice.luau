local VoiceChatService = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function wireUp(source: Instance, target: Instance)
	local wire = Instance.new("Wire")
	wire.SourceInstance = source
	wire.TargetInstance = target
	wire.Parent = source
end

-- Set up a global volume slider for everybody's voice
local volumeSlider = Instance.new("AudioFader", Workspace)
local output = Instance.new("AudioDeviceOutput", Workspace)
wireUp(volumeSlider, output)

local function onPlayerAdded(player: Player)
	local device = Instance.new("AudioDeviceInput", player)
	device.Player = player
	-- Route each new player's microphone input to the global volume slider
	wireUp(device, volumeSlider)
end

function VoiceChatService.init()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return VoiceChatService
