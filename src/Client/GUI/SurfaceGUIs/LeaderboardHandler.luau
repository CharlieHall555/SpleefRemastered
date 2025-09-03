local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local GUI_ASSETS = ReplicatedStorage:WaitForChild("GuiAssets")

-- panels in the world (BaseParts under workspace.Leaderboards)
local globalPanel: BasePart?
local weeklyPanel: BasePart?
local monthlyPanel: BasePart?

-- one SurfaceGui per board
type Board = {
	gui: SurfaceGui?,
	main: Frame?,
	list: ScrollingFrame?,
	template: Frame?,
}

local boards: { [string]: Board } = {
	global = { gui = nil, main = nil, list = nil, template = nil },
	weekly = { gui = nil, main = nil, list = nil, template = nil },
	monthly = { gui = nil, main = nil, list = nil, template = nil },
}

local updateConn: RBXScriptConnection?

local LeaderboardHandler = {}

-- utils
local function safeJsonDecode(payload: any): any?
	if typeof(payload) ~= "string" or payload == "" then
		return nil
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(payload)
	end)
	if ok and typeof(decoded) == "table" then
		return decoded
	end
	return nil
end

local function clearList(board: Board)
	if not board or not board.list then return end
	for _, child in ipairs(board.list:GetChildren()) do
		if child:IsA("Frame") and child ~= board.template then
			child:Destroy()
		end
	end
end

local function populateBoard(boardName: string, data: { [number]: { [string]: any } }?)
	local board = boards[boardName]
	if not board or not board.list or not board.template then return end
	if typeof(data) ~= "table" then return end

	clearList(board)

	for place, playerData in ipairs(data) do
		local clone = board.template:Clone()
		clone.Name = "Entry"
		clone.Visible = true

		local placeLabel = clone:FindFirstChild("Place")
		local nameLabel = clone:FindFirstChild("PlayerName")
		local winsLabel = clone:FindFirstChild("Wins")

		if placeLabel and placeLabel:IsA("TextLabel") then
			placeLabel.Text = tostring(place)
		end
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = tostring(playerData.playerName or "")
		end
		if winsLabel and winsLabel:IsA("TextLabel") then
			winsLabel.Text = tostring(playerData.win or 0)
		end

		clone.Parent = board.list
	end
end

local function mountBoard(boardName: string, panel: BasePart?)
	if not panel then return end

	local assetsFolder = GUI_ASSETS:FindFirstChild("LobbyGUIs")
	if not assetsFolder then return end

	local src = assetsFolder:FindFirstChild("LeaderboardTemplate")
	if not src or not src:IsA("SurfaceGui") then return end

	local gui = src:Clone()
	gui.Adornee = panel
	gui.Enabled = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local main = gui:FindFirstChild("Main")
	if not main or not main:IsA("Frame") then
		gui:Destroy()
		return
	end

	local leaderboardFrame = main:FindFirstChild("Leaderboard")
	if not leaderboardFrame or not leaderboardFrame:IsA("Frame") then
		gui:Destroy()
		return
	end

	local list = leaderboardFrame:FindFirstChild("ScrollingFrame")
	if not list or not list:IsA("ScrollingFrame") then
		gui:Destroy()
		return
	end

	local template = list:FindFirstChild("Template")
	if not template or not template:IsA("Frame") then
		gui:Destroy()
		return
	end
	template.Visible = false

	boards[boardName] = {
		gui = gui,
		main = main,
		list = list,
		template = template,
	}
end

function LeaderboardHandler.onProfileLoaded()
	-- find world panels once
	local lbFolder = workspace:FindFirstChild("Leaderboards")
	if not lbFolder then return end

	globalPanel = lbFolder:FindFirstChild("global") :: BasePart?
	weeklyPanel = lbFolder:FindFirstChild("weekly") :: BasePart?
	monthlyPanel = lbFolder:FindFirstChild("monthly") :: BasePart?

	-- mount all boards we have panels for
	mountBoard("global", globalPanel)
	mountBoard("weekly", weeklyPanel)
	mountBoard("monthly", monthlyPanel)

	-- initial snapshot for all boards
	local reply = RemoteEventHandler.InvokeOnServer("QUERY_GLOBAL_LEADERBOARD", 5)
	local decoded = safeJsonDecode(reply)
	if decoded then
		if typeof(decoded.global) == "table" then
			populateBoard("global", decoded.global)
		end
		if typeof(decoded.weekly) == "table" then
			populateBoard("weekly", decoded.weekly)
		end
		if typeof(decoded.monthly) == "table" then
			populateBoard("monthly", decoded.monthly)
		end
	end

	-- live updates (accepts any subset of global/weekly/monthly)
	if updateConn then
		updateConn:Disconnect()
		updateConn = nil
	end

	updateConn = RemoteEventHandler.newEventConnection("GLOBAL_LEADERBOARD_UPDATE", function(newData)
		local upd = safeJsonDecode(newData)
		if not upd then return end
		if typeof(upd.global) == "table" then
			populateBoard("global", upd.global)
		end
		if typeof(upd.weekly) == "table" then
			populateBoard("weekly", upd.weekly)
		end
		if typeof(upd.monthly) == "table" then
			populateBoard("monthly", upd.monthly)
		end
	end)
end

function LeaderboardHandler.destroy()
	if updateConn then
		updateConn:Disconnect()
		updateConn = nil
	end

	for name, board in pairs(boards) do
		if board.gui then
			board.gui:Destroy()
		end
		boards[name] = { gui = nil, main = nil, list = nil, template = nil }
	end

	globalPanel = nil
	weeklyPanel = nil
	monthlyPanel = nil
end

return LeaderboardHandler
