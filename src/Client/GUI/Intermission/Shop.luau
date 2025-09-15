local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ExtraLives = require(ClientModuleDirectory.ExtraLives)
local ShopItem = require(ClientModuleDirectory.ShopItem)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local LocalPlayer = Players.LocalPlayer

local Shop = {}

-- State (kept local to this module)
local ShopGui: Frame
local main: Frame
local buttonSelection: ScrollingFrame
local closeButtonClickable: TextButton
local extraLifeFrame: Frame
local extraLifeCurrentLives: TextLabel
local shovelsFrame: Frame
local itemTemplate: Frame
local initialized = false

-- Utils
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

local function buildItemCard(item: ShopItem.ShopItem, i: number): Frame
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

local function loadExtraLives()
	if not extraLifeFrame or not itemTemplate then
		return
	end
	local list = extraLifeFrame:WaitForChild("ScrollingFrame")

	clearChildren(list)

	local count = 0

	for _, item: ShopItem.ShopItem in ExtraLives do
		count += 1
		local card = buildItemCard(item, count)
		card.Parent = list
	end
end

local function wireHandlers()
	-- Single close wiring
	local closeBtn = main:WaitForChild("CloseButton")
	closeBtn.Clickable.Activated:Connect(function()
		Shop.hide()
	end)
	closeButtonClickable = closeBtn.Clickable
end

-- Public API
function Shop.onProfileLoaded()
	if initialized then
		-- Refresh contents if called again
		loadExtraLives()
		Shop.show()
		return
	end

	if PlatformDetector.getPlatform() == "MOBILE" then
		ShopGui = GuiAssets.Intermission:WaitForChild("MobileShop")
	else
		ShopGui = GuiAssets.Intermission:WaitForChild("Shop")
	end

	ShopGui.Visible = false
	ShopGui.Parent = Screens.intermissionHUD

	main = ShopGui:WaitForChild("Main")
	buttonSelection = main:WaitForChild("ButtonSelection")

	extraLifeFrame = main:WaitForChild("ExtraLives")
	extraLifeCurrentLives = extraLifeFrame:WaitForChild("CurrentLives")
	shovelsFrame = main:WaitForChild("Shovels")

	itemTemplate = ShopGui:WaitForChild("ItemTemplate")

	extraLifeCurrentLives.Text = "Respawns : " .. (UserProfile.getValue("respawns") or "0")

	UserProfile.setOnUpdateCallback(function(valueName, newValue)
		extraLifeCurrentLives.Text = "Respawns : " .. (newValue or "0")
	end, "respawns")

	wireHandlers()
	loadExtraLives()

	initialized = true
end

function Shop.getVisible()
    return ShopGui.Visible
end

function Shop.show()
	if not ShopGui then
		return
	end
	ShopGui.Visible = true
	FrameSystem.setCurrent(ShopGui)
end

function Shop.hide()
	if not ShopGui then
		return
	end
	ShopGui.Visible = false
	FrameSystem.setCurrent(nil)
end

return Shop
