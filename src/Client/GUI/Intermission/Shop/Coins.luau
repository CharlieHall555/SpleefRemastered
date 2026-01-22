-- ShopExtraLives.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local ProfileVariables = require(ClientModuleDirectory.Variables.ProfileVariables)
local ShopItem = require(ClientModuleDirectory.ShopItem)

-- Data source of purchasable extra lives (array of ShopItem.ShopItem)
local CoinData = require(ClientModuleDirectory.Coins)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local LocalPlayer = Players.LocalPlayer

local ShopExtraLives = {}

-- State
local coinFrame: Frame
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
    card.Name = repeatChar("a", math.floor(item.cost / 5))
    card.BuyButton.Clickable.Activated:Connect(function()
        MarketplaceService:PromptProductPurchase(LocalPlayer, item.productId)
    end)
    card.Visible = true
    return card
end

local function loadItems()
    if not coinFrame or not itemTemplate then
        return
    end

    local list = coinFrame:WaitForChild("ScrollingFrame")
    clearChildren(list)

    local count = 0
    for _, item: ShopItem.ShopItem in CoinData do
        count += 1
        local card = buildItemCard(item)
        card.LayoutOrder = count
        card.Parent = list
    end
end

function ShopExtraLives.start(frame: Frame, template: Frame)
    coinFrame = frame
    itemTemplate = template
    currentLivesLabel = coinFrame:WaitForChild("CurrentLives")

    currentLivesLabel.Text = "Respawns : " .. (ProfileVariables.getValue("respawns") or "0")

    ProfileVariables.setOnUpdateCallback(function(valueName, newValue)
        if valueName == "respawns" then
            currentLivesLabel.Text = "Respawns : " .. (newValue or "0")
        end
    end, "respawns")

    if PlatformDetector.getPlatform() == "MOBILE" then
        coinFrame.ScrollingFrame.ScrollBarThickness = 10
    end

    loadItems()
end

function ShopExtraLives.refresh()
    loadItems()
end

return ShopExtraLives
