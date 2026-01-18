local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Agent

local AgentCombat = {}

local overlapsParams = OverlapParams.new()
overlapsParams.CollisionGroup = "CG_AGENT_OR_PLAYER"

function AgentCombat.init()
	Agent = require(ModuleDirectory.Systems.Agent.Agent)
end

function AgentCombat.getPlayersInRadius(agent: Agent.Agent, radius: number): ({ [number] : Agent.Agent | Player } , number)
	local inRadius = {}
	local seenChars = {}
	local origin = agent.model.PrimaryPart.Position
	local contactCount = 0

	local parts = workspace:GetPartBoundsInRadius(origin, radius)

	for _, eachPart: Instance in parts do
		local character = eachPart.Parent
		local characterPrimary = character.PrimaryPart 
		if seenChars[character] or not characterPrimary then
			continue
		end
		
		local distance = (characterPrimary.Position - origin).Magnitude
		local entity
		
		if character:HasTag("AGENT") then
			entity = Agent.getByModel(character)
		else
			entity = Players:GetPlayerFromCharacter(character)
		end
		
		if entity then
			inRadius[distance] = entity
			contactCount += 1
		end
		
		seenChars[character] = true
	end

	return inRadius, contactCount
end

local agentStamps : {[any]: {[string]: BasePart}} = {}

local STAMP_TEMPLATE : BasePart = Instance.new("Part")
STAMP_TEMPLATE.Size = Vector3.new(1,1,1)
STAMP_TEMPLATE.Anchored = true
STAMP_TEMPLATE.Shape = Enum.PartType.Ball
STAMP_TEMPLATE.CanCollide = false
STAMP_TEMPLATE.Material = Enum.Material.Neon
STAMP_TEMPLATE.Name = "AgentStamp"

function AgentCombat.placeStamp(
	agent : Agent.Agent,
	stampName : string,
	position : Vector3,
	color : Color3
)
	-- Ensure agent entry exists
	if agentStamps[agent] == nil then
		agentStamps[agent] = {}
	end

	local stampsForAgent = agentStamps[agent]

	-- If stamp already exists for this name, remove it
	local existingStamp = stampsForAgent[stampName]
	if existingStamp then
		existingStamp:Destroy()
		stampsForAgent[stampName] = nil
	end

	-- Create new stamp
	local stamp = STAMP_TEMPLATE:Clone()
	stamp.Name = stampName
	stamp.Color = color
	stamp.Position = position
	stamp.Parent = workspace -- or a dedicated folder

	-- Store reference
	stampsForAgent[stampName] = stamp
end

return AgentCombat
