local AbilityBar = {}

local TweenService = game:GetService("TweenService")

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local localPlayer = game.Players.LocalPlayer
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local AbilitiesData = require(ClientModuleDirectory.AbilitiesData)
local ProfileVariables = require(ClientModuleDirectory.Variables.ProfileVariables)

local onPowerUp: (() -> ())? = nil

local currentCooldown: number = 0
local abilityName: string?

local AbilityBarGUI: Frame?

local abilityBarMoveable: Frame?
local abilityText: TextLabel?
local cooldownText: TextLabel?

local HIGHLIGHT_COLOR = Color3.fromRGB(241, 241, 241)
local DARK_COLOR = Color3.fromRGB(37, 37, 37)

local DEFAULT_BAR_COLOR = Color3.fromRGB(176, 39, 179)
local FULL_BAR_COLOR = Color3.fromRGB(251, 0, 255)

local function animateText(label: TextLabel)
	local original = label:GetAttribute("originalSize") or label.Size
	label.Size = UDim2.fromScale(original.X.Scale * 1.25, original.Y.Scale * 1.25)
	TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = original,
	}):Play()
end

local function isTouch(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Touch
end

local function setHighlighted(bg: Frame, img: ImageLabel, highlighted: boolean)
	if highlighted then
		bg.BackgroundColor3 = HIGHLIGHT_COLOR
		if img then
			img.ImageColor3 = DARK_COLOR
		end
	else
		bg.BackgroundColor3 = DARK_COLOR
		if img then
			img.ImageColor3 = HIGHLIGHT_COLOR
		end
	end
end

function AbilityBar.onProfileLoaded()
	if PlatformDetector.getPlatform() == "MOBILE" then
		AbilityBarGUI = GuiAssets:WaitForChild("InGame"):WaitForChild("AbilityBarMobile")

		AbilityBarGUI.PowerUpButton.Clickable.Activated:Connect(function()
			if onPowerUp then
				onPowerUp()
			end
		end)

		AbilityBarGUI.PowerUpButton.Clickable.InputEnded:Connect(function(input)
			if isTouch(input) then
				setHighlighted(AbilityBarGUI.PowerUpButton, nil, false)
			end
		end)

		AbilityBarGUI.PowerUpButton.Clickable.InputBegan:Connect(function(input)
			if isTouch(input) then
				setHighlighted(AbilityBarGUI.PowerUpButton, nil, true)
			end
		end)

		local abilityDef = AbilitiesData[ProfileVariables.getValue("ability") or ""]
		if abilityDef then
			currentCooldown = abilityDef.cooldown or 0
			abilityName = abilityDef.displayName or "Powerup"
			if AbilityBarGUI.PowerUpButton.TextLabel then
				AbilityBarGUI.PowerUpButton.TextLabel.Text = abilityName
			end
		end

		ProfileVariables.setOnUpdateCallback(function(valueName, newValue)
			if valueName == "ability" then
				local abilityDef = AbilitiesData[newValue]
				if abilityDef then
					currentCooldown = abilityDef.cooldown or 0
					abilityName = abilityDef.displayName or "Powerup"
					if AbilityBarGUI.PowerUpButton.TextLabel then
						AbilityBarGUI.PowerUpButton.TextLabel.Text = abilityName
					end
				end
			end
		end, "ability")
	else
		AbilityBarGUI = GuiAssets:WaitForChild("InGame"):WaitForChild("AbilityBar")
	end

	AbilityBarGUI.Parent = Screens.gameHUD

	cooldownText = AbilityBarGUI.Bar.Cooldown
	abilityBarMoveable = AbilityBarGUI.Bar.Moveable
	abilityText = AbilityBarGUI:FindFirstChild("AbilityName")

	local abilityDef = AbilitiesData[ProfileVariables.getValue("ability")]
	if abilityDef then
		currentCooldown = abilityDef.cooldown or 0
		abilityName = abilityDef.displayName
		if abilityText then
			abilityText.Text = abilityName .. " (Q)"
		end
	end

	ProfileVariables.setOnUpdateCallback(function(valueName, newValue)
		if valueName == "ability" then
			local abilityDef = AbilitiesData[newValue]
			if abilityDef then
				currentCooldown = abilityDef.cooldown or 0
				abilityName = abilityDef.displayName
				if abilityText then
					abilityText.Text = abilityName .. " (Q)"
				end
			end
		end
	end, "ability")

	local Arrow = AbilityBarGUI:FindFirstChild("Arrow")
	if Arrow then
		local tween = TweenService:Create(
			Arrow,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = UDim2.fromScale(Arrow.Position.X.Scale, Arrow.Position.Y.Scale - 0.2) }
		)
		tween:Play()
	end

	cooldownText:SetAttribute("originalSize" , cooldownText.Size)
end

function AbilityBar.setArrowVisible(value)
	local Arrow = AbilityBarGUI.Arrow
	if Arrow then
		Arrow.Visible = value
	end
end

local previousDisplayed = ""

function AbilityBar.setCooldown(value: number)
	if AbilityBarGUI then
		local abilityValue = math.floor(value + 0.99)
		cooldownText.Text = tostring(abilityValue)

		if cooldownText.Text ~= previousDisplayed then
			animateText(cooldownText)
		end

		previousDisplayed = cooldownText.Text
		if abilityValue <= 0 then
			cooldownText.Text = ""
		end
		abilityBarMoveable.Size = UDim2.new(1 - (value / currentCooldown), 0, 1, 0)
	end
end

function AbilityBar.getGui()
	return AbilityBarGUI
end

function AbilityBar.setOnPowerUp(fn: (() -> ())?)
	onPowerUp = fn
end

function AbilityBar.shake()
	if not AbilityBarGUI then
		return
	end
	local originalPos = AbilityBarGUI.Position
	local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function doTween(offset: Vector2)
		local goal = {}
		goal.Position = originalPos + UDim2.fromOffset(offset.X, offset.Y)
		local tween = TweenService:Create(AbilityBarGUI, tweenInfo, goal)
		tween:Play()
		tween.Completed:Wait()
	end

	task.spawn(function()
		doTween(Vector2.new(5, 0))
		doTween(Vector2.new(-5, 0))
		doTween(Vector2.new(3, 0))
		doTween(Vector2.new(-3, 0))
		local tween = TweenService:Create(AbilityBarGUI, tweenInfo, { Position = originalPos })
		tween:Play()
	end)
end

return AbilityBar
