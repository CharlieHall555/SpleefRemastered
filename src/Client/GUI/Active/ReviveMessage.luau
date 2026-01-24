local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local RoundStatus = require(ClientModuleDirectory.Gui.RoundStatus)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local localPlayer = Players.LocalPlayer

local ReviveMessage = {} :: any

-- GUI refs / state
local reviveMessageGui: Frame? = nil
local messageLabel: TextLabel? = nil
local messageStroke: UIStroke? = nil

-- Animation state
local isAnimating = false
local inTweens: { Tween } = {}
local outTweens: { Tween } = {}

local originPosition = nil

-- Tunables
local TWEEN_IN_TIME = 0.15
local TWEEN_OUT_TIME = 1.4
local HOLD_TIME = 0.1
local EASE_IN = TweenInfo.new(TWEEN_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASE_OUT = TweenInfo.new(TWEEN_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function setTransparencyInstant(bg: number, text: number, stroke: number)
    if reviveMessageGui then
        reviveMessageGui.BackgroundTransparency = bg
    end
    if messageLabel then
        messageLabel.TextTransparency = text
    end
    if messageStroke then
        messageStroke.Transparency = stroke
    end
end

local function playTweens(info: TweenInfo, targetBg: number, targetText: number, targetStroke: number): { Tween }
    local tweens = {}

    if reviveMessageGui then
        table.insert(tweens, TweenService:Create(reviveMessageGui, info, { BackgroundTransparency = targetBg }))
    end
    if messageLabel then
        table.insert(tweens, TweenService:Create(messageLabel, info, { TextTransparency = targetText }))
    end
    if messageStroke then
        table.insert(tweens, TweenService:Create(messageStroke, info, { Transparency = targetStroke }))
    end

    for _, t in ipairs(tweens) do
        t:Play()
    end

    return tweens
end

local function connectAssets()
    local guiAssets = ReplicatedStorage:WaitForChild("GuiAssets")
    local inGameFolder = guiAssets:WaitForChild("InGame")
    reviveMessageGui = inGameFolder:WaitForChild("ReviveMessage") :: Frame
    originPosition = reviveMessageGui.Position
    reviveMessageGui.Parent = Screens.gameHUD
    reviveMessageGui.Visible = false

    messageLabel = reviveMessageGui:FindFirstChild("Message") :: TextLabel?
    if messageLabel then
        messageStroke = messageLabel:FindFirstChildOfClass("UIStroke")
    end
 
    -- start hidden
    setTransparencyInstant(1, 1, 1)
end

function ReviveMessage.onLoaded()
    connectAssets()

    RemoteEventHandler.newEventConnection("PLAYER_REVIVED", function(player: Player)
        if player ~= localPlayer and ClientStateTracker.getState() == "ACTIVE" then
            ReviveMessage.show(player.DisplayName)
        end
    end)
end

function ReviveMessage.show(playerName: string)
    if not reviveMessageGui or not messageLabel then
        return
    end
    if isAnimating then
        return -- debounce: ignore if animation is running
    end

    local stateLabel = RoundStatus.getStateGui()
    if stateLabel and stateLabel.Visible == true then
        reviveMessageGui.Position = originPosition
    elseif stateLabel then
        reviveMessageGui.Position = stateLabel.Position
    else
        reviveMessageGui.Position = originPosition
    end

    isAnimating = true
    reviveMessageGui.Visible = true
    messageLabel.Text = playerName .. " has been Revived"

    -- reset to hidden
    setTransparencyInstant(1, 1, 1)

    -- quick fade in
    inTweens = playTweens(EASE_IN, 0.3, 0, 0)

    -- when one tween completes, proceed (they all share the same timing)
    inTweens[1].Completed:Once(function()
        
        local respawnChime = "rbxassetid://118694334396316"
		 --SoundPlayer.playSound(respawnChime , {volume = 0.5})

        task.wait(HOLD_TIME)
        -- slow fade out
        outTweens = playTweens(EASE_OUT, 1, 1, 1)

        outTweens[1].Completed:Once(function()
            if reviveMessageGui then
                reviveMessageGui.Visible = false
            end
            isAnimating = false
        end)
    end)
end

return ReviveMessage
