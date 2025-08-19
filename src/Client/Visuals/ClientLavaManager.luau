local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local TweenService = game:GetService("TweenService")

local ClientLavaManager = {}

local runningTween: Tween? = nil
local enabled = false

local LAVATWEENINFO = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false, 0)
local LAVAOFFSETTARGET = -6

local function stopTween()
    if runningTween then
        runningTween:Pause()
        runningTween:Destroy()
        runningTween = nil
    end
end

local function playTween(lavaPart: BasePart)
    if not enabled then
        return
    end

    local lavaTexture = lavaPart:FindFirstChildOfClass("Texture")
    if not lavaTexture then
        return
    end

    stopTween()
    lavaTexture.OffsetStudsU = 0
    runningTween = TweenService:Create(lavaTexture, LAVATWEENINFO, { OffsetStudsU = LAVAOFFSETTARGET })
    runningTween:Play()
end

function ClientLavaManager.onLoaded()
    ClientStateTracker.connectActive(function()
        task.spawn(function()
            local background = workspace:FindFirstChild("background")
            if not background then
                return
            end

            local lavaPart = background:WaitForChild("Lava")
            if not lavaPart then
                return
            end

            lavaPart.Destroying:Connect(function()
                stopTween()
            end)

            playTween(lavaPart)
        end)
    end)
    ClientLavaManager.enable()
end

function ClientLavaManager.disable()
    enabled = false
    stopTween()
end

function ClientLavaManager.enable()
    enabled = true
    local background = workspace:FindFirstChild("background")
    if not background then
        return
    end
    local lavaPart = background:FindFirstChild("Lava")
    if lavaPart and lavaPart:IsA("BasePart") then
        playTween(lavaPart)
    end
end

function ClientLavaManager.getEnabled()
    return enabled
end

return ClientLavaManager
