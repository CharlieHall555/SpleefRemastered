local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ToolManager = {}

-- Tools we want every player to own
local TOOL_NAMES: {string} = { "Shovel", "Snowball" }

-- Folder where your Shovel currently lives; we’ll fetch Snowball from here too (same place)
local TOOL_FOLDER_PATH = { "ServerStorage", "Shovels" }

-- Caches
local _toolTemplates: { [string]: Tool } = {}
local _characterAddedConnections: { [number]: RBXScriptConnection } = {}
local _backpackRemovedConnections: { [number]: RBXScriptConnection } = {}
local _characterRemovedConnections: { [number]: RBXScriptConnection } = {}
local _playerChildAddedConnections: { [number]: RBXScriptConnection } = {}
local _playerChildRemovedConnections: { [number]: RBXScriptConnection } = {}

-- Utils
local function getToolFolder(): Instance
    local serverStorage = game:GetService("ServerStorage")
    local folder = serverStorage:WaitForChild("Shovels") -- same place as Shovel
    return folder
end

local function getToolTemplate(toolName: string): Tool
    local cached = _toolTemplates[toolName]
    if cached and cached.Parent ~= nil then
        return cached
    end
    local folder = getToolFolder()
    local tool = folder:WaitForChild(toolName, 4) :: Tool
    assert(tool, toolName .. " template missing in ServerStorage/Shovels")
    _toolTemplates[toolName] = tool
    return tool
end

local function containerHasTool(container: Instance?, toolName: string): boolean
    if not container then return false end
    return container:FindFirstChild(toolName) ~= nil
end

local function playerHasTool(player: Player, toolName: string): boolean
    if not player or not player.Parent then return false end
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    if containerHasTool(backpack, toolName) then return true end
    if containerHasTool(character, toolName) then return true end
    return false
end

local function playerHasAllTools(player: Player): boolean
    for _, name in ipairs(TOOL_NAMES) do
        if not playerHasTool(player, name) then
            return false
        end
    end
    return true
end

local function ensureToolInternal(player: Player, toolName: string)
    if not player or not player.Parent then return end
    if playerHasTool(player, toolName) then return end

    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack == nil then return end

    local tool = getToolTemplate(toolName):Clone()
    tool.Parent = backpack
end

local function ensureAllToolsInternal(player: Player)
    if not player or not player.Parent then return end
    for _, toolName in ipairs(TOOL_NAMES) do
        ensureToolInternal(player, toolName)
    end
end

local function disconnectForPlayer(map: { [number]: RBXScriptConnection }, userId: number)
    local conn = map[userId]
    if conn then
        conn:Disconnect()
        map[userId] = nil
    end
end

local function isManagedToolName(name: string): boolean
    for _, t in ipairs(TOOL_NAMES) do
        if t == name then return true end
    end
    return false
end

local function hookBackpack(player: Player)
    local userId = player.UserId
    disconnectForPlayer(_backpackRemovedConnections, userId)

    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then return end

    _backpackRemovedConnections[userId] = backpack.ChildRemoved:Connect(function(child)
        if isManagedToolName(child.Name) then
            task.defer(function()
                -- Only re-add if it truly doesn't exist anywhere
                if not playerHasTool(player, child.Name) then
                    ensureToolInternal(player, child.Name)
                end
            end)
        end
    end)
end

local function hookCharacter(player: Player)
    local userId = player.UserId
    disconnectForPlayer(_characterRemovedConnections, userId)

    local character = player.Character
    if not character then return end

    _characterRemovedConnections[userId] = character.ChildRemoved:Connect(function(child)
        if isManagedToolName(child.Name) then
            task.defer(function()
                if not playerHasTool(player, child.Name) then
                    ensureToolInternal(player, child.Name)
                end
            end)
        end
    end)
end

local function hookPlayerContainersAppear(player: Player)
    local userId = player.UserId

    disconnectForPlayer(_playerChildAddedConnections, userId)
    disconnectForPlayer(_playerChildRemovedConnections, userId)

    _playerChildAddedConnections[userId] = player.ChildAdded:Connect(function(child)
        if child:IsA("Backpack") then
            hookBackpack(player)
            task.defer(function()
                ensureAllToolsInternal(player)
            end)
        elseif child:IsA("Model") and child.Name == player.Name then
            hookCharacter(player)
            task.defer(function()
                ensureAllToolsInternal(player)
            end)
        end
    end)

    _playerChildRemovedConnections[userId] = player.ChildRemoved:Connect(function(child)
        if child:IsA("Backpack") then
            disconnectForPlayer(_backpackRemovedConnections, userId)
        elseif child:IsA("Model") and child.Name == player.Name then
            disconnectForPlayer(_characterRemovedConnections, userId)
        end
    end)
end

-- Public: ensures ALL managed tools (Shovel + Snowball)
function ToolManager.ensureTool(player: Player): nil
    -- Preload templates so any asserts happen up-front
    for _, name in ipairs(TOOL_NAMES) do
        getToolTemplate(name)
    end
    ensureAllToolsInternal(player)
end

function ToolManager.init()
    -- Preload templates early
    for _, name in ipairs(TOOL_NAMES) do
        getToolTemplate(name)
    end

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        hookPlayerContainersAppear(player)

        _characterAddedConnections[player.UserId] = player.CharacterAdded:Connect(function()
            task.defer(function()
                hookCharacter(player)
                ensureAllToolsInternal(player)
            end)
        end)

        task.defer(function()
            hookBackpack(player)
            hookCharacter(player)
            ensureAllToolsInternal(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        local userId = player.UserId
        disconnectForPlayer(_characterAddedConnections, userId)
        disconnectForPlayer(_backpackRemovedConnections, userId)
        disconnectForPlayer(_characterRemovedConnections, userId)
        disconnectForPlayer(_playerChildAddedConnections, userId)
        disconnectForPlayer(_playerChildRemovedConnections, userId)
    end)
end

return ToolManager
