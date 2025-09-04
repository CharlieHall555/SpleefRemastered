local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local LevelUtilities = require(ClientModuleDirectory.LevelUtilities)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets

local ExperienceBar = {}

-- UI refs
local ExperienceFrame: Frame
local Fill: Frame

-- Tween config
local FILL_TWEEN = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getLevelAndXp(): (number, number)
	local level = tonumber(UserProfile.getValue("level")) or 1
	local xp = tonumber(UserProfile.getValue("xp")) or 0
	return level, xp
end

local function updateTexts(level: number, xp: number)
	local needed = LevelUtilities.xpToNextLevel(level) or 1
	ExperienceFrame.LevelText.Text = ("LVL %d"):format(level)
	ExperienceFrame.XPText.Text = ("%d / %d"):format(xp, needed)
end

local function tweenFillTo(percent: number)
	percent = math.clamp(percent, 0, 1)
	local goal = { Size = UDim2.fromScale(percent, Fill.Size.Y.Scale) }
	TweenService:Create(Fill, FILL_TWEEN, goal):Play()
end

local function refreshBar(level: number, xp: number)
	local needed = LevelUtilities.xpToNextLevel(level)
	if not needed or needed <= 0 then
		-- avoid div by zero; just show full
		tweenFillTo(1)
		return
	end
	tweenFillTo(xp / needed)
end

local function renderAll()
	local level, xp = getLevelAndXp()
	updateTexts(level, xp)
	refreshBar(level, xp)
end

function ExperienceBar.onProfileLoaded()
	-- build UI
	ExperienceFrame = GuiAssets.Intermission.Experience
	ExperienceFrame.Parent = Screens.intermissionHUD
	ExperienceFrame.Visible = true

	Fill = ExperienceFrame.XPBar.Moveable

	-- initial state
	-- snap fill instantly to avoid seeing a tween from 0 on first render
	do
		local level, xp = getLevelAndXp()
		local needed = LevelUtilities.xpToNextLevel(level) or 1
		local pct = math.clamp(needed > 0 and (xp / needed) or 1, 0, 1)
		Fill.Size = UDim2.fromScale(pct, Fill.Size.Y.Scale)
	end
	renderAll()

	-- callbacks
	UserProfile.setOnUpdateCallback(function(_, newLevel)
		-- level changed: update texts and recompute bar against new threshold
		local level = tonumber(newLevel) or 1
		local xp = select(2, getLevelAndXp())
		updateTexts(level, xp)
		refreshBar(level, xp)
	end, "level")

	UserProfile.setOnUpdateCallback(function(_, newXp)
		print("got")
		-- xp changed: update texts and tween bar
		local level = select(1, getLevelAndXp())
		local xp = tonumber(newXp) or 0
		updateTexts(level, xp)
		refreshBar(level, xp)
	end, "xp")

	ClientStateTracker.connectIntermission(function()
		ExperienceFrame.Visible = true
	end)

	ClientStateTracker.connectTutorial(function()
		ExperienceFrame.Visible = false
	end)
end

return ExperienceBar
