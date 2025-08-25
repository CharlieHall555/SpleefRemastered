local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local HIGHLIGHT_COLOR = Color3.fromRGB(241, 241, 241)
local DARK_COLOR = Color3.fromRGB(37, 37, 37)
local BUTTON_COOLDOWN = 0.1

local SHOVEL_ICON = "rbxassetid://82072164357150"
local SNOWBALL_ICON = "rbxassetid://102733737810926"

local touchButtonsGui: Frame

local actionButtonImage: ImageLabel
local jumpButtonImage: ImageLabel

local actionButtonClickable: ImageLabel
local jumpButtonClickable: ImageLabel

local actionButtonBg: Frame
local jumpButtonBg: Frame

local onJump: (() -> ())? = nil
local onAction: (() -> ())? = nil

local lastJumpTime = 0
local lastActionTime = 0

local TouchButtons = {}
TouchButtons.__index = TouchButtons

local function destroyDefaultJump()
	pcall(function()
		Player.PlayerGui.TouchGui.TouchControlFrame.JumpButton:Destroy()
	end)
end

local function isTouch(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Touch
end

local function canActivate(lastTime: number): boolean
	return tick() - lastTime >= BUTTON_COOLDOWN
end

local function setHighlighted(bg: Frame, img: ImageLabel, highlighted: boolean)
	if highlighted then
		bg.BackgroundColor3 = HIGHLIGHT_COLOR
		img.ImageColor3 = DARK_COLOR
	else
		bg.BackgroundColor3 = DARK_COLOR
		img.ImageColor3 = HIGHLIGHT_COLOR
	end
end

function TouchButtons.onLoaded()
	if PlatformDetector.getPlatform() == "MOBILE" then
		destroyDefaultJump()

		touchButtonsGui = GuiAssets.Input.TouchButtons
		touchButtonsGui.Parent = Screens.touchControls
		touchButtonsGui.Visible = true
		-- touchButtonsGui.Visible = (PlatformDetector.getPlatform() == "MOBILE")


		actionButtonBg = touchButtonsGui.ActionButton
		jumpButtonBg = touchButtonsGui.JumpButton

		actionButtonClickable = actionButtonBg.Clickable
		jumpButtonClickable = jumpButtonBg.Clickable

		actionButtonImage = actionButtonBg.ImageLabel
		jumpButtonImage = jumpButtonBg.ImageLabel

		setHighlighted(actionButtonBg, actionButtonImage, false)
		setHighlighted(jumpButtonBg, jumpButtonImage, false)

		TouchButtons.setVisibleActionButton(ClientStateTracker.getState == "ACTIVE")

		actionButtonClickable.InputBegan:Connect(function(input)
			if isTouch(input) then
				setHighlighted(actionButtonBg, actionButtonImage, true)
			end
		end)

		actionButtonClickable.InputEnded:Connect(function(input)
			if isTouch(input) then
				setHighlighted(actionButtonBg, actionButtonImage, false)
			end
		end)

		jumpButtonClickable.InputBegan:Connect(function(input)
			if isTouch(input) then
				setHighlighted(jumpButtonBg, jumpButtonImage, true)
			end
		end)

		jumpButtonClickable.InputEnded:Connect(function(input)
			if isTouch(input) then
				setHighlighted(jumpButtonBg, jumpButtonImage, false)
			end
		end)

		jumpButtonClickable.Activated:Connect(function()
			if canActivate(lastJumpTime) then
				lastJumpTime = tick()
				if onJump then
					onJump()
				end
			end
		end)

		actionButtonClickable.Activated:Connect(function()
			if canActivate(lastActionTime) then
				lastActionTime = tick()
				if onAction then
					onAction()
				end
			end
		end)
	end
end

function TouchButtons.setActionToShovelIcon()
	actionButtonImage.Image = SHOVEL_ICON
end

function TouchButtons.setActionToSnowballIcon()
	actionButtonImage.Image = SNOWBALL_ICON
end

function TouchButtons.setJumpCallback(fn: (() -> ())?)
	onJump = fn
end

function TouchButtons.setActionCallback(fn: (() -> ())?)
	onAction = fn
end

function TouchButtons.setVisibleActionButton(value: boolean): nil
	actionButtonBg.Visible = value
end

function TouchButtons.getGui()
	return touchButtonsGui
end

return TouchButtons
