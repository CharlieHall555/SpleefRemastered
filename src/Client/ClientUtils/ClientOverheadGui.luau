local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local guiName = "OverheadNametag"

local characterConnections = {}

local ClientOverheadGui = {}

local function hideOverhead(gui : BillboardGui)
    gui.Enabled = false
end

local function showOverhead(gui : BillboardGui)
    gui.Enabled = true
end

local function hideAll()
    for _, player in ipairs(game.Players:GetPlayers()) do
        local char = player.Character
        if char then
            local gui = char:FindFirstChild(guiName)
            if gui then
                hideOverhead(gui)
            end
        end
    end
end

local function showAll()
    for _, player in ipairs(game.Players:GetPlayers()) do
        local char = player.Character
        if char then
            local gui = char:FindFirstChild(guiName)
            if gui then
                showOverhead(gui)
            end
        end
    end
end

local function onNewCharacterAdded(player : Player, char : Model)
    local gui = char:WaitForChild(guiName, 5)
    if gui then
        if ClientStateTracker.inGame() then
            showOverhead(gui)
        else
            hideOverhead(gui)
        end
    end
end

function ClientOverheadGui.init()

    Players.PlayerAdded:Connect(function(player)
        local connection = player.CharacterAdded:Connect(function(char)
            onNewCharacterAdded(player, char)
        end)
        table.insert(characterConnections, connection)
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        local connection = player.CharacterAdded:Connect(function(char)
            onNewCharacterAdded(player, char)
        end)
        table.insert(characterConnections, connection)
    end

end

return ClientOverheadGui    