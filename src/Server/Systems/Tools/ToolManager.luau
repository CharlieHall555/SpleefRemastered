local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)

local shovelsFolder = game:GetService("ServerStorage"):WaitForChild("Shovels")
local snowballToolTemplate = game:GetService("ServerStorage"):WaitForChild("Snowball") :: Tool
local backShovelsFolder = game:GetService("ServerStorage"):WaitForChild("BackShovels")

local ToolManager = {}

local TOOL_SHOVEL_NAME = "Shovel"
local TOOL_SNOWBALL_NAME = "Snowball"
local DEFAULT_SHOVEL_VARIANT = "DEFAULT"

local BACK_SHOVEL_NAME = "BackShovel"
local BACK_SHOVEL_TAG = "IsBackShovel"
local BACK_SHOVEL_VARIANT_ATTR = "VariantName"

local characterAddedConnections: { [number]: RBXScriptConnection } = {}

local function getShovelName(player: Player): string
    local name = PlayerData.getShovel(player)
    if type(name) ~= "string" or not shovelsFolder:FindFirstChild(name) then
        return DEFAULT_SHOVEL_VARIANT
    end
    return name
end

local function getBackpack(player: Player): Backpack?
    return player:FindFirstChildOfClass("Backpack")
end

local function collectTools(player: Player, toolName: string): { Tool }
    local found: { Tool } = {}
    local bp = getBackpack(player)
    local char = player.Character

    if char then
        for _, inst in ipairs(char:GetChildren()) do
            if inst:IsA("Tool") and inst.Name == toolName then
                table.insert(found, inst)
            end
        end
    end

    if bp then
        for _, inst in ipairs(bp:GetChildren()) do
            if inst:IsA("Tool") and inst.Name == toolName then
                table.insert(found, inst)
            end
        end
    end

    return found
end

local function removeExtrasKeepOne(player: Player, tools: { Tool })
    if #tools <= 1 then
        return
    end

    local keep: Tool? = nil
    local char = player.Character

    if char then
        for _, t in ipairs(tools) do
            if t.Parent == char then
                keep = t
                break
            end
        end
    end
    if not keep then
        keep = tools[1]
    end

    for _, t in ipairs(tools) do
        if t ~= keep and t.Parent ~= nil then
            t:Destroy()
        end
    end
end

local function collectBackShovelAccessories(player: Player): { Accessory }
    local char = player.Character
    local found: { Accessory } = {}
    if not char then
        return found
    end
    for _, inst in ipairs(char:GetChildren()) do
        if inst:IsA("Accessory") then
            local acc = inst :: Accessory
            if acc.Name == BACK_SHOVEL_NAME or acc:GetAttribute(BACK_SHOVEL_TAG) == true then
                table.insert(found, acc)
            end
        end
    end
    return found
end

local function removeExtraAccessoriesKeepOne(accessories: { Accessory })
    if #accessories <= 1 then
        return accessories[1]
    end
    local keep = accessories[1]
    for i = 2, #accessories do
        if accessories[i].Parent ~= nil then
            accessories[i]:Destroy()
        end
    end
    return keep
end

local function ensureSnowball(player: Player)
    local existing = collectTools(player, TOOL_SNOWBALL_NAME)
    if #existing == 0 then
        local bp = getBackpack(player)
        if bp and snowballToolTemplate and snowballToolTemplate:IsA("Tool") then
            local clone = snowballToolTemplate:Clone()
            clone.Name = TOOL_SNOWBALL_NAME
            clone.Parent = bp
        end
    else
        removeExtrasKeepOne(player, existing)
    end
end

local function getShovelTemplateFor(player: Player): Tool?
    local variantName = getShovelName(player)
    local template = shovelsFolder:FindFirstChild(variantName)
    if not template or not template:IsA("Tool") then
        template = shovelsFolder:FindFirstChild(DEFAULT_SHOVEL_VARIANT)
    end
    if template and template:IsA("Tool") then
        return template
    end
    warn("Shovel template missing for variant:", variantName)
    return nil
end

local function getBackShovelTemplateFor(player: Player): Accessory?
    local variantName = getShovelName(player)
    local template = backShovelsFolder:FindFirstChild(variantName)
    if not template or not template:IsA("Accessory") then
        template = backShovelsFolder:FindFirstChild(DEFAULT_SHOVEL_VARIANT)
    end
    if template and template:IsA("Accessory") then
        return template
    end
    warn("BackShovel accessory missing for variant:", variantName)
    return nil
end

local function ensureShovel(player: Player)
    local existing = collectTools(player, TOOL_SHOVEL_NAME)
    if #existing == 0 then
        local bp = getBackpack(player)
        local template = getShovelTemplateFor(player)
        if bp and template then
            local clone = template:Clone()
            clone.Name = TOOL_SHOVEL_NAME
            clone.Parent = bp
        end
    else
        removeExtrasKeepOne(player, existing)
    end
end

local function ensureBackShovel(player: Player)
    local char = player.Character
    if not char then
        return
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local variantName = getShovelName(player)
    local desired = getBackShovelTemplateFor(player)
    if not desired then
        return
    end

    local existing = collectBackShovelAccessories(player)
    local keep = removeExtraAccessoriesKeepOne(existing)

    if keep and keep:GetAttribute(BACK_SHOVEL_VARIANT_ATTR) == variantName then
        -- already correct
        return
    end

    if keep then
        keep:Destroy()
        keep = nil
    end

    local clone = desired:Clone()
    clone.Name = BACK_SHOVEL_NAME
    clone:SetAttribute(BACK_SHOVEL_TAG, true)
    clone:SetAttribute(BACK_SHOVEL_VARIANT_ATTR, variantName)
    humanoid:AddAccessory(clone)
end

local function onCharacterAdded(player: Player)
    ToolManager.ensureTool(player)
end

function ToolManager.init()
    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        characterAddedConnections[player.UserId] = player.CharacterAdded:Connect(function()
            onCharacterAdded(player)
        end)
        ToolManager.ensureTool(player)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        local conn = characterAddedConnections[player.UserId]
        if conn then
            conn:Disconnect()
            characterAddedConnections[player.UserId] = nil
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if not characterAddedConnections[player.UserId] then
            characterAddedConnections[player.UserId] = player.CharacterAdded:Connect(function()
                onCharacterAdded(player)
            end)
        end
        ToolManager.ensureTool(player)
    end
end

function ToolManager.ensureTools(playerList: { Player })
    for _, player in ipairs(playerList) do
        ToolManager.ensureTool(player)
    end
end

function ToolManager.ensureTool(player: Player)
    ensureShovel(player)
    ensureSnowball(player)
    ensureBackShovel(player)
end

function ToolManager.refreshTool(player: Player)
    local shovelInstances = collectTools(player, TOOL_SHOVEL_NAME)
    for _, t in ipairs(shovelInstances) do
        if t.Parent ~= nil then
            t:Destroy()
        end
    end
    local backAccs = collectBackShovelAccessories(player)
    for _, a in ipairs(backAccs) do
        if a.Parent ~= nil then
            a:Destroy()
        end
    end

    ensureShovel(player)
    ensureBackShovel(player)
end

return ToolManager
