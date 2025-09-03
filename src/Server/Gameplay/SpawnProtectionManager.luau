local LocalizationService = game:GetService("LocalizationService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ForceFieldTemplate = game:GetService("ServerStorage"):WaitForChild("Models"):WaitForChild("ForceFieldTemplate")
local Timer = require(ModuleDirectory.Timer)

local SpawnProtectionManager = {}

local SPAWN_PROTECTION_DURATION = 5

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
end

function SpawnProtectionManager.apply(player: Player)
	if player.Character == nil then
		return
	end

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

	newTimer.Callback = function(time)
		timerLabel.Text = tostring(math.floor(time)) .. "s"
	end

	newTimer.EndCallback = function()
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
