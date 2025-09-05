local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local blockOverlapParams = OverlapParams.new()
blockOverlapParams.CollisionGroup = "CG_BLOCK_SELECTION"
blockOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
blockOverlapParams.FilterDescendantsInstances = {}

local highlightColor = Color3.new(0.149019, 0.996078, 0)

local tempFolder = Instance.new("Model")
tempFolder.Name = "HighlightTempFolder"
tempFolder.Parent = workspace

local globalHighlight = Instance.new("Highlight")
globalHighlight.Name = "GlobalDistanceHighlight"
globalHighlight.FillColor = highlightColor
globalHighlight.OutlineColor = highlightColor
globalHighlight.OutlineTransparency = 0
globalHighlight.FillTransparency = 0.9
globalHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
globalHighlight.Parent = tempFolder

local highlightBlocks = {}

-- cache for current blocks
local currentBlocks: { [BasePart]: boolean } = {}
local originalParents: { [BasePart]: Instance } = {}

-- Internal: remove all highlights by moving blocks back
local function clearHighlights()
	for block in pairs(currentBlocks) do
		local success = pcall(function()
			if block.Parent == tempFolder then
				block.Parent = originalParents[block]
			end
		end)
		originalParents[block] = nil
	end
	table.clear(currentBlocks)
	table.clear(originalParents)
end

-- Public API
function highlightBlocks.reset()
	clearHighlights()
end

function highlightBlocks.changeColor(newColor: Color3)
	highlightColor = newColor
	globalHighlight.FillColor = newColor
	globalHighlight.OutlineColor = newColor
end

function highlightBlocks.within(distance: number)
	local character = LocalPlayer.Character
	if not character or not character.PrimaryPart then
		return
	end

	local position = character.PrimaryPart.Position
	local parts = workspace:GetPartBoundsInRadius(position, distance, blockOverlapParams)

	-- Build new set of blocks to highlight
	local newSet: { [BasePart]: boolean } = {}
	for _, block in ipairs(parts) do
		newSet[block] = true
	end

	-- Remove blocks no longer in range
	local toRemove = {}
	for block in pairs(currentBlocks) do
		if not newSet[block] then
			table.insert(toRemove, block)
		end
	end
	for _, block in ipairs(toRemove) do
		local success = pcall(function()
			if block.Parent == tempFolder then
				block.Parent = originalParents[block]
			end
		end)
		originalParents[block] = nil
		currentBlocks[block] = nil
	end

	-- Add new blocks
	for block in pairs(newSet) do
		if not currentBlocks[block] then
			local success = pcall(function()
				originalParents[block] = block.Parent
				block.Parent = tempFolder
			end)
			if success then
				currentBlocks[block] = true
			end
		end
	end
end

function highlightBlocks.outside(distance: number)
	local character = LocalPlayer.Character
	if not character or not character.PrimaryPart then
		return
	end

	local position = character.PrimaryPart.Position
	local cf = CFrame.new(position)
	local searchRadius = distance * 3 -- adjust how far you want to search for "outside" blocks
	local parts = workspace:GetPartBoundsInRadius(position, searchRadius, blockOverlapParams)
	
	-- Build new set of blocks to highlight
	local newSet: { [BasePart]: boolean } = {}
	for _, block in ipairs(parts) do
		local dist = (block.Position - position).Magnitude
		if dist > distance then
			newSet[block] = true
		end
	end

	-- Remove blocks no longer qualifying
	local toRemove = {}
	for block in pairs(currentBlocks) do
		if not newSet[block] then
			table.insert(toRemove, block)
		end
	end
	for _, block in ipairs(toRemove) do
		local success = pcall(function()
			if block.Parent == tempFolder then
				block.Parent = originalParents[block]
			end
		end)
		originalParents[block] = nil
		currentBlocks[block] = nil
	end

	-- Add new blocks
	for block in pairs(newSet) do
		if not currentBlocks[block] then
			local success = pcall(function()
				originalParents[block] = block.Parent
				block.Parent = tempFolder
			end)
			if success then
				currentBlocks[block] = true
			end
		end
	end
end

return highlightBlocks