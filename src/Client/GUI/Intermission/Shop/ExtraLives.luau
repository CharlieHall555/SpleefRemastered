-- ShopExtraLives.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local ShopItem = require(ClientModuleDirectory.ShopItem)

-- Data source of purchasable extra lives (array of ShopItem.ShopItem)
local ExtraLivesData = require(ClientModuleDirectory.ExtraLives)

local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local LocalPlayer = Players.LocalPlayer

local ShopExtraLives = {}

-- State
local extraLifeFrame: Frame
local itemTemplate: Frame
local currentLivesLabel: TextLabel

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
    card.Price.Text = tostring(item.cost) .. ""
    card.ImageLabel.Image = item.image
    card.NameLabel.Text = item.title
    card.Name = repeatChar("a", item.cost)
    card.BuyButton.Clickable.Activated:Connect(function()
        MarketplaceService:PromptProductPurchase(LocalPlayer, item.productId)
    end)
    card.Visible = true
    return card
end

local function loadItems()
    if not extraLifeFrame or not itemTemplate then
        return
    end

    local list = extraLifeFrame:WaitForChild("ScrollingFrame")
    clearChildren(list)

    local count = 0
    for _, item: ShopItem.ShopItem in ExtraLivesData do
        count += 1
        pcall(function()
            local card = buildItemCard(item)
            card.LayoutOrder = count
            card.Parent = list
        end)
    end
end

function ShopExtraLives.start(frame: Frame, template: Frame)
    extraLifeFrame = frame
    itemTemplate = template
    currentLivesLabel = extraLifeFrame:WaitForChild("CurrentLives")

    currentLivesLabel.Text = "Respawns : " .. (UserProfile.getValue("respawns") or "0")

    UserProfile.setOnUpdateCallback(function(valueName, newValue)
        if valueName == "respawns" then
            currentLivesLabel.Text = "Respawns : " .. (newValue or "0")
        end
    end, "respawns")

    if PlatformDetector.getPlatform() == "MOBILE" then
        extraLifeFrame.ScrollingFrame.ScrollBarThickness = 10
    end

    loadItems()
end

function ShopExtraLives.refresh()
    loadItems()
end

return ShopExtraLives
