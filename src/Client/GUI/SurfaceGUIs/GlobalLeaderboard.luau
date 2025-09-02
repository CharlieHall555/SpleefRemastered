local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local GUI_ASSETS = ReplicatedStorage:WaitForChild("GuiAssets")
local SPIN_TIME = 1

-- locals as module state
local adornee: BasePart?
local leaderboard: SurfaceGui?
local template: Frame?
local loadingScreen: Frame?
local spinner: ImageLabel?
local leaderboardScreen: Frame?
local spinTween: Tween?
local updateConn: RBXScriptConnection?

local GlobalLeaderboard = {}

local function safeJsonDecode(payload: any): any?
    if typeof(payload) ~= "string" or payload == "" then
        return nil
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(payload)
    end)
    if ok and typeof(decoded) == "table" then
        return decoded
    end
    return nil
end

local function setLoadingVisible(isVisible: boolean)
    if loadingScreen then
        loadingScreen.Visible = isVisible
    end
    if leaderboardScreen then
        leaderboardScreen.Visible = not isVisible
    end
    if isVisible then
        if spinner and not spinTween then
            spinner.Rotation = 0
            spinTween = TweenService:Create(
                spinner,
                TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
                { Rotation = 360 }
            )
            spinTween:Play()
        end
    else
        if spinTween then
            spinTween:Cancel()
            spinTween = nil
        end
    end
end

local function clearList()
    if not leaderboardScreen then
        return
    end
    local frame = leaderboardScreen:FindFirstChild("ScrollingFrame")
    if not frame or not frame:IsA("ScrollingFrame") then
        return
    end
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("Frame") and child ~= template then
            child:Destroy()
        end
    end
end

local function populate(data: { [number]: { [string]: any } }?)
    if not template or not leaderboardScreen then
        return
    end
    local frame = leaderboardScreen:FindFirstChild("ScrollingFrame")
    if not frame or not frame:IsA("ScrollingFrame") then
        return
    end
    clearList()
    if typeof(data) ~= "table" then
        return
    end

    for place, playerData in ipairs(data) do
        local clone = template:Clone()
        clone.Name = "Entry"
        clone.Visible = true

        local placeLabel = clone:FindFirstChild("Place")
        local nameLabel = clone:FindFirstChild("PlayerName")
        local winsLabel = clone:FindFirstChild("Wins")

        if placeLabel and placeLabel:IsA("TextLabel") then
            placeLabel.Text = tostring(place)
        end
        if nameLabel and nameLabel:IsA("TextLabel") then
            nameLabel.Text = tostring(playerData.playerName or "")
        end
        if winsLabel and winsLabel:IsA("TextLabel") then
            winsLabel.Text = tostring(playerData.win or 0)
        end

        clone.Parent = frame
    end
end

function GlobalLeaderboard.onProfileLoaded()
    local assetsFolder = GUI_ASSETS:FindFirstChild("LobbyGUIs")
    if not assetsFolder then
        return
    end

    local leaderboardGui = assetsFolder:FindFirstChild("Leaderboard")
    if not leaderboardGui or not leaderboardGui:IsA("SurfaceGui") then
        return
    end

    local adorneePart = workspace:FindFirstChild("LeaderboardPanel")
    if adorneePart and adorneePart:IsA("BasePart") then
        adornee = adorneePart
    end

    leaderboard = leaderboardGui:Clone()
    leaderboard.Adornee = adornee
    leaderboard.Enabled = true
    leaderboard.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local main = leaderboard:FindFirstChild("Main")
    if not main or not main:IsA("Frame") then
        return
    end

    loadingScreen = main:FindFirstChild("Loading") :: Frame?
    leaderboardScreen = main:FindFirstChild("Leaderboard") :: Frame?
    if loadingScreen then
        spinner = loadingScreen:FindFirstChild("Spinner") :: ImageLabel?
    end
    if leaderboardScreen then
        local sf = leaderboardScreen:FindFirstChild("ScrollingFrame")
        if sf and sf:IsA("ScrollingFrame") then
            local t = sf:FindFirstChild("Template")
            if t and t:IsA("Frame") then
                template = t
                template.Visible = false
            end
        end
    end

    if leaderboardScreen then
        leaderboardScreen.Visible = false
    end
    setLoadingVisible(true)

    local reply = RemoteEventHandler.InvokeOnServer("QUERY_GLOBAL_LEADERBOARD", 5)
    local decoded = safeJsonDecode(reply)
    if decoded and typeof(decoded.global) == "table" then
        populate(decoded.global)
    end

    setLoadingVisible(false)

    if updateConn then
        updateConn:Disconnect()
        updateConn = nil
    end
    updateConn = RemoteEventHandler.newEventConnection("GLOBAL_LEADERBOARD_UPDATE", function(newData)
        local upd = safeJsonDecode(newData)
        if upd and typeof(upd.global) == "table" then
            populate(upd.global)
        end
    end)

    if leaderboard and not leaderboard.Adornee then
        leaderboard.Enabled = true
        leaderboard.Adornee = nil
    end
end

function GlobalLeaderboard.destroy()
    if updateConn then
        updateConn:Disconnect()
        updateConn = nil
    end
    if spinTween then
        spinTween:Cancel()
        spinTween = nil
    end
    if leaderboard then
        leaderboard:Destroy()
        leaderboard = nil
    end
    adornee = nil
    template = nil
    loadingScreen = nil
    spinner = nil
    leaderboardScreen = nil
end

return GlobalLeaderboard
