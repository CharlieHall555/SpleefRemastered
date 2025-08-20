local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ToolManager = {}

local TOOL_NAME = "Shovel"

local _shovelTemplate: Tool? = nil
local _characterAddedConnections: { [number]: RBXScriptConnection } = {}
local _backpackRemovedConnections: { [number]: RBXScriptConnection } = {}
local _characterRemovedConnections: { [number]: RBXScriptConnection } = {}
local _playerChildAddedConnections: { [number]: RBXScriptConnection } = {}
local _playerChildRemovedConnections: { [number]: RBXScriptConnection } = {}

local function getToolTemplate(): Tool
    if not _shovelTemplate or _shovelTemplate.Parent == nil then
        local serverStorage = game:GetService("ServerStorage")
        local shovelsFolder = serverStorage:WaitForChild("Shovels")
        _shovelTemplate = shovelsFolder:WaitForChild(TOOL_NAME, 4) :: Tool
        assert(_shovelTemplate, TOOL_NAME .. " template missing in ServerStorage/Shovels")
    end
    return _shovelTemplate
end

local function containerHasTool(container: Instance?): boolean
    if not container then
        return false
    end
    return container:FindFirstChild(TOOL_NAME) ~= nil
end

local function playerHasToolAnywhere(player: Player): boolean
    if not player or not player.Parent then
        return false
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    if containerHasTool(backpack) then
        return true
    end
    if containerHasTool(character) then
        return true
    end
    return false
end

local function ensureTool(player: Player)
    if not player or not player.Parent then
        return
    end
    if playerHasToolAnywhere(player) then
        return
    end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack == nil then
        return
    end
    local tool = getToolTemplate():Clone()
    tool.Parent = backpack
end

local function disconnectForPlayer(map: { [number]: RBXScriptConnection }, userId: number)
    local conn = map[userId]
    if conn then
        conn:Disconnect()
        map[userId] = nil
    end
end

local function hookBackpack(player: Player)
    local userId = player.UserId
    disconnectForPlayer(_backpackRemovedConnections, userId)

    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then
        return
    end

    _backpackRemovedConnections[userId] = backpack.ChildRemoved:Connect(function(child)
        if child.Name == TOOL_NAME then
            task.defer(function()
                -- If it moved to Character, do nothing; otherwise restore.
                if not playerHasToolAnywhere(player) then
                    ensureTool(player)
                end
            end)
        end
    end)
end

local function hookCharacter(player: Player)
    local userId = player.UserId
    disconnectForPlayer(_characterRemovedConnections, userId)

    local character = player.Character
    if not character then
        return
    end

    _characterRemovedConnections[userId] = character.ChildRemoved:Connect(function(child)
        if child.Name == TOOL_NAME then
            task.defer(function()
                -- If it moved back to Backpack, do nothing; otherwise restore.
                if not playerHasToolAnywhere(player) then
                    ensureTool(player)
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
                ensureTool(player)
            end)
        elseif child:IsA("Model") and child.Name == player.Name then
            hookCharacter(player)
            task.defer(function()
                ensureTool(player)
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

function ToolManager.init()
    getToolTemplate()

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        hookPlayerContainersAppear(player)

        _characterAddedConnections[player.UserId] = player.CharacterAdded:Connect(function()
            task.defer(function()
                hookCharacter(player)
                ensureTool(player)
            end)
        end)

        task.defer(function()
            hookBackpack(player)
            hookCharacter(player)
            ensureTool(player)
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

--[[function ToolManager.onLoaded()
    local serverStorage = game:GetService("ServerStorage")
    local shovelsFolder = serverStorage:WaitForChild("Shovels")
    _shovelTemplate = shovelsFolder:WaitForChild("Shovel" , 4) :: Tool
    assert(_shovelTemplate, "BasicShovel template missing in ServerStorage/Shovels")
end

function ToolManager.giveTools(players: {Player}): nil
    assert(_shovelTemplate, "ToolManager not loaded. Call onLoaded() first.")
    for _, player in ipairs(players) do
        if player and player.Parent then
            local backpack = player:FindFirstChildOfClass("Backpack")
            if backpack and not backpack:FindFirstChild(_shovelTemplate.Name) then
                local tool = _shovelTemplate:Clone()
                tool.Parent = backpack
                table.insert(_handedOutTools, tool)
            end
        end
    end
end

function ToolManager.reset(): nil
    for i = #_handedOutTools, 1, -1 do
        local tool = _handedOutTools[i]
        if tool and tool.Parent then
            tool:Destroy()
        end
        _handedOutTools[i] = nil
    end
end]]

