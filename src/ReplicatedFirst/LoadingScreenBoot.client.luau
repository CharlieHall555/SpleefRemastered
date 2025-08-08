local ReplicatedFirst = game:GetService("ReplicatedFirst")
local localPlayer = game:GetService("Players").LocalPlayer
local LoadingScreen = ReplicatedFirst:WaitForChild("Loading")
local TweenService = game:GetService("TweenService")
local Remove = LoadingScreen:WaitForChild("removeEvent")
LoadingScreen.Parent = localPlayer:WaitForChild("PlayerGui")

local Spinner = LoadingScreen.Loading:WaitForChild("Spinner")
local LoadingFrame = LoadingScreen:WaitForChild("Loading")

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
