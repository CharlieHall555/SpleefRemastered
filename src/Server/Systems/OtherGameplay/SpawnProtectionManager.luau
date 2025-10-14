local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ForceFieldTemplate = game:GetService("ServerStorage"):WaitForChild("Models"):WaitForChild("ForceFieldTemplate")
local Timer = require(ModuleDirectory.Timer)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local SpawnProtectionManager = {}

local SPAWN_PROTECTION_DURATION = 5

local activeCooldowns = {}

local function calcModelMass(model: Model)
	local out = 0
	local all = model:GetChildren()
	for _, each in all do
		if each:IsA("BasePart") then
			out += each:GetMass()
		end
	end
	return out
end

function SpawnProtectionManager.init()

	RemoteEventHandler.newEventConnection("PLAYER_LOADED" , function(player)
		
		activeCooldowns[player.UserId] = false
		SessionVariables.setValue(player, "spawnProtectionActive", false)

	end)

	Players.PlayerRemoving:Connect(function(player)
		


	end)

end

function SpawnProtectionManager.isActive(player)
	return (activeCooldowns[player.UserId] or false) == true
end

function SpawnProtectionManager.apply(player: Player)
	if player.Character == nil then
		return
	end

	activeCooldowns[player.UserId] = true
	SessionVariables.setValue(player, "spawnProtectionActive", true)

	local newForceField = ForceFieldTemplate:Clone()

	local newWeld = Instance.new("Weld")
	newWeld.Part1 = player.Character.PrimaryPart
	newWeld.Part0 = newForceField
	newWeld.Parent = player.Character.PrimaryPart
	newForceField.Parent = player.Character

	local timerLabel = newForceField.CountDown.TextLabel

	local newTimer = Timer.new()

	newTimer:Start(SPAWN_PROTECTION_DURATION)

	local modelMass = calcModelMass(player.Character)

	local newForce = Instance.new("VectorForce")
	newForce.Parent = player.Character.PrimaryPart
	newForce.Force = Vector3.new(0, modelMass * 0.9 * workspace.Gravity, 0)
	newForce.Attachment0 = player.Character.HumanoidRootPart:FindFirstChild("RootAttachment")
		or player.Character.HumanoidRootPart:FindFirstAncestorOfClass("Attachment")

	newTimer.StepCallback = function(time)
		timerLabel.Text = tostring(math.floor(time)) .. "s"
	end

	newTimer.EndCallback = function()

		activeCooldowns[player.UserId] = false
		SessionVariables.setValue(player, "spawnProtectionActive", false)

		if newForce then
			newForce:Destroy()
		end

		if newForceField then
			newForceField:Destroy()
		end

		if newWeld then
			newWeld:Destroy()
		end

		if newTimer then
			newTimer:Destroy()
			newTimer = nil
		end
	end
end

return SpawnProtectionManager
