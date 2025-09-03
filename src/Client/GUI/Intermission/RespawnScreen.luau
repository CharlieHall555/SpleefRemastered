local RespawnScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local ProductList = require(ClientModuleDirectory.ProductList)

local GuiAssets = ReplicatedStorage:WaitForChild("GuiAssets")

local spectateTimer = 5

local AUTO_HIDE_SECONDS = 9

local respawnScreenFrame: Frame?
local closeButton: TextButton?
local respawnButton: TextButton?
local respawnLockedFrame: Frame?
local respawnInfoFrame: Frame?
local deathLabel: TextLabel?
local spectateTimerLabel: TextLabel?

local _didInit = false
local _showToken = 0

local function getScreenFrame(): Frame
    local intermission = GuiAssets:WaitForChild("Intermission")
    if PlatformDetector.getPlatform() == "MOBILE" then
        return intermission:WaitForChild("MobileRespawnScreen") :: Frame
    else
        return intermission:WaitForChild("RespawnScreen") :: Frame
    end
end

local function resetScreen()
    spectateTimer = AUTO_HIDE_SECONDS
    if deathLabel then
        deathLabel.Text = ""
    end
    if spectateTimerLabel then
        spectateTimerLabel.Text = ""
    end
    if respawnLockedFrame then
        respawnLockedFrame.Visible = false
    end
    if respawnInfoFrame then
        respawnInfoFrame.Visible = true
    end
end

local function hideFrame()
    if respawnScreenFrame then
        respawnScreenFrame.Visible = false
    end
end

local function showFrame()
    if respawnScreenFrame then
        respawnScreenFrame.Visible = true
    end
end


local function onCloseButton()
    RespawnScreen.hide()
end

local function onRespawnButton()
    RespawnScreen.hide()
    local lives = tonumber(UserProfile.getValue("respawns")) or 0
    if lives > 0 then
        RemoteEventHandler.FireOnServer("REQUEST_RESPAWN")
        print("REQUEST!")
    else
        if ProductList and ProductList.ImmediateRespawn then
            MarketplaceService:PromptProductPurchase(LocalPlayer, ProductList.ImmediateRespawn)
        end
    end
end

local function canShowRespawnScreen(): boolean
    local state = ClientStateTracker.getServerState()
    return state == "ACTIVE"
end

function RespawnScreen.onProfileLoaded()
    if _didInit then
        return
    end
    _didInit = true

    respawnScreenFrame = getScreenFrame()
    closeButton = respawnScreenFrame:WaitForChild("CloseButton").Clickable :: TextButton
    respawnButton = respawnScreenFrame:WaitForChild("RespawnButton").Clickable :: TextButton
    respawnLockedFrame = respawnScreenFrame:WaitForChild("RespawnButton").LockedScreen
    respawnInfoFrame = respawnScreenFrame:WaitForChild("RespawnInfo")
    deathLabel = respawnScreenFrame:WaitForChild("DeathLabel")
    spectateTimerLabel = respawnScreenFrame:WaitForChild("SpectatingTimer")

    respawnScreenFrame.Parent = Screens.intermissionHUD
    respawnScreenFrame.Visible = false

    resetScreen()

    closeButton.Activated:Connect(onCloseButton)
    respawnButton.Activated:Connect(onRespawnButton)
end

function RespawnScreen.hide()
    _showToken += 1
    hideFrame()
    resetScreen()
end

function RespawnScreen.show(playerWhoDied: Player, eliminator: Player?)
    local myToken = _showToken + 1
    _showToken = myToken

    if not canShowRespawnScreen() then
        return
    end

    if playerWhoDied and eliminator and deathLabel then
        deathLabel.Text = "Eliminated by " .. eliminator.DisplayName .. "!"
    elseif deathLabel then
        deathLabel.Text = "You fell!"
    end

    local lives = tonumber(UserProfile.getValue("respawns")) or 0
    respawnInfoFrame.RemainingLivesCounter.Text = "Remaining: " .. tostring(lives)

    showFrame()

    spectateTimer = AUTO_HIDE_SECONDS
    task.spawn(function()
        while spectateTimer > 0 and _showToken == myToken do
            spectateTimer -= 1
            if spectateTimerLabel then
                spectateTimerLabel.Text = "Closing in " .. spectateTimer .. " s"
            end
            task.wait(1)
        end
        if _showToken == myToken then
            RespawnScreen.hide()
        end
    end)
end

return RespawnScreen
