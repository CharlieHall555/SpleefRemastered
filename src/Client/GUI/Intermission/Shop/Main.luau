-- ShopMain.lua

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local RunService = game:GetService("RunService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local ShopExtraLives = require(ClientModuleDirectory.Gui.Shop.ExtraLives)
local ShopAbilities = require(ClientModuleDirectory.Gui.Shop.Abilities)
local ShopShovels = require(ClientModuleDirectory.Gui.Shop.Shovels)
local ShopCoins = require(ClientModuleDirectory.Gui.Shop.Coins)
local ShopGamepass = require(ClientModuleDirectory.Gui.Shop.Gamepass)
local VibrationService = require(ClientModuleDirectory.VibrationService)

local LocalPlayer = Players.LocalPlayer

local AUTO_HIDE_SECONDS = 10

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
local gamepassFrame: Frame
local missingFundsFrame : Frame

local missingFundsOpen = 0

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

    buttonSelection.GamePasses.Clickable.Activated:Connect(function()
        ShopMain.setFrame(gamepassFrame, "Gamepasses")
    end)
end

local function wireHandlers()
    local closeBtn = main:WaitForChild("CloseButton")
    closeBtn.Clickable.Activated:Connect(function()
        ShopMain.hide()
    end)
end

function ShopMain.missingFunds(amount : number)
    if not missingFundsFrame then
        return
    end
    missingFundsOpen = os.clock()
    missingFundsFrame.Visible = true
    missingFundsFrame.Window.AmountMissing.Text = "You are missing " .. string.format("<font color='rgb(255,205,23)'>%dC</font>", amount)

    local errorBlip = "rbxassetid://70373378044427"
	 --SoundPlayer.playSound(errorBlip, { volume = 1.5 })
    VibrationService.light()
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
    gamepassFrame = main:WaitForChild("Gamepasses")
    missingFundsFrame = main:WaitForChild("MissingFunds")

    missingFundsFrame.Visible = false

    itemTemplate = shopGui:WaitForChild("ItemTemplate")

    wireHandlers()
    bindSelectionButtons()

    -- Initialize submodules
    ShopExtraLives.start(extraLifeFrame, itemTemplate)
    ShopAbilities.start(abilityFrame, itemTemplate , ShopMain.missingFunds)
    ShopShovels.start(shovelsFrame, itemTemplate ,  ShopMain.missingFunds)
    ShopCoins.start(coinsFrame, itemTemplate)
    ShopGamepass.start(gamepassFrame, itemTemplate)

    RunService:BindToRenderStep("autoClosePopup", Enum.RenderPriority.Last.Value, function()
        
        if missingFundsFrame.Visible then

            local timeLeft = math.floor(math.max(0, AUTO_HIDE_SECONDS - (os.clock() - missingFundsOpen)) + 1)
            
            missingFundsFrame.Window.AutoClosing.Text = "Auto closing in " .. tostring(timeLeft) .. "s"
            if os.clock() - missingFundsOpen >= AUTO_HIDE_SECONDS then
                missingFundsFrame.Visible = false
            end

        end

    end)

    missingFundsFrame.Window.NoButton.Clickable.Activated:Connect(function()
        missingFundsFrame.Visible = false
    end)

    missingFundsFrame.Window.YesButton.Clickable.Activated:Connect(function()
        missingFundsFrame.Visible = false
        ShopMain.setFrame(coinsFrame, "Coins")
    end)

    initialized = true
    ShopMain.setFrame(shovelsFrame, "Shovels")

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

function ShopMain.openAbilitiesFrame()
    if shopGui and abilityFrame then
        print("lol")
        ShopMain.setFrame(abilityFrame, "Abilities")
        ShopMain.show()
    end
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
