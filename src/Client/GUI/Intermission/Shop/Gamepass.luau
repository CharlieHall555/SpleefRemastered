-- ShopExtraLives.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)
local ShopItem = require(ClientModuleDirectory.ShopItem)

-- Data source of purchasable extra lives (array of ShopItem.ShopItem)
local GamePassData = require(ClientModuleDirectory.GamePassData)

local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local LocalPlayer = Players.LocalPlayer

local ShopExtraLives = {}

-- State
local gamePassFrame: Frame
local itemTemplate: Frame

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

    local ownedGamepasses = UserSessionVariables.getValue("ownedGamepasses") or {}

    if table.find(ownedGamepasses, item.passId) then
        local card = itemTemplate:Clone()
        card.Price.Text = tostring(item.cost) .. "\u{E002}"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = false
        card.EquippedBadge.Visible = true
        card.EquippedBadge.TextLabel.Text = "Owned"
        card.ImageLabel.Image = item.image
        card.NameLabel.Text = item.title
        card.Name = repeatChar("a", item.cost)
        card.Visible = true
        return card
    else
        local card = itemTemplate:Clone()
        card.Price.Text = tostring(item.cost) .. "\u{E002}"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = true
        card.EquipButton.Visible = false
        card.EquippedBadge.Visible = false
        card.ImageLabel.Image = item.image
        card.NameLabel.Text = item.title
        card.Name = repeatChar("a", item.cost)
        card.BuyButton.Clickable.Activated:Connect(function()
            MarketplaceService:PromptGamePassPurchase(LocalPlayer, item.passId)
        end)
        card.Visible = true
        return card
    end
end

local function loadItems()
    if not gamePassFrame or not itemTemplate then
        return
    end

    local list = gamePassFrame:WaitForChild("ScrollingFrame")
    clearChildren(list)

    local count = 0
    for _, item: ShopItem.ShopItem in GamePassData do
        count += 1
        pcall(function()
            local card = buildItemCard(item)
            card.LayoutOrder = count
            card.Parent = list
        end)        
    end
end

function ShopExtraLives.start(frame: Frame, template: Frame)
    gamePassFrame = frame
    itemTemplate = template

    loadItems()

    UserSessionVariables.setOnUpdateCallback(function(name: string, value: any)
       loadItems()
    end, "ownedGamepasses")

    if PlatformDetector.getPlatform() == "MOBILE" then
        gamePassFrame.ScrollingFrame.ScrollBarThickness = 10
    end
end

function ShopExtraLives.refresh()
    loadItems()
end

return ShopExtraLives
