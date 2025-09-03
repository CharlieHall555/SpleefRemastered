local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local ProductManager = require(ModuleDirectory.Monetization.ProductManager)
local ProductList = require(ModuleDirectory.ProductList)
local RespawnManager = require(ModuleDirectory.Gameplay.RespawnManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)

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

	ProductManager.bindToPromptFinished(ProductList.ImmediateRespawn, function(userId, info) end)
end

return ProductBindings
