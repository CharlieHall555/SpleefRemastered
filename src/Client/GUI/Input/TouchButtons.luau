local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local LocalizationService = game:GetService("LocalizationService")
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local RunService = game:GetService("RunService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Player = game.Players.LocalPlayer
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local HIGHLIGHT_COLOR = Color3.fromRGB(241, 241, 241)
local DARK_COLOR = Color3.fromRGB(37, 37, 37)
local BUTTON_COOLDOWN = 0.1

local SHOVEL_ICON = "rbxassetid://82072164357150"
local SNOWBALL_ICON = "rbxassetid://102733737810926"
local POWERUP_ICON = "rbxassetid://104332731142938"

local touchButtonsGui: Frame

local actionButtonImage: ImageLabel
local jumpButtonImage: ImageLabel
local powerUpButtonImage: ImageLabel
local powerUpButtonText : TextLabel

local actionButtonClickable: ImageLabel
local jumpButtonClickable: ImageLabel
local powerUpButtonClickable: ImageLabel

local actionButtonBg: Frame
local jumpButtonBg: Frame
local powerUpButtonBg: Frame

local onJump: (() -> ())? = nil
local onAction: (() -> ())? = nil
local onPowerUp: (() -> ())? = nil

local lastJumpTime = 0
local lastActionTime = 0
local lastPowerUpTime = 0

local TouchButtons = {}
TouchButtons.__index = TouchButtons

local function destroyDefaultJump(): boolean & nil
	return pcall(function()
		Player.PlayerGui.TouchGui.TouchControlFrame.JumpButton.Visible = false
	end)
end

local function isTouch(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Touch
end

local function canActivate(lastTime: number): boolean
	return time() - lastTime >= BUTTON_COOLDOWN
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

function TouchButtons.onProfileLoaded()
	local s, _ = destroyDefaultJump()
	task.spawn(function()
		local tries = 0
		while s == false or tries > 200 do
			destroyDefaultJump()
			tries += 1
			task.wait(0.1)
		end
	end)
end

function TouchButtons.onLoaded()
	if PlatformDetector.getPlatform() == "MOBILE" then
		touchButtonsGui = GuiAssets.Input.TouchButtons
		touchButtonsGui.Parent = Screens.touchControls
		touchButtonsGui.Visible = true
		-- touchButtonsGui.Visible = (PlatformDetector.getPlatform() == "MOBILE")

		actionButtonBg = touchButtonsGui.ActionButton
		jumpButtonBg = touchButtonsGui.JumpButton
		powerUpButtonBg = touchButtonsGui.PowerUpButton

		actionButtonClickable = actionButtonBg.Clickable
		jumpButtonClickable = jumpButtonBg.Clickable
		powerUpButtonClickable = powerUpButtonBg.Clickable

		actionButtonImage = actionButtonBg.ImageLabel
		jumpButtonImage = jumpButtonBg.ImageLabel
		powerUpButtonImage = powerUpButtonBg.ImageLabel

		powerUpButtonBg.Visible = false
		--powerUpButtonImage.Visible = (ClientStateTracker.getState() == "ACTIVE")

		powerUpButtonText = powerUpButtonBg.TextLabel

		setHighlighted(actionButtonBg, actionButtonImage, false)
		setHighlighted(jumpButtonBg, jumpButtonImage, false)
		setHighlighted(powerUpButtonBg, powerUpButtonImage, false)

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

		powerUpButtonClickable.InputBegan:Connect(function(input)
			if isTouch(input) then
				setHighlighted(powerUpButtonBg, powerUpButtonImage, true)
			end
		end)

		powerUpButtonClickable.InputEnded:Connect(function(input)
			if isTouch(input) then
				setHighlighted(powerUpButtonBg, powerUpButtonImage, false)
			end
		end)

		powerUpButtonClickable.Activated:Connect(function()
			if canActivate(lastPowerUpTime) then
				lastPowerUpTime = time()
				if onPowerUp then
					onPowerUp()
				end
			end
		end)

		jumpButtonClickable.Activated:Connect(function()
			if canActivate(lastJumpTime) then
				lastJumpTime = time()
				if onJump then
					onJump()
				end
			end
		end)

		actionButtonClickable.Activated:Connect(function()
			if canActivate(lastActionTime) then
				lastActionTime = time()
				if onAction then
					onAction()
				end
			end
		end)

		RunService.RenderStepped:Connect(TouchButtons.resizeLoop)
	end
end

local lastScreenSize: Vector2? = nil

local function getInsets()
	local tl, br = game:GetService("GuiService"):GetGuiInset()
	return tl.X, br.X, br.Y
end

local function computeButtonSize(gui: Frame)
	local size = gui and gui.AbsoluteSize or Vector2.new(800, 600)
	local minAxis = math.min(size.X, size.Y)
	local isSmall = minAxis <= 500
	local base = isSmall and 70 or 120
	local scaled = math.clamp(math.floor(minAxis * 0.14), base, 160)
	return isSmall and base or scaled
end

function TouchButtons.resizeLoop()
	if not touchButtonsGui or not touchButtonsGui.Visible then
		return
	end

	local currentSize = touchButtonsGui.AbsoluteSize
	if lastScreenSize and currentSize == lastScreenSize then
		return -- no change, skip expensive recompute
	end
	lastScreenSize = currentSize

	local btn = computeButtonSize(touchButtonsGui)
	local margin = (btn >= 120) and 16 or 10

	-- Move the pair slightly further left from the edge
	local globalShift = 0

	-- Vertical offset so the action button sits a little higher than jump
	local actionLift = math.max(12, math.floor(btn * 1.1)) -- "couple px more" on small screens

	-- Ensure no overlap -> keep center distance > ~1.05*btn
	-- With a small vertical separation (actionLift), use a solid horizontal gap
	local horizontalGap = math.max(math.floor(btn * 0.95), 48)

	local _, rightInset, bottomInset = getInsets()

	-- Action: closer to the right edge and slightly higher
	if actionButtonBg then
		actionButtonBg.AnchorPoint = Vector2.new(1, 1)
		actionButtonBg.Size = UDim2.fromOffset(btn, btn)
		actionButtonBg.Position =
		UDim2.new(1, -(rightInset + margin + globalShift), 1, -(bottomInset + margin + actionLift))	
	end

	-- Jump: further left than the action (more inset), slightly lower
	if jumpButtonBg then
		jumpButtonBg.AnchorPoint = Vector2.new(1, 1)
		jumpButtonBg.Size = UDim2.fromOffset(btn, btn)
		jumpButtonBg.Position =
			UDim2.new(1, -(rightInset + margin + globalShift + horizontalGap), 1, -(bottomInset + margin))
	end
end

function TouchButtons.setActionToShovelIcon()
	actionButtonImage.Image = SHOVEL_ICON
end

function TouchButtons.setCooldown(value : number)
	powerUpButtonText.Text = tostring(math.floor(value))
end

function TouchButtons.showCooldown()
	powerUpButtonText.Visible = true
	powerUpButtonImage.Visible = false
end

function TouchButtons.hideCooldown()
	if touchButtonsGui then
		powerUpButtonText.Visible = false
		powerUpButtonImage.Visible = true
	end
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

function TouchButtons.setPowerUpCallback(fn: (() -> ())?)
	onPowerUp = fn
end

function TouchButtons.setVisibleActionButton(value: boolean): nil
	if PlatformDetector.getPlatform() == "MOBILE" then
		actionButtonBg.Visible = value
	end
end

function TouchButtons.setVisiblePowerUpButton(value: boolean): nil
	--power up button is disabled for now
	if powerUpButtonBg then
		powerUpButtonBg.Visible = false
	end
end


function TouchButtons.getGui()
	return touchButtonsGui
end

return TouchButtons
