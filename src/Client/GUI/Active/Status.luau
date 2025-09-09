local RoundStatus = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local TweenService = game:GetService("TweenService")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)



local StatusGUI
local isShaking = false

local TweenService = game:GetService("TweenService")
local isShaking = false

function RoundStatus.shakePrepare()
	if isShaking then
		return
	end
	if not StatusGUI or not StatusGUI:FindFirstChild("State") then
		return
	end

	local stateLabel = StatusGUI.State
	if not stateLabel.Visible then
		return
	end

	isShaking = true

	local originalPos = stateLabel.Position
	local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

	-- quick side-to-side shake
	local offsets = {
		UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 5, originalPos.Y.Scale, originalPos.Y.Offset),
		UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 5, originalPos.Y.Scale, originalPos.Y.Offset),
		originalPos
	}

	task.spawn(function()
		for _, targetPos in ipairs(offsets) do
			local tween = TweenService:Create(stateLabel, tweenInfo, {Position = targetPos})
			tween:Play()
			tween.Completed:Wait()
		end
		isShaking = false
	end)
end


function RoundStatus.outOfAmmo(value: boolean)
	if StatusGUI then
		StatusGUI.AmmoWarning.Visible = value
	end
end

function RoundStatus.onProfileLoaded()
	StatusGUI = GuiAssets:WaitForChild("InGame"):WaitForChild("Status")
	StatusGUI.Parent = Screens.gameHUD

	ClientStateTracker.connectServerStateChange(function(newState)
		if newState == "PREPARING" then
			StatusGUI.State.Visible = true
			StatusGUI.State.Text = "Prepare"
			StatusGUI.State.Fire1.Visible = false
			StatusGUI.State.Fire2.Visible = false
		elseif newState == "ACTIVE" then
			StatusGUI.State.Visible = false
		end
	end)

	RemoteEventHandler.newEventConnection("START_SUDDEN_DEATH", function(player)
		StatusGUI.State.Visible = true
		StatusGUI.State.Text = "Sudden Death"
		StatusGUI.State.Fire1.Visible = true
		StatusGUI.State.Fire2.Visible = true
	end)

	RemoteEventHandler.newEventConnection("PLAYERS_IN_GAME_CHANGED", function(aliveNow: number, maxAlive: number)
		StatusGUI.TopBar.AliveLabel.Text = aliveNow .. " / " .. maxAlive
	end)

	RemoteEventHandler.newEventConnection("PREPARING_TIMER_CHANGED", function(time)
		if ClientStateTracker.getServerState() == "PREPARING" then
			StatusGUI.TopBar.TimerLabel.Text = math.max(0, math.floor(time))
		end
	end)

	RemoteEventHandler.newEventConnection("SUDDEN_DEATH_TIMER_CHANGED", function(time)
		if ClientStateTracker.getServerState() == "ACTIVE" then
			StatusGUI.TopBar.TimerLabel.Text = math.max(0, math.floor(time))
		end
	end)

	local AMMO_ORIGIN = StatusGUI.AmmoWarning.Position

	StatusGUI.State.Changed:Connect(function(property)
		if StatusGUI.State.Visible == true then
			StatusGUI.AmmoWarning.Position = AMMO_ORIGIN
		else
			StatusGUI.AmmoWarning.Position = StatusGUI.State.Position
		end
	end)
		
end

return RoundStatus
