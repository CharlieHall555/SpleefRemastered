local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets

local AlertSystem = {}

local TIME_TO_DISAPPEAR = 5
local MAX_ALERTS = 5

local _alertStackGui: Frame?
local _alertStackTemplate: Frame?
local _alertQueue: { Frame }

function AlertSystem.init()
	_alertQueue = {}

	_alertStackGui = GuiAssets:WaitForChild("AlertStackGui", 4)
	assert(_alertStackGui, "AlertStackGui not found")

    _alertStackGui.Parent = player.PlayerGui:WaitForChild("General")

	_alertStackTemplate = _alertStackGui:WaitForChild("AlertTemplate", 4)
	assert(_alertStackTemplate, "AlertTemplate not found")
end

function AlertSystem.addAlert( alertMessage: string?, alertImage: string)
	assert(_alertStackGui and _alertStackTemplate, "AlertSystem not initialized")

	if #_alertQueue >= MAX_ALERTS then
		local oldest: Frame = table.remove(_alertQueue, 1)
		oldest:Destroy()
	end

	local newAlert = _alertStackTemplate:Clone()
    newAlert.Visible = true
	newAlert.Name = tostring(DateTime.now().UnixTimestampMillis)
	newAlert.Parent = _alertStackGui

	local messageLabel = newAlert.Message
	if messageLabel then
		messageLabel.Text = alertMessage
	end

	local icon = newAlert.Icon
	if icon then
		icon.Image = alertImage or ""
	end

	table.insert(_alertQueue, newAlert)

	task.delay(TIME_TO_DISAPPEAR, function()
		for i, alert in ipairs(_alertQueue) do
			if alert == newAlert then
				table.remove(_alertQueue, i)
				break
			end
		end
		if newAlert.Parent then
			newAlert:Destroy()
		end
	end)
end

return AlertSystem
