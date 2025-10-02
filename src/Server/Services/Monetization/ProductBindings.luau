local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ProductManager = require(ModuleDirectory.Monetization.ProductManager)
local ProductList = require(ModuleDirectory.ProductList)
local RespawnManager = require(ModuleDirectory.Gameplay.RespawnManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local CoinManager = require(ModuleDirectory.Monetization.CoinManager)
local EconomyAnalytics = require(ModuleDirectory.Analytics.EconomyAnalytics)

local ProductBindings = {}

local RESPAWN_DELAY = 1

function ProductBindings.init()
	ProductManager.bindToReceipt(ProductList.ImmediateRespawn, function(player, receiptInfo)
		task.spawn(function()
			task.wait(RESPAWN_DELAY)
			local success = RespawnManager.respawnPlayer(player)
			if success then
				RemoteEventHandler.FireOnClient(player, "RESPAWN_GRANTED")
				return
			else
				PlayerData.incrementRespawns(player, 1)
				RemoteEventHandler.FireOnClient(player, "RESPAWN_REFUNDED", 1)
			end
		end)
	end)

	ProductManager.bindToReceipt(ProductList.OneRespawn, function(player, receiptInfo)
		task.spawn(function()
			task.wait(RESPAWN_DELAY)
			PlayerData.incrementRespawns(player, 1)
			RemoteEventHandler.FireOnClient(player, "RESPAWN_ADDED", 1)
		end)
	end)

	ProductManager.bindToReceipt(ProductList.ThreeRespawn, function(player, receiptInfo)
		task.spawn(function()
			task.wait(RESPAWN_DELAY)
			PlayerData.incrementRespawns(player, 3)
			RemoteEventHandler.FireOnClient(player, "RESPAWN_ADDED", 3)
		end)
	end)

	ProductManager.bindToReceipt(ProductList.FiveRespawn, function(player, receiptInfo)
		task.spawn(function()
			task.wait(RESPAWN_DELAY)
			PlayerData.incrementRespawns(player, 5)
			RemoteEventHandler.FireOnClient(player, "RESPAWN_ADDED", 5)
		end)
	end)

	ProductManager.bindToReceipt(ProductList.Coins100, function(player, receiptInfo)
		task.spawn(function()
			CoinManager.giveCoins(player, 100)
			EconomyAnalytics.logCoinsTransaction(player, 100, "Source", "IAP")
		end)
	end)

	ProductManager.bindToReceipt(ProductList.Coins250, function(player, receiptInfo)
		task.spawn(function()
			CoinManager.giveCoins(player, 250)
			EconomyAnalytics.logCoinsTransaction(player, 250, "Source", "IAP")
		end)
	end)

	ProductManager.bindToReceipt(ProductList.Coins500, function(player, receiptInfo)
		task.spawn(function()
			CoinManager.giveCoins(player, 500)
			EconomyAnalytics.logCoinsTransaction(player, 500, "Source", "IAP")
		end)
	end)

	ProductManager.bindToReceipt(ProductList.Coins1000, function(player, receiptInfo)
		task.spawn(function()
			CoinManager.giveCoins(player, 1000)
			EconomyAnalytics.logCoinsTransaction(player, 1000, "Source", "IAP")
		end)
	end)

	ProductManager.bindToPromptFinished(ProductList.ImmediateRespawn, function(userId, info) end)
end

return ProductBindings
