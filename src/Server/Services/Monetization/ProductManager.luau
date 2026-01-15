local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local KickManager = require(ModuleDirectory.Systems.Gameplay.KickManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ProductList = require(ModuleDirectory.ProductList)

local ProductManager = {}

-- uid counter shared across both Receipt + prompt bindings
local _uidCounter = 0

-- Receipt handlers
local _byProduct: { [number]: { [number]: (Player, {}) -> () } } = {}
local _byUid: { [number]: number } = {}

-- PromptPurchaseFinished handlers
local _promptByProduct: { [number]: { [number]: (number, { productId: number, purchased: boolean }) -> () } } = {}
local _promptByUid: { [number]: number } = {}

local _promptConn: RBXScriptConnection? = nil

local function nextUid(): number
	_uidCounter += 1
	return _uidCounter
end

local function getPlayerById(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function fireHandlersForProduct(productId: number, player: Player, ReceiptInfo: {})
	local handlers = _byProduct[productId]
	if not handlers then return end

	for _, fn in handlers do
		task.spawn(function()
			local ok, err = pcall(fn, player, ReceiptInfo)
			if not ok then
				warn(("[ProductManager] Handler error for product %d: %s"):format(productId, tostring(err)))
			end
		end)
	end
end

local function firePromptHandlersForProduct(productId: number, player: Player, purchased: boolean)
	local handlers = _promptByProduct[productId]
	if not handlers then return end

	local info = { productId = productId, purchased = purchased }
	for _, fn in handlers do
		task.spawn(function()
			local ok, err = pcall(fn, player, info)
			if not ok then
				warn(("[ProductManager] Prompt handler error for product %d: %s"):format(productId, tostring(err)))
			end
		end)
	end
end

function ProductManager.init()
	-- One global Receipt handler; delegate to registered callbacks.
	MarketplaceService.ProcessReceipt = function(ReceiptInfo)
		local player = getPlayerById(ReceiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		fireHandlersForProduct(ReceiptInfo.ProductId, player, ReceiptInfo)
		-- Handlers are responsible for granting benefits; acknowledge purchase.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Connect once to PromptProductPurchaseFinished to fan out to per-product handlers.
	if not _promptConn then
		_promptConn = MarketplaceService.PromptProductPurchaseFinished:Connect(function(player: Player, productId: number, wasPurchased: boolean)
			if not player or typeof(productId) ~= "number" then return end
			firePromptHandlersForProduct(productId, player, wasPurchased)
		end)
	end
end

--===========================--
-- Receipt binding (existing)
--===========================--

-- Keep original misspelling for backward compatibility
function ProductManager.bindToReceipt(productId: number, fn: (player: Player, ReceiptInfo: {}) -> ()): number
	assert(type(productId) == "number", "productId must be a number")
	assert(type(fn) == "function", "fn must be a function")

	local uid = nextUid()
	_byProduct[productId] = _byProduct[productId] or {}
	_byProduct[productId][uid] = fn
	_byUid[uid] = productId
	return uid
end

function ProductManager.unBindToReceipt(uid: number): nil
	local productId = _byUid[uid]
	if not productId then return end

	local bucket = _byProduct[productId]
	if bucket then
		bucket[uid] = nil
		local hasAny = false
		for _ in bucket do
			hasAny = true
			break
		end
		if not hasAny then
			_byProduct[productId] = nil
		end
	end
	_byUid[uid] = nil
end

-- Correctly-spelled aliases
ProductManager.bindToReceipt = ProductManager.bindToReceipt
ProductManager.unBindToReceipt = ProductManager.unBindToReceipt

--============================================--
-- NEW: PromptProductPurchaseFinished binding
--============================================--

-- Works similarly to bindToReceipt: per-product buckets, returns a uid,
-- and your callback is (player, info) where info = { productId, purchased }
function ProductManager.bindToPromptFinished(
	productId: number,
	fn: (userId : number , info: { productId: number, purchased: boolean }) -> ()
): number
	assert(type(productId) == "number", "productId must be a number")
	assert(type(fn) == "function", "fn must be a function")

	local uid = nextUid()
	_promptByProduct[productId] = _promptByProduct[productId] or {}
	_promptByProduct[productId][uid] = fn
	_promptByUid[uid] = productId
	return uid
end

function ProductManager.unBindToPromptFinished(uid: number): nil
	local productId = _promptByUid[uid]
	if not productId then return end

	local bucket = _promptByProduct[productId]
	if bucket then
		bucket[uid] = nil
		local hasAny = false
		for _ in bucket do
			hasAny = true
			break
		end
		if not hasAny then
			_promptByProduct[productId] = nil
		end
	end
	_promptByUid[uid] = nil
end

return ProductManager
