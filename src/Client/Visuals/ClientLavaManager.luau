--!strict
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local TweenService = game:GetService("TweenService")

local ClientLavaManager = {}

-- config
local LAVA_TWEEN_INFO = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false, 0)
local LAVA_OFFSET_TARGET = -6

-- state
local enabled = true

local currentModel: Model? = nil
local currentTween: Tween? = nil
local currentConns: { RBXScriptConnection } = {}
local currentToken = 0 -- increments to cancel old async waits

local function stopCurrent()
	-- cancel any in-flight async
	currentToken += 1

	-- disconnect
	for _, c in ipairs(currentConns) do
		c:Disconnect()
	end
	table.clear(currentConns)

	-- stop tween
	if currentTween then
		currentTween:Pause()
		currentTween:Destroy()
		currentTween = nil
	end

	currentModel = nil
end

local function startForBackground(background: Model)
	if not enabled then
		return
	end

	-- replace previous
	stopCurrent()
	currentModel = background

	-- cleanup if model disappears
	table.insert(currentConns, background.Destroying:Connect(function()
		if currentModel == background then
			stopCurrent()
		end
	end))
	table.insert(currentConns, background.AncestryChanged:Connect(function(_, parent)
		if not parent and currentModel == background then
			stopCurrent()
		end
	end))

	local myToken = currentToken

	task.spawn(function()
		-- Wait for Lava part
		local lavaInst = background:WaitForChild("Lava") :: Instance
		if myToken ~= currentToken or not enabled or currentModel ~= background then
			return
		end
		if not lavaInst:IsA("BasePart") then
			return
		end

		-- Wait for Texture on that part
		local tex = lavaInst:FindFirstChildOfClass("Texture")
		if not tex then
			tex = lavaInst:WaitForChildWhichIsA("Texture")
		end
		if myToken ~= currentToken or not enabled or currentModel ~= background then
			return
		end
		if not tex or not tex:IsA("Texture") then
			return
		end

		-- Start tween
		tex.OffsetStudsU = 0
		currentTween = TweenService:Create(tex, LAVA_TWEEN_INFO, { OffsetStudsU = LAVA_OFFSET_TARGET })
		currentTween:Play()
	end)
end

function ClientLavaManager.onLoaded()
	ClientStateTracker.connectActive(function()
		enabled = true
	end)

	RemoteEventHandler.newEventConnection("NEW_BACKGROUND_LOADED", function(background: Model)
		if not background or not background:IsA("Model") then
            warn("no background model")
			return
		end
		startForBackground(background)
	end)
end

function ClientLavaManager.enable()
	enabled = true
end

function ClientLavaManager.disable()
	if not enabled then
		return
	end
	enabled = false
	stopCurrent()
end

function ClientLavaManager.getEnabled()
	return enabled
end

return ClientLavaManager
