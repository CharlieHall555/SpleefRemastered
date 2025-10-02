local AnalyticsService = game:GetService("AnalyticsService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)

local EconomyAnalytics = {}

export type flowType = "Sink" | "Source"
export type transactionType = "IAP" | "TimedReward" | "Gameplay" | "Shop" | "ContextualPurchase" | "Onboarding" | "Admin"

local validTransactionTypes = {"IAP" , "TimedReward" , "Gameplay" , "Shop" , "ContextualPurchase" , "Onboarding" , "Admin"}
function EconomyAnalytics.init() end

function EconomyAnalytics.logCoinsTransaction(player: Player, amount: number, flow: flowType?, _type: transactionType?)
	if player and amount and flow and _type and table.find(validTransactionTypes , _type) then
		local flowEnum = Enum.AnalyticsEconomyFlowType[flow]

		local s, e = pcall(function()
			AnalyticsService:LogEconomyEvent(
				player,
				flowEnum,
				"Coins",
				amount,
				PlayerData.getCoins(player) or amount,
				_type
			)
		end)
	end
end

return EconomyAnalytics
