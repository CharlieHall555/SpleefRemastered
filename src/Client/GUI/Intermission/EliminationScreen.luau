local EliminationScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local GuiAssets = ReplicatedStorage:WaitForChild("GuiAssets")

local AUTO_HIDE_SECONDS = 9

-- internal state
local didInit = false
local showToken = 0
local spectateTimer = AUTO_HIDE_SECONDS

-- ui refs (kept outside the module table as requested)
local frame: Frame?
local closeButton: TextButton?
local spectateButton: TextButton?
local spectateLocked: Frame?
local timerLabel: TextLabel?
local deathLabel: TextLabel?


-- helpers
local function getScreenFrame(): Frame
    local intermission = GuiAssets:WaitForChild("Intermission")
    if PlatformDetector.getPlatform() == "MOBILE" then
        return intermission:WaitForChild("MobileEliminationScreen") :: Frame
    else
        return intermission:WaitForChild("EliminationScreen") :: Frame
    end
end

local function updateLockByState()
    local isActive = ClientStateTracker.getServerState() == "ACTIVE"
    if spectateLocked then
        spectateLocked.Visible = not isActive
    end
end

local function resetScreen()
    spectateTimer = AUTO_HIDE_SECONDS
    if timerLabel then
        timerLabel.Text = ""
    end
    if deathLabel then
        deathLabel.Text = ""
    end
    if spectateLocked then
        spectateLocked.Visible = false
    end
end

local onSpectatePressed : (() -> ()) = nil

-- public api
function EliminationScreen.onProfileLoaded()
    if didInit then
        return
    end
    didInit = true

    frame = getScreenFrame()
    closeButton = frame:WaitForChild("CloseButton").Clickable :: TextButton
    spectateButton = frame:WaitForChild("SpectateButton").Clickable :: TextButton
    spectateLocked = frame:WaitForChild("SpectateButton").LockedScreen :: Frame
    timerLabel = frame:WaitForChild("Timer") :: TextLabel
    deathLabel = frame:WaitForChild("DeathLabel")

    frame.Parent = Screens.intermissionHUD
    frame.Visible = false

    resetScreen()
    updateLockByState()

    closeButton.Activated:Connect(function()
        EliminationScreen.hide()
    end)

    -- Intentionally not wiring spectate action here (external code will handle)
    spectateButton.Activated:Connect(function()
        if onSpectatePressed then
            EliminationScreen.hide()
            onSpectatePressed()
        end
    end)

    ClientStateTracker.connectServerStateChange(function()
        updateLockByState()
    end)

end



function EliminationScreen.setOnSpectatePressed(fn : () -> ())
    onSpectatePressed = fn  
end

function EliminationScreen.hide()
    showToken += 1
    if frame then
        frame.Visible = false
    end
    resetScreen()
end

function EliminationScreen.show(playerWhoDied: Player, eliminator: Player?)
    local myToken = showToken + 1
    showToken = myToken

    if frame then
        frame.Visible = true
    end

    if playerWhoDied and eliminator and deathLabel then
        deathLabel.Text = "Eliminated by " .. eliminator.DisplayName .. "!"
    elseif deathLabel then
        deathLabel.Text = "You fell!"
    end

    updateLockByState()

    task.spawn(function()
        while spectateTimer > 0 and showToken == myToken do
            spectateTimer -= 1
            if timerLabel then
                timerLabel.Text = "Closing in " .. spectateTimer .. " s"
            end
            task.wait(1)
        end
        if showToken == myToken then
            EliminationScreen.hide()
        end
    end)

end

return EliminationScreen
