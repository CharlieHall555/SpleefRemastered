-- ShopAbilities.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local TextUtilities = require(ClientModuleDirectory.TextUtilities)

local ShovelsData = require(ClientModuleDirectory.ShovelsData)

local buttonConnections = {}

local LocalPlayer = Players.LocalPlayer

local ShopShovels = {}

-- State
local shovelsFrame: Frame
local itemTemplate: Frame
local cachedItems: { ShovelsData.ShovelDefinition }? = nil

local coinLabel : TextLabel
local shovelLabel : TextLabel

local function repeatChar(char: string, count: number): string
    if not char or char == "" or count <= 0 then
        return ""
    end
    return string.rep(char, count)
end

local function clearChildren(parent: Instance)
    for _, child in ipairs(parent:GetChildren()) do
        if child ~= itemTemplate and child:IsA("Frame") then
            child:Destroy()
        end
    end
end

local function buildItemCard(item: ShovelsData.ShovelDefinition): Frame
    local card = itemTemplate:Clone()

    local equippedShovel = UserProfile.getValue("shovel") or ""
   
    if item.name == equippedShovel then
        card.Price.Text = "Equipped"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = false
        card.EquippedBadge.Visible = true
        card.ImageLabel.Image = item.image
    elseif table.find(UserProfile.getValue("shovels") or {}, item.name) then
        card.Price.Text = "Owned"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = true
        card.EquippedBadge.Visible = false
        card.ImageLabel.Image = item.image
    elseif item.canBuy == false then
        card.Price.Text = "Locked"
        card.Price.TextColor3 = Color3.fromRGB(220, 7, 7)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = false
        card.EquippedBadge.Visible = false
        card.ImageLabel.Image = item.image
        if item.passLink then
            card.BuyButton.Visible = true
            card.BuyButton.TextLabel.Text = "Get Pass"
        end
    else
        card.Price.Text = tostring(item.cost) .. "C"
        card.Price.TextColor3 = Color3.fromRGB(255, 205, 23)
        card.BuyButton.Visible = true
        card.EquipButton.Visible = false
        card.EquippedBadge.Visible = false
        card.ImageLabel.Image = item.image
    end

    local connection = card.BuyButton.Clickable.Activated:Connect(function()
        print("lol")
        if item.passLink then
            local success, message = pcall(function()
                MarketplaceService:PromptGamePassPurchase(LocalPlayer, item.passLink)
            end)
            return
        elseif item.canBuy == false then
            return
        end
        RemoteEventHandler.FireOnServer("REQUEST_BUY_SHOVEL", item.name)
    end)
    table.insert(buttonConnections, connection)

    local connection = card.EquipButton.Clickable.Activated:Connect(function()
        RemoteEventHandler.FireOnServer("REQUEST_EQUIP_SHOVEL", item.name)
    end)
    table.insert(buttonConnections, connection)

    card.NameLabel.Text = item.displayName
    card.Name = repeatChar("a", item.cost)
    card.Visible = true
    return card
end

local function loadItems()
    if not shovelsFrame or not itemTemplate then
        return
    end

    local list = shovelsFrame:WaitForChild("ScrollingFrame")
    clearChildren(list)
    for _, connection in buttonConnections do
        connection:Disconnect()
    end

    local source = cachedItems or ShovelsData

    local order = 0
    for _, item: ShovelsData.ShovelDefinition in source do
        if item.showInShop == false then
            continue
        end
        order += 1
        pcall(function()
            local card = buildItemCard(item)
            card.LayoutOrder = order
            card.Parent = list
        end)
    end
end

function ShopShovels.start(frame: Frame, template: Frame)
    shovelsFrame = frame
    itemTemplate = template
    coinLabel = shovelsFrame:WaitForChild("Coins")
    shovelLabel = shovelsFrame:WaitForChild("Equipped")

    coinLabel.Text = "Coins: " ..TextUtilities.formatCurrency(UserProfile.getValue("coins") or 0).."C"
    shovelLabel.Text = "Equipped: " .. tostring(UserProfile.getValue("shovel") or "None")
    loadItems()

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        shovelLabel.Text = "Equipped: " .. tostring(newValue or "None")
    end , "shovel")

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        coinLabel.Text = "Coins: " ..TextUtilities.formatCurrency(newValue or 0).."C"
    end , "coins")

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        loadItems()
    end , "shovels")

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        loadItems()
    end , "shovel")
    
end

-- If you want to supply items at runtime

function ShopShovels.refresh()
    loadItems()
end

return ShopShovels
