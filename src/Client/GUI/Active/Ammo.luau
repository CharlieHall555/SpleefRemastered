local Ammo = {}

local TweenService = game:GetService("TweenService")

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local RoundStatus = require(ClientModuleDirectory.Gui.RoundStatus)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)

local AmmoGui: Frame?

function Ammo.onProfileLoaded()
    AmmoGui = GuiAssets:WaitForChild("InGame"):WaitForChild("Ammo")
    AmmoGui.Parent = Screens.gameHUD

    ClientAmmoTracker.setOnMaxAmmoChanged(function(maxammo)
        if ClientAmmoTracker.getIsInfinite() then
            return
        end
        AmmoGui.Count.Text = 0 .. " / " .. maxammo
        AmmoGui.OutOfAmmo.Visible = true
        RoundStatus.outOfAmmo(true)
    end)

    ClientAmmoTracker.setOnAmmoChanged(function(newAmmo, maxammo)
        if ClientAmmoTracker.getIsInfinite() then
            return
        end

        AmmoGui.Count.Text = newAmmo .. " / " .. maxammo
        if newAmmo == 0 then
            AmmoGui.OutOfAmmo.Visible = true
            RoundStatus.outOfAmmo(true)
        else
            AmmoGui.OutOfAmmo.Visible = false
            RoundStatus.outOfAmmo(false)
        end
    end)

    ClientAmmoTracker.setInfiniteOn(function()
        AmmoGui.Count.Text = "∞"
        AmmoGui.OutOfAmmo.Visible = false
        RoundStatus.outOfAmmo(false)
    end)

    if PlatformDetector.getPlatform() == "MOBILE" then
        AmmoGui.AnchorPoint = Vector2.new(AmmoGui.AnchorPoint.X, 1)
        local touchButtonsGui = TouchButtons.getGui()
        local yScale = touchButtonsGui.Position.Y.Scale - touchButtonsGui.Size.Y.Scale
        AmmoGui.Position = UDim2.new(UDim.new(1, 0), UDim.new(yScale, 0))
        AmmoGui.UIScale.Scale = 1.2
    end
end

function Ammo.shake()
    if not AmmoGui then
        return
    end

    local originalPos = AmmoGui.Position
    local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function doTween(offset: Vector2)
        local goal = {}
        goal.Position = originalPos + UDim2.fromOffset(offset.X, offset.Y)
        local tween = TweenService:Create(AmmoGui, tweenInfo, goal)
        tween:Play()
        tween.Completed:Wait()
    end

    task.spawn(function()
        doTween(Vector2.new(5, 0))
        doTween(Vector2.new(-5, 0))
        doTween(Vector2.new(3, 0))
        doTween(Vector2.new(-3, 0))
        local tween = TweenService:Create(AmmoGui, tweenInfo, { Position = originalPos })
        tween:Play()
    end)
end

return Ammo
