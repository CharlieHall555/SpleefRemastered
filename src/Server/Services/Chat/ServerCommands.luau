local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local LevelController = require(ModuleDirectory.LevelSystem.LevelController)
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local GroupService = game:GetService("GroupService")
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local ShovelCustomization = require(ModuleDirectory.Tool.ShovelCustomization)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local EconomyAnalytics = require(ModuleDirectory.Analytics.EconomyAnalytics)
local CoinManager = require(ModuleDirectory.Monetization.CoinManager)
local AbilityDefinitions = require(ModuleDirectory.Abilities.Definitions)

local ServerCommands = {}

local commandsFolder

-- try to post a system message to the default channel (falls back to print)
local function createCommand(commandName: string, allias: string, requiredGroupLevel: number): TextChatCommand
	local newCommand = Instance.new("TextChatCommand", commandsFolder)
	newCommand.Name = commandName
	newCommand.PrimaryAlias = allias
	newCommand.AutocompleteVisible = false
	newCommand.Parent = commandsFolder
	newCommand:SetAttribute("level", requiredGroupLevel)
	return newCommand
end

function systemMessage(player: Player, message: string)
	RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", message)
end

local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function findPlayerByIdentifier(identifier: string?): Player?
	if not identifier or identifier == "" then
		return nil
	end

	-- userId numeric?
	local asNum = tonumber(identifier)
	if asNum then
		local p = Players:GetPlayerByUserId(asNum)
		if p then
			return p
		end
	end

	-- exact username (Name)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name:lower() == identifier:lower() then
			return p
		end
	end

	-- exact display name
	for _, p in ipairs(Players:GetPlayers()) do
		if p.DisplayName and p.DisplayName:lower() == identifier:lower() then
			return p
		end
	end

	-- partial matches (prefer Name, then DisplayName)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.find(p.Name:lower(), identifier:lower(), 1, true) then
			return p
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.DisplayName and string.find(p.DisplayName:lower(), identifier:lower(), 1, true) then
			return p
		end
	end

	return nil
end

local function getOriginPlayer(originTextSource: TextSource?): Player?
	if not originTextSource then
		return nil
	end
	local uid = originTextSource.UserId
	if not uid or uid == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(uid)
end

local function connectToTrigger(
	command: TextChatCommand,
	callback: (originTextSource: TextSource, unfilteredText: string) -> ()
)
	command.Triggered:Connect(function(originTextSource, unfilteredText)
		local levelRequired = command:GetAttribute("level") or 255
		local caller: Player? = getOriginPlayer(originTextSource)
		if caller then
			local callerRank = (caller:GetRankInGroup(Config.GROUP_ID) or 1)
			if callerRank >= levelRequired then
				callback(originTextSource, unfilteredText)
			end
		end
	end)
end

function ServerCommands.init()
	commandsFolder = Instance.new("Folder")
	commandsFolder.Name = "ServerCommands"
	commandsFolder.Parent = TextChatService

	commandsFolder = Instance.new("Folder")
	commandsFolder.Name = "ServerCommands"
	commandsFolder.Parent = TextChatService

	--systemMessage(caller, "Invalid amount. Usage: /xp <positive number> [player]") example where caller is player

	connectToTrigger(
		createCommand("setTool", "/setShovel", 255),
		function(originTextSource: TextSource, unfilteredText: string)
			local player = Players:GetPlayerByUserId(originTextSource.UserId)
			if not player then
				return "Error: unable to resolve your player."
			end

			-- Require quoted shovel name: /setShovel "ShovelNameHere"
			local shovelName = unfilteredText:match('^%s*/setShovel%s+"(.-)"%s*$')
				or unfilteredText:match('^%s*/setShovel%s+"(.-)"%s+')
				or unfilteredText:match('^%s*/setShovel%s+"(.-)"')

			if not shovelName or shovelName == "" then
				local usage = 'Usage: /setShovel "ShovelNameHere"'
				systemMessage(player, usage)
				return usage
			end

			local ok = ShovelCustomization.equipShovel(player, shovelName)
			if ok then
				local msg = ('Shovel set to "%s".'):format(shovelName)
				systemMessage(player, msg)
				return msg
			else
				local msg = ('Failed to set shovel to "%s".'):format(shovelName)
				systemMessage(player, msg)
				return msg
			end
		end
	)

	connectToTrigger(
		createCommand("giveShovel", "/giveShovel", 255),
		function(originTextSource: TextSource, unfilteredText: string)
			local caller = getOriginPlayer(originTextSource)
			if not caller then
				return
			end

			-- Extract quoted shovel name and optional remainder (player ident)
			-- Matches:
			--   /giveShovel "VIP"
			--   /giveShovel "VIP" fazeNinja
			--   /giveShovel    "VIP"     Some Display Name
			local shovelName, remainder = unfilteredText:match('^%s*/giveShovel%s+"(.-)"%s*(.*)$')

			if not shovelName or shovelName == "" then
				systemMessage(caller, 'Usage: /giveShovel "ShovelNameHere" [player]')
				return
			end

			local target: Player? = nil
			remainder = trim(remainder or "")

			if remainder ~= "" then
				-- support spaces in display names
				target = findPlayerByIdentifier(remainder)
				if not target then
					systemMessage(caller, ("Player '%s' not found."):format(remainder))
					return
				end
			else
				target = caller
			end

			local ok = ShovelCustomization.giveShovel(target, shovelName)

			if ok then
				local who = (caller and caller.Name) or "SYSTEM"
				systemMessage(caller, ('[SHOVEL] %s gave shovel "%s" to %s.'):format(who, shovelName, target.Name))
			else
				systemMessage(caller, "[SHOVEL] Failed to give shovel.")
			end
		end
	)

	connectToTrigger(createCommand("giveCoins", "/coins", 255), function(originTextSource, unfilteredText)
		local caller = getOriginPlayer(originTextSource)
		local argsText = trim(unfilteredText or "")
		local parts = {}
		for token in string.gmatch(argsText, "%S+") do
			table.insert(parts, token)
		end

		if #parts < 2 then
			systemMessage(caller, "Usage: /coins <amount> [player]")
			return
		end

		local amount = tonumber(parts[2])
		if not amount or amount <= 0 then
			systemMessage(caller, "Invalid amount. Usage: /coins <positive number> [player]")
			return
		end

		local target: Player? = nil
		if #parts >= 3 then
			local ident = table.concat(parts, " ", 3)
			target = findPlayerByIdentifier(ident)
			if not target then
				systemMessage(caller, ("Player '%s' not found."):format(ident))
				return
			end
		else
			target = caller
			if not target then
				systemMessage(caller, "Could not resolve the calling player.")
				return
			end
		end

		-- apply XP
		local ok, err = pcall(function()
			CoinManager.giveCoins(target, amount)
			EconomyAnalytics.logCoinsTransaction(target, amount, "Source", "Admin")
		end)

		if ok then
			local who = (caller and caller.Name) or "SYSTEM"
			systemMessage(caller, ("[COINS] %s gave %d coins to %s."):format(who, amount, target.Name))
		else
			systemMessage(caller, "[COINS] Failed to give coins: " .. tostring(err))
		end
	end)

	connectToTrigger(createCommand("serverAge", "/serverAge", 1), function(originTextSource, unfilteredText)

		local caller = getOriginPlayer(originTextSource)
			
		if not caller then
			return
		end

		local running_time = math.floor(time())
		systemMessage(caller, "Server Age: " .. tostring(running_time or -1) .. " seconds.")
	end)

	connectToTrigger(createCommand("giveAbility", "/giveAbility", 255), function(originTextSource, unfilteredText)
		local caller = getOriginPlayer(originTextSource)
		local argsText = trim(unfilteredText or "")
		local parts = {}

		if not caller then
			return
		end

		-- split argsText by spaces
		for word in string.gmatch(argsText, "%S+") do
			table.insert(parts, word)
		end

		print(parts)

		if #parts < 2 then
			systemMessage(caller, "Usage: /giveAbility <ability>")
			return
		end

		-- remove all double quotes from the ability name
		local abilityName = parts[2]:gsub('"', "")

		local abilities = PlayerData.getAbilities(caller)

		if AbilityDefinitions[abilityName] == nil then
			systemMessage(caller, "No such ability: " .. abilityName)
			return
		end

		if not table.find(abilities, abilityName) then
			PlayerData.addAbility(caller, abilityName)
			systemMessage(caller, "Gave you the ability " .. abilityName)
		else
			systemMessage(caller, "You already have that ability.")
		end
	end)

	connectToTrigger(createCommand("setAbility", "/setAbility", 1), function(originTextSource, unfilteredText)
		local caller = getOriginPlayer(originTextSource)
		local argsText = trim(unfilteredText or "")
		local parts = {}

		if not caller then
			return
		end

		-- split argsText by spaces
		for word in string.gmatch(argsText, "%S+") do
			table.insert(parts, word)
		end

		print(parts)

		if #parts < 2 then
			systemMessage(caller, "Usage: /setAbility <ability>")
			return
		end

		-- remove all double quotes from the ability name
		local abilityName = parts[2]:gsub('"', "")

		local abilities = PlayerData.getAbilities(caller)

		if table.find(abilities, abilityName) then
			PlayerData.setAbility(caller, abilityName)
			systemMessage(caller, "Set your ability to " .. abilityName)
		else
			systemMessage(caller, "You don't have that ability.")
		end
	end)

	--giveXpCommand
	connectToTrigger(createCommand("giveXp", "/xp", 255), function(originTextSource, unfilteredText)
		local caller = getOriginPlayer(originTextSource)
		local argsText = trim(unfilteredText or "")
		local parts = {}
		for token in string.gmatch(argsText, "%S+") do
			table.insert(parts, token)
		end

		-- parts[1] == "/xp", so real args start from parts[2]
		if #parts < 2 then
			systemMessage(caller, "Usage: /xp <amount> [player]")
			return
		end

		local amount = tonumber(parts[2])
		if not amount or amount <= 0 then
			systemMessage(caller, "Invalid amount. Usage: /xp <positive number> [player]")
			return
		end

		local target: Player? = nil
		if #parts >= 3 then
			-- support spaces in display names
			local ident = table.concat(parts, " ", 3)
			target = findPlayerByIdentifier(ident)
			if not target then
				systemMessage(caller, ("Player '%s' not found."):format(ident))
				return
			end
		else
			target = caller
			if not target then
				systemMessage(caller, "Could not resolve the calling player.")
				return
			end
		end

		-- apply XP
		local ok, err = pcall(function()
			LevelController.giveXp(target, amount)
		end)

		if ok then
			local who = (caller and caller.Name) or "SYSTEM"
			systemMessage(caller, ("[XP] %s gave %d XP to %s."):format(who, amount, target.Name))
		else
			systemMessage(caller, "[XP] Failed to give XP: " .. tostring(err))
		end
	end)

	connectToTrigger(createCommand("kick", "/kick", 255), function(originTextSource, unfilteredText)
		local caller = getOriginPlayer(originTextSource)
		local argsText = trim(unfilteredText or "")
		local parts = {}
		for token in string.gmatch(argsText, "%S+") do
			table.insert(parts, token)
		end

		-- parts[1] == "/kick"
		if #parts < 2 then
			systemMessage(caller, "Usage: /kick <player> [reason]")
			return
		end

		-- Support multi-word identifiers: try all splits to find a player
		local target: Player? = nil
		local identEnd = 2
		for i = #parts, 2, -1 do
			local ident = table.concat(parts, " ", 2, i)
			target = findPlayerByIdentifier(ident)
			if target then
				identEnd = i
				break
			end
		end

		if not target then
			systemMessage(caller, ("Player '%s' not found."):format(table.concat(parts, " ", 2)))
			return
		end

		-- Extract optional reason after the identifier
		local reason = ""
		if identEnd < #parts then
			reason = table.concat(parts, " ", identEnd + 1)
		end
		if reason == "" then
			reason = "You were kicked from the server."
		end

		-- Prevent self-kick and kicking peers/superiors in the same group
		if caller and caller == target then
			systemMessage(caller, "You cannot kick yourself.")
			return
		end

		-- Execute kick
		local ok, err = pcall(function()
			target:Kick(reason)
		end)

		if ok then
			systemMessage(caller, ("Kicked %s. Reason: %s"):format(target.Name, reason))
		else
			systemMessage(caller, "Failed to kick: " .. tostring(err))
		end
	end)
end

return ServerCommands
