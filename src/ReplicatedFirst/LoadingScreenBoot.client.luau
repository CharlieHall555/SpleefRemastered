local ReplicatedFirst = game:GetService("ReplicatedFirst")
local localPlayer = game:GetService("Players").LocalPlayer
local LoadingScreen = ReplicatedFirst:WaitForChild("Loading")
local TweenService = game:GetService("TweenService")
local Remove = LoadingScreen:WaitForChild("removeEvent")
LoadingScreen.Parent = localPlayer:WaitForChild("PlayerGui")

local Spinner = LoadingScreen.Loading:WaitForChild("Spinner")
local SpinnerShadow = LoadingScreen.Loading:WaitForChild("SpinnerShadow")
local LoadingFrame = LoadingScreen:WaitForChild("Loading")

local LoadingMessage : TextLabel = LoadingFrame:WaitForChild("LoadingMessage")
local LoadingMessageShadow : TextLabel = LoadingFrame:WaitForChild("LoadingMessageShadow")


local Messages = {
    "Packing snowballs",
    "Sweeping the arena floor",
    "Counting snowflakes"
}

-- Spin settings
local SPIN_TIME = 1 -- seconds per full rotation

-- Create spin tween
local spinTween = TweenService:Create(
    Spinner,
    TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
    { Rotation = 360 }
)

-- Start spinning
Spinner.Rotation = 0
spinTween:Play()

-- Stop and clean up when Spinner is destroyed
Spinner.AncestryChanged:Connect(function(_, parent)
    if not parent then
        if spinTween then
            spinTween:Cancel()
            spinTween = nil
        end
    end
end)

-- Fade-out function
local function fadeOut()
    -- Stop spinner
    if spinTween then
        spinTween:Cancel()
        spinTween = nil
    end

    -- Tween LoadingFrame off the screen
    local tween = TweenService:Create(
        LoadingFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        { Position = UDim2.new(0, 0, -1, 0) }
    )
    tween:Play()
    tween.Completed:Wait()
end

Remove.Event:Connect(function()
    print("lol")
    fadeOut()
    LoadingScreen:Destroy()
end)

-- rotating loading messages + dot animation
local running = true
local currentBase = Messages[1]
local dotCount = 0

local function updateLabel()
	if not running or not LoadingMessage or not LoadingMessage.Parent then return end
	LoadingMessage.Text = string.format("%s%s", currentBase, string.rep(".", dotCount))
    LoadingMessageShadow.Text = string.format("%s%s", currentBase, string.rep(".", dotCount))
end

-- stop loops if the screen is removed
LoadingScreen.AncestryChanged:Connect(function(_, parent)
	if not parent then
		running = false
	end
end)

-- also stop when we fade out
local oldFadeOut = fadeOut
fadeOut = function()
	running = false
	oldFadeOut()
end

-- rotate the base message every 3s
task.spawn(function()
	local i = 1
	while running do
		currentBase = Messages[i]
		i = (i % #Messages) + 1
		-- keep the current message for ~3 seconds, dots will animate separately
		for _ = 1, 30 do
			if not running then break end
			task.wait(0.1)
		end
	end
end)

-- animate dots: "", ".", "..", "..." cycling every ~0.35s
task.spawn(function()
	dotCount = 0
	while running do
		dotCount = (dotCount % 3) + 1
		updateLabel()
		task.wait(0.35)
	end
end)

updateLabel()
