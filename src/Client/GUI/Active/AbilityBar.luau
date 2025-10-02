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
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)

local currentCooldown : number = 0
local abilityName : string?

local AbilityBarGUI: Frame?

local abilityBarMoveable : Frame?
local abilityText : TextLabel?
local cooldownText : TextLabel?

function AbilityBar.onProfileLoaded()
    if PlatformDetector.getPlatform() == "MOBILE" then
        return
    end
    
    AbilityBarGUI = GuiAssets:WaitForChild("InGame"):WaitForChild("AbilityBar")
    AbilityBarGUI.Parent = Screens.gameHUD

    cooldownText = AbilityBarGUI.Bar.Cooldown
    abilityBarMoveable = AbilityBarGUI.Bar.Moveable
    abilityText = AbilityBarGUI.AbilityName

    local abilityDef = AbilitiesData[UserProfile.getValue("ability")]
    if abilityDef then
        currentCooldown = abilityDef.cooldown or 0
        abilityName = abilityDef.displayName
        abilityText.Text = abilityName .. " (Q)"
    end

    UserProfile.setOnUpdateCallback(function(valueName, newValue)
        if valueName == "ability" then
            local abilityDef = AbilitiesData[newValue]
            if abilityDef then
                currentCooldown = abilityDef.cooldown or 0
                abilityName = abilityDef.displayName
                abilityText.Text = abilityName .. " (Q)"
            end
        end
    end, "ability")

end

function AbilityBar.setCooldown(value : number)
    if AbilityBarGUI then
        local abilityValue = math.floor(value+0.99)
        cooldownText.Text = tostring(abilityValue)
        if abilityValue <= 0 then
            cooldownText.Text = ""
        end
        abilityBarMoveable.Size = UDim2.new(1 - (value / currentCooldown), 0, 1, 0)
    end 
end

function AbilityBar.getGui()
    return AbilityBarGUI
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
