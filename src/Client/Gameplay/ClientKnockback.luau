local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local localPlayer = game.Players.LocalPlayer
local ClientKnockback = {}
local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)

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

function ClientKnockback.init()
    RemoteEventHandler.newEventConnection("KNOCKBACK", function(dir: Vector3, power: number)
        local character = player.Character
        if character == nil then
            return
        end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            return
        end
        print("hiitttt")

        -- Create an impulse force for knockback
        local knockbackForce = Instance.new("VectorForce")
        knockbackForce.Name = "KnockbackForce"
        knockbackForce.Force = dir * power
        knockbackForce.Attachment0 = rootPart:FindFirstChild("RootAttachment") or Instance.new("Attachment", rootPart)
        knockbackForce.RelativeTo = Enum.ActuatorRelativeTo.World
        knockbackForce.ApplyAtCenterOfMass = true
        knockbackForce.Parent = rootPart

        -- Remove after short delay so it acts as an impulse
        task.delay(0.15, function()
            if knockbackForce then
                knockbackForce:Destroy()
            end
        end)
    end)

    RemoteEventHandler.newEventConnection("KNOCKBACK_ANIMATION", function(playerTarget: Player) -- and sound

        if playerTarget and playerTarget.Character then
            SoundPlayer.queuePositionalSound("rbxassetid://146163534" , playerTarget.Character.PrimaryPart.Position)
        end
        
        if not playerTarget or playerTarget == localPlayer then
            return
        end
        playHitFlashOn(playerTarget)
    end)
end

return ClientKnockback
