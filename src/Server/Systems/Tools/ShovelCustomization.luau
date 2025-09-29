local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local ToolManager = require(ModuleDirectory.Tool.ToolManager)

local ShovelCustomization = {}

function ShovelCustomization.giveShovel(player: Player, shovelName: string)
	local ownedShovels = PlayerData.getShovels(player) or {}
	if table.find(ownedShovels, shovelName) then
		return false
	end
	PlayerData.addShovel(player, shovelName)
	ToolManager.refreshTool(player)
	return true
end

function ShovelCustomization.equipShovel(player: Player, shovelName: string)
	print("types", typeof(player), typeof(shovelName))

	local ownedShovels = PlayerData.getShovels(player) or {}
	if table.find(ownedShovels, shovelName) then
		PlayerData.setShovel(player, shovelName)
		ToolManager.refreshTool(player)
		return true
	end

	print("NOT OWNDED" , ownedShovels)

	return false
end

return ShovelCustomization
