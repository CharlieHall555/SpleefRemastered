local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local KickManager = require(ModuleDirectory.Gameplay.KickManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ProductList = require(ModuleDirectory.ProductList)

local ProductManager = {}

local _uidCounter = 0
local _byProduct: { [number]: { [number]: (Player, {}) -> () } } = {}
local _byUid: { [number]: number } = {}

local function nextUid(): number
    _uidCounter += 1
    return _uidCounter
end

local function getPlayerById(userId: number): Player?
    return Players:GetPlayerByUserId(userId)
end

local function fireHandlersForProduct(productId: number, player: Player, receiptInfo: {})
    local handlers = _byProduct[productId]
    if not handlers then
        return
    end
    for _, fn in handlers do
        task.spawn(function()
            local ok, err = pcall(fn, player, receiptInfo)
            if not ok then
                warn(("[ProductManager] Handler error for product %d: %s"):format(productId, tostring(err)))
            end
        end)
    end
end

function ProductManager.init()
    -- One global receipt handler; delegate to registered callbacks.
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        local player = getPlayerById(receiptInfo.PlayerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        fireHandlersForProduct(receiptInfo.ProductId, player, receiptInfo)

        -- Handlers are responsible for granting benefits; we acknowledge purchase.
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end

function ProductManager.bindToSale(productId: number, fn: (player: Player, receiptInfo: {}) -> ()): number
    assert(type(productId) == "number", "productId must be a number")
    assert(type(fn) == "function", "fn must be a function")

    local uid = nextUid()
    _byProduct[productId] = _byProduct[productId] or {}
    _byProduct[productId][uid] = fn
    _byUid[uid] = productId
    return uid
end

function ProductManager.unBindToSale(uid: number): nil
    local productId = _byUid[uid]
    if not productId then
        return
    end
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

return ProductManager
