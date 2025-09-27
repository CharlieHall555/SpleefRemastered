-- ShopMain.lua

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local ShopExtraLives = require(ClientModuleDirectory.Gui.Shop.ExtraLives)
local ShopAbilities = require(ClientModuleDirectory.Gui.Shop.Abilities)
local ShopShovels = require(ClientModuleDirectory.Gui.Shop.Shovels)
local ShopCoins = require(ClientModuleDirectory.Gui.Shop.Coins)

local LocalPlayer = Players.LocalPlayer

local ShopMain = {}

-- State (kept local to this module)
local shopGui: Frame
local main: Frame
local currentVisibleFrame: Frame
local buttonSelection: ScrollingFrame

-- Frames
local extraLifeFrame: Frame
local shovelsFrame: Frame
local abilityFrame: Frame
local itemTemplate: Frame
local coinsFrame: Frame

local initialized = false

local function bindSelectionButtons()
    buttonSelection.ExtraLife.Clickable.Activated:Connect(function()
        ShopMain.setFrame(extraLifeFrame, "Extra Lives")
    end)

    buttonSelection.AShovels.Clickable.Activated:Connect(function()
        ShopMain.setFrame(shovelsFrame, "Shovels")
    end)

    buttonSelection.Abilities.Clickable.Activated:Connect(function()
        ShopMain.setFrame(abilityFrame, "Abilities")
    end)

    buttonSelection.Coins.Clickable.Activated:Connect(function()
        ShopMain.setFrame(coinsFrame, "Coins")
    end)
end

local function wireHandlers()
    local closeBtn = main:WaitForChild("CloseButton")
    closeBtn.Clickable.Activated:Connect(function()
        ShopMain.hide()
    end)
end

function ShopMain.onProfileLoaded()
    if initialized then
        ShopExtraLives.refresh()
        ShopAbilities.refresh()
        ShopMain.show()
        return
    end

    shopGui = GuiAssets.Intermission:WaitForChild("Shop")

    if PlatformDetector.getPlatform() == "MOBILE" then
        shopGui.Size = UDim2.fromScale(0.85, 0.85)
    else
        shopGui.Size = UDim2.fromScale(0.51, 0.584)
    end

    shopGui.Visible = false
    shopGui.Parent = Screens.intermissionHUD

    main = shopGui:WaitForChild("Main")
    buttonSelection = main:WaitForChild("ButtonSelection")

    extraLifeFrame = main:WaitForChild("ExtraLives")
    shovelsFrame = main:WaitForChild("Shovels")
    abilityFrame = main:WaitForChild("Abilities")
    coinsFrame = main:WaitForChild("Coins")

    itemTemplate = shopGui:WaitForChild("ItemTemplate")

    wireHandlers()
    bindSelectionButtons()

    -- Initialize submodules
    ShopExtraLives.start(extraLifeFrame, itemTemplate)
    ShopAbilities.start(abilityFrame, itemTemplate)
    ShopShovels.start(shovelsFrame, itemTemplate)
    ShopCoins.start(coinsFrame, itemTemplate)

    initialized = true
end

function ShopMain.setFrame(frame: Frame, title: string)
    if not shopGui then
        return
    end

    if currentVisibleFrame then
        currentVisibleFrame.Visible = false
    end

    currentVisibleFrame = frame
    currentVisibleFrame.Visible = true
    main.Title.Text = title
end

function ShopMain.getVisible()
    return shopGui and shopGui.Visible or false
end

function ShopMain.show()
    if not shopGui then
        return
    end
    shopGui.Visible = true
    FrameSystem.setCurrent(shopGui)
end

function ShopMain.hide()
    if not shopGui then
        return
    end
    shopGui.Visible = false
    FrameSystem.setCurrent(nil)
end

return ShopMain
