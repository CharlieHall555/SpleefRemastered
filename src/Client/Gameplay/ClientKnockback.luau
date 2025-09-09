local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local VibrationService = require(ClientModuleDirectory.VibrationService)

local KnockbackUtilities = require(ClientModuleDirectory.KnockbackUtilities)

local ClientKnockback = {}

local HIGHLIGHT_NAME = "HitFlash"
local FLASH_TIME = 0.25
local HOLD_TIME = 0.05

local function removeExisting(character: Model)
    local existing = character:FindFirstChild(HIGHLIGHT_NAME)
    if existing and existing:IsA("Highlight") then
        existing:Destroy()
    end
end

local function playHitFlashOn(playerTarget: Player)
    local character = playerTarget.Character
    if not character then
        return
    end

    removeExisting(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = HIGHLIGHT_NAME
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillColor = Color3.fromRGB(255, 70, 70)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
    highlight.Parent = character

    local tweenIn = TweenService:Create(
        highlight,
        TweenInfo.new(FLASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { FillTransparency = 0.35, OutlineTransparency = 0 }
    )

    local tweenOut = TweenService:Create(
        highlight,
        TweenInfo.new(FLASH_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { FillTransparency = 1, OutlineTransparency = 1 }
    )

    tweenIn:Play()
    tweenIn.Completed:Wait()

    task.wait(HOLD_TIME)

    tweenOut:Play()
    tweenOut.Completed:Wait()

    if highlight then
        highlight:Destroy()
    end
end

function ClientKnockback.knockback(dir: Vector3, power: number)
    VibrationService.medium()
    local character = LocalPlayer.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
    if not rootPart or not humanoid then return end
    if dir.Magnitude < 1e-3 then return end

    local impulse = KnockbackUtilities.computeImpulse(rootPart, humanoid, dir, power)

    -- Optional micro-lift to reduce ground friction stickiness; tune as desired.
    impulse += Vector3.new(0, rootPart.AssemblyMass * 15, 0)

    rootPart:ApplyImpulse(impulse)
end

function ClientKnockback.init()
    RemoteEventHandler.newEventConnection("KNOCKBACK", ClientKnockback.knockback)

    RemoteEventHandler.newEventConnection("KNOCKBACK_ANIMATION", function(playerTarget: Player)
        if playerTarget and playerTarget.Character and playerTarget.Character.PrimaryPart then
            SoundPlayer.queuePositionalSound("rbxassetid://146163534", playerTarget.Character.PrimaryPart.Position)
        end

        if not playerTarget or playerTarget == LocalPlayer then
            return
        end

        playHitFlashOn(playerTarget)
    end)
end

return ClientKnockback
