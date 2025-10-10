-- ShopAbilities.lua

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local ShopItem = require(ClientModuleDirectory.ShopItem)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local TextUtilities = require(ClientModuleDirectory.TextUtilities)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local AbilitiesData = require(ClientModuleDirectory.AbilitiesData)

local LocalPlayer = Players.LocalPlayer

local ShopAbilities = {}

-- State
local abilitiesFrame: Frame
local itemTemplate: Frame
local cachedItems: { ShopItem.ShopItem }? = nil
local buttonConnections = {}

local coinLabel : TextLabel
local abilityLabel : TextLabel

local onMissingFunds : (number) -> ()

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

    local equippedAbility = UserProfile.getValue("ability") or ""

    if item.name == equippedAbility then
        card.Price.Text = "Equipped"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = false
        card.EquippedBadge.Visible = true
        card.ImageLabel.Image = item.icon
    elseif table.find(UserProfile.getValue("abilities") or {}, item.name) then
        card.Price.Text = "Owned"
        card.Price.TextColor3 = Color3.fromRGB(0, 255, 0)
        card.BuyButton.Visible = false
        card.EquipButton.Visible = true
        card.ImageLabel.Image = item.icon
    else
        card.Price.Text = tostring(item.cost) .. "C"
        card.Price.TextColor3 = Color3.fromRGB(255, 205, 23)
        card.BuyButton.Visible = true
        card.EquipButton.Visible = false
        card.ImageLabel.Image = item.icon
    end

    local buttonConnection = card.BuyButton.Clickable.Activated:Connect(function()

        if (UserProfile.getValue("coins") or 0) < item.cost then
            print("missing")
            print(onMissingFunds)
            if onMissingFunds then
                onMissingFunds(item.cost - (UserProfile.getValue("coins") or 0))
            end
            return
        end

        RemoteEventHandler.FireOnServer("REQUEST_BUY_ABILITY", item.name)
    end)
    table.insert(buttonConnections, buttonConnection)

    buttonConnection = card.EquipButton.Clickable.Activated:Connect(function()
        RemoteEventHandler.FireOnServer("REQUEST_EQUIP_ABILITY", item.name)
    end)
    table.insert(buttonConnections, buttonConnection)

    card.Size = UDim2.new(0.165 / 4, 0, 1, 0)
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
    for _ , each in buttonConnections do
        each:Disconnect()
    end

    local source = cachedItems or AbilitiesData

    local order = 0
    for _, item: ShopItem.ShopItem in source do
        print(source)
        order += 1
        local s , e = pcall(function()
            local card = buildItemCard(item)
            card.LayoutOrder = order
            card.Parent = list
        end)
        if not s then 
            warn("Failed to build item card: " .. tostring(e))
        end
    end
end

function ShopAbilities.start(frame: Frame, template: Frame , missingFundsFunc : (number) -> ())

        
    onMissingFunds = missingFundsFunc
    abilitiesFrame = frame
    itemTemplate = template
    coinLabel = abilitiesFrame:WaitForChild("Coins")
    abilityLabel = abilitiesFrame:WaitForChild("Equipped")

    print(UserProfile.getValue("coins") , UserProfile.getValue("ability"))
    coinLabel.Text = "Coins: " ..TextUtilities.formatCurrency(UserProfile.getValue("coins") or 0).."C"
    local def = AbilitiesData[UserProfile.getValue("ability") or ""] or {displayName = "None"}
    abilityLabel.Text = "Equipped: " .. tostring(def.displayName)
    loadItems()

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        loadItems()
        local def = AbilitiesData[newValue] or {displayName = "None"}
        abilityLabel.Text = "Equipped: " .. tostring(def.displayName)
    end , "ability")
    
    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        coinLabel.Text = "Coins: " ..TextUtilities.formatCurrency(newValue or 0).."C"
    end , "coins")

    UserProfile.setOnUpdateCallback(function(valueName, newValue)  
        loadItems()
    end , "abilities")

    if PlatformDetector.getPlatform() == "MOBILE" then
        abilitiesFrame.ScrollingFrame.ScrollBarThickness = 10
    end


    
end

-- If you want to supply items at runtime

function ShopAbilities.refresh()
    loadItems()
end

return ShopAbilities
