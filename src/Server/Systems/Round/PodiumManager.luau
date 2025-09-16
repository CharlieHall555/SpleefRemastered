local Players = game:GetService("Players")

local ANIMATION_ID = "rbxassetid://133113167814737"

local PodiumManager = {}

export type PodiumManager = {
	init: () -> (),
	clear: () -> (),
	setChar: (winner: Player) -> (),
}

local currentModel: Model? = nil

local function playDance(humanoid: Humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = ANIMATION_ID

	local track = animator:LoadAnimation(animation)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.2)
end

local function alignToBase(model: Model, baseAttachment: Attachment)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hipHeight = humanoid and humanoid.HipHeight or 2
	local target = baseAttachment.WorldCFrame * CFrame.new(0, hipHeight, 0)
	model:PivotTo(target)
end

local function prepareForPodium(model: Model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.CanCollide = false
			inst.Massless = true
			inst.Anchored = inst.Name == "HumanoidRootPart"
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = false
		humanoid.Health = humanoid.MaxHealth
		playDance(humanoid)
	end
end

local function createCharacter(userId: number, baseAttachment: Attachment): Model?
	local model: Model? = nil
	local maxAttempts = 3

	for attempt = 1, maxAttempts do
		local success, result = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)

		if success and result then
			model = result
			break
		else
			warn(
				("CreateHumanoidModelFromUserId failed (attempt %d/%d) for userId %d"):format(
					attempt,
					maxAttempts,
					userId
				)
			)
			task.wait(0.25)
		end
	end

	if not model then
		return nil
	end

	model.Name = tostring(userId)
	model.Parent = workspace

	prepareForPodium(model)
	alignToBase(model, baseAttachment)

	return model
end

local base: Attachment = workspace:WaitForChild("Lobby").Podium.PrimaryPart:WaitForChild("Base")

function PodiumManager.init() end

function PodiumManager.clear()
	if currentModel and currentModel.Parent then
		currentModel:Destroy()
	end
	currentModel = nil
end

function PodiumManager.setChar(winner: Player)
	task.spawn(function()
		PodiumManager.clear()
		currentModel = createCharacter(winner.UserId, base)
	end)
end

return PodiumManager
