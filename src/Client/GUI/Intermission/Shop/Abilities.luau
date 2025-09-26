-- ShopAbilities.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ShopItem = require(ClientModuleDirectory.ShopItem)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local TextUtilities = require(ClientModuleDirectory.TextUtilities)

local AbilitiesData = require(ClientModuleDirectory.AbilitiesData)

local LocalPlayer = Players.LocalPlayer

local ShopAbilities = {}

-- State
local abilitiesFrame: Frame
local itemTemplate: Frame
local cachedItems: { ShopItem.ShopItem }? = nil

local coinLabel : TextLabel
local abilityLabel : TextLabel

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

local function buildItemCard(item: ShopItem.ShopItem): Frame
    local card = itemTemplate:Clone()

    if table.find(UserProfile.getValue("abilities") or {}, item.name) then
        card.Price.Text = "Owned"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = true
    else
        card.Price.Text = tostring(item.cost) .. "C"
        card.Price.TextColor3 = Color3.fromRGB(255, 205, 23)
        card.BuyButton.Visible = true
        card.EquipButton.Visible = false
    end

    card.NameLabel.Text = item.displayName
    card.Name = repeatChar("a", item.cost)
    card.Visible = true
    return card
end

local function loadItems()
    if not abilitiesFrame or not itemTemplate then
        return
    end

    local list = abilitiesFrame:WaitForChild("ScrollingFrame")
    clearChildren(list)

    local source = cachedItems or AbilitiesData

    local order = 0
    for _, item: ShopItem.ShopItem in source do
        order += 1
        local card = buildItemCard(item)
        card.LayoutOrder = order
        card.Parent = list
    end
end

function ShopAbilities.start(frame: Frame, template: Frame)
    abilitiesFrame = frame
    itemTemplate = template
    coinLabel = abilitiesFrame:WaitForChild("Coins")
    abilityLabel = abilitiesFrame:WaitForChild("Equipped")



    coinLabel.Text = "Coins: " ..TextUtilities.formatCurrency(UserProfile.getValue("coins") or 0).."C"
    abilityLabel.Text = "Equipped: " .. (UserProfile.getValue("ability") or "None")
    loadItems()

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        abilityLabel.Text = "Equipped: " .. (newValue or "None")
    end , "ability")

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        coinLabel.Text = "Coins: " ..TextUtilities.formatCurrency(newValue or 0).."C"
    end , "coins")

    
end

-- If you want to supply items at runtime

function ShopAbilities.refresh()
    loadItems()
end

return ShopAbilities
