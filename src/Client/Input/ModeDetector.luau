local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local MouseIcon = require(ClientModuleDirectory.Gui.MouseIcon)
local GuiService = game:GetService("GuiService")

export type mode = "SHOOT" | "MINE"

local ClientModeDetector = {}

local currentMode: mode? = nil
local listeners: { [number]: (mode) -> nil } = {}
local nextUid = 0

local function emit(newMode: mode)
	for _, fn in pairs(listeners) do
		local ok, err = pcall(fn, newMode)
		if not ok then
			warn("[ClientModeDetector] listener error:", err)
		end
	end
end

local function setMode(newMode: mode)
	if currentMode ~= newMode then
		currentMode = newMode
		emit(newMode)
	end
end

function ClientModeDetector.init()
	-- Default starting state
	currentMode = "SHOOT"
end

function ClientModeDetector.newBlock(newBlock)
	if newBlock then
		setMode("MINE")
	else
		setMode("SHOOT")
	end
end

function ClientModeDetector.connectModeChange(fn: (newMode: mode) -> nil): number
	assert(typeof(fn) == "function", "connectModeChange requires a function")

	nextUid += 1
	local uid = nextUid
	listeners[uid] = fn

	-- Fire immediately with current state so UI can sync
	task.defer(function()
		fn((currentMode or "SHOOT") :: mode)
	end)

	return uid
end

function ClientModeDetector.unbindConnection(uid: number)
	listeners[uid] = nil
end

function ClientModeDetector.getMode(): mode
	return (currentMode or "SHOOT") :: mode
end

return ClientModeDetector
