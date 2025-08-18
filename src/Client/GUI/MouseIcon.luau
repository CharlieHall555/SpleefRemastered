local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local MouseIcon = {}

-- tweak these as needed
local SMALL_SHOVEL = "rbxassetid://112984427793297"
local SMALL_SNOWBALL = "rbxassetid://91214120728139"

-- internal state
local mouseTemplate: ImageLabel?
local activeIcon: ImageLabel?
local _renderConn: RBXScriptConnection?
local _screenGui: ScreenGui?
local mouse

-- ensure screen gui exists
local function getGui(): ScreenGui
	if _screenGui and _screenGui.Parent then return _screenGui end
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "MouseIconGui"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 10_000 -- sit on top of most UI
	g.Parent = pg
	_screenGui = g
	return g
end

local function onRender()
	if not activeIcon then return end
	local pos = UserInputService:GetMouseLocation()
	-- center the image on the cursor
	activeIcon.Position = UDim2.fromOffset(pos.X, pos.Y)
end

local function startFollowing()
	if _renderConn then return end
	_renderConn = RunService.RenderStepped:Connect(onRender)
end

local function stopFollowing()
	if _renderConn then
		_renderConn:Disconnect()
		_renderConn = nil
	end
end

local function showCustomCursor(assetId: string)
	-- prefer GUI cursor so Roblox doesn’t override it on UI hover
	if not mouseTemplate then
		-- fallback: use the modern property if template is missing
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseIcon = assetId
		return
	end

	local gui = getGui()
	if not activeIcon then
		activeIcon = mouseTemplate
		activeIcon.Name = "CustomMouseIcon"
		activeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		activeIcon.BackgroundTransparency = 1
		activeIcon.Visible = true
		activeIcon.Parent = gui
	end

	activeIcon.Image = assetId
    activeIcon.Visible = true
	UserInputService.MouseIconEnabled = false -- hide system cursor
	startFollowing()
end

local function clearCustomCursor()
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseIcon = "" -- restore default
	if activeIcon then
		activeIcon.Visible = false
		activeIcon = nil
	end
	stopFollowing()
end

function MouseIcon.onLoaded() -- runs on program start
	print("yy")
	mouseTemplate = ReplicatedStorage:WaitForChild("GuiAssets"):WaitForChild("MouseTemplate") :: ImageLabel
	mouse = player:GetMouse() -- fix casing; kept for compatibility if you need it elsewhere
end

function MouseIcon.snowball()
	showCustomCursor(SMALL_SNOWBALL)
end

function MouseIcon.shovel()
	showCustomCursor(SMALL_SHOVEL)
end

function MouseIcon.reset()
	clearCustomCursor()
end

return MouseIcon
