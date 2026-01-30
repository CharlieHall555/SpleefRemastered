
local Players = game:GetService("Players")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Materials = require(ClientModuleDirectory.Materials)
local VectorUtil = require(ClientModuleDirectory.VectorUtil)

local TextureManager = {}

local layersFolder: Folder? = nil

local NPOS_TO_UNIT_DIR: { [number]: Vector2 } = {
	[1] = Vector2.new(0, -1), -- forward
	[2] = Vector2.new(0, 1), -- back
	[3] = Vector2.new(1, 0), -- +X
	[4] = Vector2.new(-1, 0), -- -X
}

local DIR_TO_FACE: { [number]: Enum.NormalId } = {
	[1] = Enum.NormalId.Front,
	[2] = Enum.NormalId.Back,
	[3] = Enum.NormalId.Right,
	[4] = Enum.NormalId.Left,
}

local DIR_TO_OPPOSITE_FACE: { [number]: Enum.NormalId } = {
	[1] = Enum.NormalId.Back,
	[2] = Enum.NormalId.Front,
	[3] = Enum.NormalId.Left,
	[4] = Enum.NormalId.Right,
}

local spawnedTextures: { [string]: { Texture } } = {}

local function isBlock(part: Instance): boolean
	return part:IsA("BasePart") and (part :: BasePart):HasTag("Block")
end

local function isVisibleBlock(part: BasePart): boolean
	return part.Transparency < 1 and part.CanCollide
end

local function getTextureTemplateFromPart(partToTexture: BasePart): Texture?
	local partType = partToTexture:GetAttribute("type")
	if partType == nil then
		return nil
	end

	local def = Materials.get(partType)
	if not def then
		return nil
	end

	return def.texture
end

local function getLayer(layerId: string?): Folder?
	if not layerId then
		return nil
	end
	if layersFolder then
		local found = layersFolder:FindFirstChild(layerId)
		if found and found:IsA("Folder") then
			return found
		end
	end
	return nil
end

local function getPos(layer: Folder, pos: Vector2): BasePart?
	local sPos = VectorUtil.serializeVector2(pos)
	local child = layer:FindFirstChild(sPos)
	if child and child:IsA("BasePart") then
		return child
	end
	return nil
end

local function getNeighbors(layer: Folder, pos: Vector2): { [number]: BasePart }
	local neighbors: { [number]: BasePart } = {}
	for dirIndex, direction in pairs(NPOS_TO_UNIT_DIR) do
		local neighborPos = pos + direction
		local neighbor = getPos(layer, neighborPos)
		if neighbor then
			neighbors[dirIndex] = neighbor
		end
	end
	return neighbors
end

local function trackTexture(layerId: string?, texture: Texture?)
	if not layerId or not texture then
		return
	end
	if not spawnedTextures[layerId] then
		spawnedTextures[layerId] = {}
	end
	table.insert(spawnedTextures[layerId], texture)
end

local function destroyAllTexturesOn(block: BasePart)
	for _, child in block:GetChildren() do
		if child:IsA("Texture") then
			child:Destroy()
		end
	end
end

local function ensureFaceTexture(block: BasePart, textureTemplate: Texture, faceId: Enum.NormalId, layerId: string?)
	local name = faceId.Name
	local existing = block:FindFirstChild(name)
	if existing and existing:IsA("Texture") then
		-- Make sure it's on the right face (in case template/face changed)
		(existing :: Texture).Face = faceId
		return
	end

	local t = textureTemplate:Clone()
	t.Face = faceId
	t.Name = name
	t.Parent = block
	trackTexture(layerId, t)
end

local function removeFaceTexture(block: BasePart, faceId: Enum.NormalId)
	local existing = block:FindFirstChild(faceId.Name)
	if existing and existing:IsA("Texture") then
		existing:Destroy()
	end
end

local function ensureTopBottom(block: BasePart, textureTemplate: Texture, layerId: string?)
	ensureFaceTexture(block, textureTemplate, Enum.NormalId.Top, layerId)
	ensureFaceTexture(block, textureTemplate, Enum.NormalId.Bottom, layerId)
end

local function rebuildBlockTextures(block: BasePart)
	if not isBlock(block) then
		return
	end

	local layerId = block:GetAttribute("parentLayerId") :: string?
	local layer = getLayer(layerId)

	if not isVisibleBlock(block) then
		destroyAllTexturesOn(block)
		return
	end

	local textureTemplate = getTextureTemplateFromPart(block)
	if not textureTemplate then
		return
	end

	-- Always top/bottom
	ensureTopBottom(block, textureTemplate, layerId)

	-- If no layer context, can't do neighbors
	if not layer then
		return
	end

	local pos = VectorUtil.deserializeVector2(block.Name)
	local neighbors = getNeighbors(layer, pos)

	for dirIndex, _ in pairs(NPOS_TO_UNIT_DIR) do
		local faceId = DIR_TO_FACE[dirIndex]
		local neighbor = neighbors[dirIndex]

		local exposed = (neighbor == nil) or (not isVisibleBlock(neighbor))
		if exposed then
			ensureFaceTexture(block, textureTemplate, faceId, layerId)
		else
			removeFaceTexture(block, faceId)
		end
	end
end

-- When a block becomes visible, it covers neighbor faces that touch it.
local function coverNeighborFacesByThisBlock(block: BasePart)
	local layerId = block:GetAttribute("parentLayerId") :: string?
	local layer = getLayer(layerId)
	if not layer then
		return
	end
	if not isVisibleBlock(block) then
		return
	end

	local pos = VectorUtil.deserializeVector2(block.Name)
	local neighbors = getNeighbors(layer, pos)

	for dirIndex, neighbor in pairs(neighbors) do
		if isVisibleBlock(neighbor) then
			local neighborFaceToRemove = DIR_TO_OPPOSITE_FACE[dirIndex]
			removeFaceTexture(neighbor, neighborFaceToRemove)
		end
	end
end

local function exposeNeighborFacesByThisBlock(block: BasePart)
	local layerId = block:GetAttribute("parentLayerId") :: string?
	local layer = getLayer(layerId)
	if not layer then
		return
	end

	local pos = VectorUtil.deserializeVector2(block.Name)
	local neighbors = getNeighbors(layer, pos)

	for dirIndex, neighbor in pairs(neighbors) do
		if isVisibleBlock(neighbor) then
			local textureTemplate = getTextureTemplateFromPart(neighbor)
			if textureTemplate then
				local neighborFaceToAdd = DIR_TO_OPPOSITE_FACE[dirIndex]
				ensureFaceTexture(neighbor, textureTemplate, neighborFaceToAdd, layerId)
			end
		end
	end
end

-- Central “apply change at block” function (DRY):
-- - action = "show" or "hide"
-- - updates block itself AND the neighbor faces affected by the change
local function applyVisibilityChange(block: BasePart, action: "show" | "hide")
	if action == "hide" then
		-- First hide self (so neighbor logic sees it as hidden)
		destroyAllTexturesOn(block)
		-- Then expose neighbors
		exposeNeighborFacesByThisBlock(block)
	else
		-- Show: rebuild self textures then cover neighbor faces
		rebuildBlockTextures(block)
		coverNeighborFacesByThisBlock(block)
	end
end

--//====================================================
--// Initial layer processing
--//====================================================

local function rebuildLayer(layer: Folder)
	-- First pass: build each block’s own faces (based on current neighbors)
	for _, child in layer:GetChildren() do
		if child:IsA("BasePart") and child:HasTag("Block") then
			rebuildBlockTextures(child)
		end
	end

	-- Second pass: ensure neighbor faces are covered where needed
	-- (helps if order of creation caused temporary “exposed” faces)
	for _, child in layer:GetChildren() do
		if child:IsA("BasePart") and child:HasTag("Block") and isVisibleBlock(child) then
			coverNeighborFacesByThisBlock(child)
		end
	end
end

local function onLayerAdded(layer: Instance)
	if not (layer:IsA("Folder")) then
		return
	end
	rebuildLayer(layer)
end

local function onLayerRemoved(layer: Instance)
	if not layer:IsA("Folder") then
		return
	end

	local loadedForLayer = spawnedTextures[layer.Name] or {}
	for _, each in loadedForLayer do
		if each and each.Parent then
			each:Destroy()
		end
	end
	spawnedTextures[layer.Name] = nil
end

--//====================================================
--// Descendant add (new block) handling
--//====================================================

local function onDescendantAdded(desc: Instance)
	if not desc:IsA("BasePart") then
		return
	end
	if not desc:HasTag("Block") then
		return
	end

	if not isVisibleBlock(desc) then
		return
	end

	applyVisibilityChange(desc, "show")
end

--//====================================================
--// Public API
--//====================================================

function TextureManager.blockShownLocally(block: BasePart)
	applyVisibilityChange(block, "show")
end

function TextureManager.blockHiddenLocally(block: BasePart)
	applyVisibilityChange(block, "hide")
end

function TextureManager.onProfileLoaded()
	layersFolder = game.Workspace:WaitForChild("Layers", 2) :: Folder?
	if not layersFolder then
		warn("TextureManager failed startup (no Workspace.Layers)")
		return
	end

	-- Remote events
	RemoteEventHandler.newEventConnection("BLOCK_SHOWN", function(b: BasePart)
		applyVisibilityChange(b, "show")
	end)

	RemoteEventHandler.newEventConnection("BLOCK_HIDDEN", function(b: BasePart)
		applyVisibilityChange(b, "hide")
	end)

	RemoteEventHandler.newEventConnection("BLOCK_DESTROYED", function(b: BasePart)
		applyVisibilityChange(b, "hide")
	end)

	RemoteEventHandler.newEventConnection("BLOCK_SLOWFALL", function(b: BasePart)
		applyVisibilityChange(b, "hide")
	end)

	-- Initial + live updates
	layersFolder.ChildAdded:Connect(onLayerAdded)
	layersFolder.ChildRemoved:Connect(onLayerRemoved)
	layersFolder.DescendantAdded:Connect(onDescendantAdded)

	-- If layers already exist before we connect:
	for _, layer in layersFolder:GetChildren() do
		if layer:IsA("Folder") then
			rebuildLayer(layer)
		end
	end
end

return TextureManager
