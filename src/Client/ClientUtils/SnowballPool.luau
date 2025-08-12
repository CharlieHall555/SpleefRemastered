local RunService = game:GetService("RunService")

export type SnowballPool = {
	init: (self: SnowballPool) -> (),
	take: (self: SnowballPool) -> Part?,
	add: (self: SnowballPool, part: Part) -> (),
}

local root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(root.ClientModuleDirectory)
local Config = require(ClientModuleDirectory.Config)

local farAway = Vector3.new(1000000,0,0)

local SnowballPool = {}

local snowballTemplate: Part
local snowballDump: { Part } = {}
local counter = 1 -- our own counter, avoids #table problems

local pool: {Part} = {}


-- helper to push to pool
local function pushPart(p: Part)
	pool[#pool + 1] = p 
end

-- helper to pop from pool
local function popPart(): Part?
	return table.remove(pool)
end

function SnowballPool.init()
	snowballTemplate = game:GetService("ReplicatedStorage").Resources:WaitForChild("SnowballTemplate")

	task.spawn(function()
		local partCount = 0
		for i = 1, Config.INITIAL_SNOW_BALLS do
			partCount += 1
			local newPart = snowballTemplate:Clone()
			newPart.CastShadow = false
			newPart.Anchored = true -- consistent baseline
			newPart.CanCollide = false
			newPart.CanQuery = true
			newPart.CanTouch = false
			newPart.Position = farAway
			newPart.Parent = game.Workspace
			pushPart(newPart)

			if partCount >= Config.PARTS_PER_FRAME then
				task.wait()
				partCount = 0
			end
		end
	end)
end

function SnowballPool.take(): Part?
	local part = popPart()
	if part then
		return part
	end
	print("newone")
	-- Pool empty, create a new one
	local newPart = snowballTemplate:Clone()
	newPart.CastShadow = false
	newPart.Anchored = true -- consistent baseline
	newPart.CanCollide = false
	newPart.CanQuery = true
	newPart.CanTouch = false
	newPart.Position = farAway
	newPart.Parent = game.Workspace
	return newPart
end

function SnowballPool.add(part: Part)
	-- Reset minimal state needed for reuse
	part.Position = farAway
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.CanTouch = false
	pushPart(part)
end

return SnowballPool