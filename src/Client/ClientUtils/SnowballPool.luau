local RunService = game:GetService("RunService")

export type SnowballPool = {
	init: (self: SnowballPool) -> (),
	take: (self: SnowballPool) -> Part?,
	add: (self: SnowballPool, part: Part) -> (),
}

local root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(root.ClientModuleDirectory)
local Config = require(ClientModuleDirectory.Config)

local SnowballPool = {}

local snowballTemplate: Part
local snowballDump: { Part } = {}

function SnowballPool.init()
	snowballTemplate = game:GetService("ReplicatedStorage").Resources:WaitForChild("SnowballTemplate")

	task.spawn(function()
		local partCount = 0
		for i = 1, Config.INITIAL_SNOW_BALLS do
			partCount += 1
			local newPart = snowballTemplate:Clone()
			newPart.CastShadow = false
			newPart.Anchored = false
			newPart.CanCollide = true
			newPart.Parent = nil
			table.insert(snowballDump, newPart)

			if partCount >= Config.PARTS_PER_FRAME then
				task.wait()
				partCount = 0
			end
		end
	end)
end

function SnowballPool.take(): Part?
	local part = snowballDump[1]
	if part then
		table.remove(snowballDump, 1)
		return part
	else
		part = snowballTemplate:Clone()
		part.CastShadow = false
		part.Anchored = true
		part.CanCollide = false
		part.Parent = nil
		return part
	end
	return nil
end

function SnowballPool.add(part: Part)
	part.Velocity = Vector3.zero
	part.RotVelocity = Vector3.zero
	part.Anchored = true
	part.CanCollide = false
	part.Parent = nil
	table.insert(snowballDump, part)
end

return SnowballPool
