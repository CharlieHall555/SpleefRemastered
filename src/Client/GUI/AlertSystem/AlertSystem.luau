local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local TweenService = game:GetService("TweenService")

local AlertSystem = {}

local TIME_TO_DISAPPEAR = 5
local MAX_ALERTS = 4

local alertTemplate: Frame?
local container: Instance? = nil

-- Active alerts + O(1) removal
local activeAlerts: { Frame } = {}
local alertIndex: { [Frame]: number } = {}

local function iterAllGuiInstances(root: Instance): { Instance }
	local list = { root }
	for _, d in ipairs(root:GetDescendants()) do
		table.insert(list, d)
	end
	return list
end

local function tweenFadeOut(alert: Frame, duration: number)
	local info = TweenInfo.new(duration)

	for _, d in ipairs(iterAllGuiInstances(alert)) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			TweenService:Create(d, info, { TextTransparency = 1 }):Play()
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
			TweenService:Create(d, info, { ImageTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		end
	end
end

local function removeAlert(alert: Frame)
	local i = alertIndex[alert]
	if not i then
		return
	end

	local last = activeAlerts[#activeAlerts]
	activeAlerts[i] = last
	activeAlerts[#activeAlerts] = nil

	alertIndex[alert] = nil
	if last then
		alertIndex[last] = i
	end

	if alert.Parent then
		alert:Destroy()
	end
end

local function createAlert(alertText: string, alertImage: string?)
	if not alertTemplate then
		warn("alertTemplate is nil")
		return nil
	end

	local newTemplate = alertTemplate:Clone()
	newTemplate.Visible = true
	newTemplate.Message.Text = alertText
	if alertImage and alertImage ~= "" then
		newTemplate.Icon.Image = alertImage
	end

	return newTemplate
end

function AlertSystem.onProfileLoaded()
	local alertStackTemplate = GuiAssets:WaitForChild("AlertSystem"):WaitForChild("AlertStackGui")
	if not alertStackTemplate then
		warn("AlertSystem Failed")
		return
	end

	alertTemplate = GuiAssets:WaitForChild("AlertSystem"):WaitForChild("AlertTemplate")
	AlertSystem.Gui = alertStackTemplate:Clone()
	AlertSystem.Gui.Parent = Screens.gameHUD

	container = AlertSystem.Gui
end

function AlertSystem.show(alertText: string, alertImage: string?)
	if not AlertSystem.Gui or not container then
		return
	end

	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui and not AlertSystem.Gui.Parent then
		AlertSystem.Gui.Parent = playerGui
	end

	local alert = createAlert(alertText, alertImage)
	if not alert then
		return
	end

	if #activeAlerts >= MAX_ALERTS then
		local oldest = activeAlerts[1]
		if oldest then
			removeAlert(oldest)
		end
	end

	alert.Parent = container
	table.insert(activeAlerts, alert)
	alertIndex[alert] = #activeAlerts

	local half = TIME_TO_DISAPPEAR * 0.5
	local fadeDuration = TIME_TO_DISAPPEAR - half

	-- start fade after 50% of time
	task.delay(half, function()
		-- might already be removed
		if alertIndex[alert] then
			tweenFadeOut(alert, fadeDuration)
		end
	end)

	-- destroy at end
	task.delay(TIME_TO_DISAPPEAR, function()
		removeAlert(alert)
	end)
end

return AlertSystem
