--!strict
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local Block = require(ModuleDirectory.Systems.Map.Block)

local TileScoreDebug = {}

local DEBUG_FOLDER_NAME = "TileScoreDebug"
local active: {[string]: SurfaceGui} = {} -- key -> gui
local debugFolder: Folder? = nil

-- If your blocks can be rotated, set this to the face you consider "top".
local TOP_FACE = Enum.NormalId.Top

local function ensureFolder(): Folder
	if debugFolder and debugFolder.Parent then
		return debugFolder
	end

	local existing = workspace:FindFirstChild(DEBUG_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		debugFolder = existing
		return existing
	end

	local f = Instance.new("Folder")
	f.Name = DEBUG_FOLDER_NAME
	f.Parent = workspace
	debugFolder = f
	return f
end

local function snap2(v: Vector2): Vector2
	return Vector2.new(math.floor(v.X + 0.5), math.floor(v.Y + 0.5))
end

local function makeKey(layerY: number, tilePos: Vector2): string
	return tostring(layerY) .. "|" .. tostring(tilePos.X) .. "," .. tostring(tilePos.Y)
end

local function getOrCreateSurfaceGui(id: string, adornee: BasePart): SurfaceGui
	local gui = active[id]
	if gui and gui.Parent then
		-- rebind in case part got swapped
		gui.Adornee = adornee
		gui.Face = TOP_FACE
		return gui
	end

	gui = Instance.new("SurfaceGui")
	gui.Name = "TileScoreSurfaceGui"
	gui.Adornee = adornee
	gui.Face = TOP_FACE
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50 -- tweak for sharpness
	gui.Parent = ensureFolder()

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.BackgroundTransparency = 0.25
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = bg

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -8, 0, 18)
	title.Position = UDim2.fromOffset(4, 2)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "TileScore"
	title.Parent = bg

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -8, 1, -22)
	body.Position = UDim2.fromOffset(4, 20)
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Text = ""
	body.Parent = bg

	active[id] = gui
	return gui
end

local function setText(gui: SurfaceGui, tilePos: Vector2, layerY: number, score: any)
	local bg = gui:FindFirstChild("BG") :: Frame?
	if not bg then return end
	local title = bg:FindFirstChild("Title") :: TextLabel?
	local body = bg:FindFirstChild("Body") :: TextLabel?
	if title then
		title.Text = ("(%d, %d) | Y=%d"):format(tilePos.X, tilePos.Y, layerY)
	end
	if body then
		local s = tonumber(score.Score) or 0
		local prox = tonumber(score.ProxScore) or 0
		local neigh = tonumber(score.NeighborScore) or 0
		local bid = score.blockId
		body.Text = ("Score: %.2f\nProx:  %.2f\nNeigh: %.2f\nBlockId: %s"):format(
			s, prox, neigh, bid and tostring(bid) or "nil"
		)
	end
end

function TileScoreDebug.init()
	ensureFolder()
	TileScoreDebug.reset()
end

function TileScoreDebug.reset()
	for _, gui in pairs(active) do
		if gui then gui:Destroy() end
	end
	table.clear(active)

	if debugFolder and debugFolder.Parent then
		debugFolder:ClearAllChildren()
	end
end

-- Supports:
-- A) { [layerY] = { [posKey] = TileScore } }
-- B) { [offsetKey] = TileScore|false } + (layerY, centerTilePos)
function TileScoreDebug.displayDebug(tileScoreInfo: any, layerY: number?, centerTilePos: Vector2?)
	ensureFolder()

	local used: {[string]: boolean} = {}

	local isFormatA = false
	if typeof(tileScoreInfo) == "table" then
		for k, v in pairs(tileScoreInfo) do
			if typeof(k) == "number" and typeof(v) == "table" then
				isFormatA = true
			end
			break
		end
	end

	if isFormatA then
		for ly, layerTable in pairs(tileScoreInfo) do
			if typeof(ly) ~= "number" or typeof(layerTable) ~= "table" then
				continue
			end

			for posKey, score in pairs(layerTable) do
				local pos2 = VectorUtil.deserializeVector2(posKey)
				local tilePos = snap2(pos2)

				local bid = score.blockId
				if typeof(bid) ~= "number" then
					continue
				end

				local blockData = Block.get(bid)
				local adornee: BasePart? = blockData and blockData.Part

				if adornee and adornee:IsA("BasePart") then
					local id = makeKey(ly, tilePos)
					local gui = getOrCreateSurfaceGui(id, adornee)
					setText(gui, tilePos, ly, score)
					used[id] = true
				end
			end
		end
	else
		if layerY == nil or centerTilePos == nil then
			warn("[TileScoreDebug] For getScoresAt output, pass (tileScoreInfo, layerY, centerTilePos).")
			return
		end

		local center = snap2(centerTilePos)

		for offsetKey, score in pairs(tileScoreInfo) do
			if score ~= false and score ~= nil then
				local offset = VectorUtil.deserializeVector2(offsetKey)
				local tilePos = snap2(center + offset)

				local bid = score.blockId
				if typeof(bid) ~= "number" then
					continue
				end

				local blockData = Block.get(bid)
				local adornee: BasePart? = blockData and blockData.Part

				if adornee and adornee:IsA("BasePart") then
					local id = makeKey(layerY, tilePos)
					local gui = getOrCreateSurfaceGui(id, adornee)
					setText(gui, tilePos, layerY, score)
					used[id] = true
				end
			end
		end
	end

	for id, gui in pairs(active) do
		if not used[id] then
			gui:Destroy()
			active[id] = nil
		end
	end
end

return TileScoreDebug
