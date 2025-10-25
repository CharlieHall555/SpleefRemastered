local challengeSnowballTemplate: Model?

local ChallengeSnowball = {}
ChallengeSnowball.__index = ChallengeSnowball

local counter = 0

local snowballs = {}

function ChallengeSnowball.init()
	challengeSnowballTemplate = game.ReplicatedStorage:WaitForChild("Resources"):WaitForChild("ChallengeSnowballTemplate")
end

function ChallengeSnowball.new(position: Vector3)
	local newSnowball = setmetatable({}, ChallengeSnowball)

	newSnowball.id = counter
	counter += 1
	newSnowball.instance = challengeSnowballTemplate:Clone()
	newSnowball.instance.PrimaryPart.CFrame = CFrame.new(position)
	newSnowball.instance.Parent = workspace
	newSnowball.instance:AddTag("CHALLENGE_SNOWBALL")
	newSnowball.instance:SetAttribute("Id", newSnowball.id)
	snowballs[newSnowball.id] = newSnowball
	return newSnowball
end

function ChallengeSnowball.destroyAll()
	for _, each in snowballs do
		each:Destroy()
	end
end

function ChallengeSnowball.destroyById(givenId: number): nil
	local snowball = snowballs[givenId]
	snowball:Destroy()
end

function ChallengeSnowball:Destroy()
	if self.instance then
		self.instance:Destroy()
	end
	snowballs[self.id] = nil
	self = nil
end

return ChallengeSnowball
