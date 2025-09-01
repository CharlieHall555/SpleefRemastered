local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LevelUtilities = require(ModuleDirectory.LevelSystem.LevelUtilities)
local LevelController = require(ModuleDirectory.LevelSystem.LevelController)
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerCommands = {}

local commandsFolder

-- try to post a system message to the default channel (falls back to print)
local function createCommand(commandName: string, allias: string): TextChatCommand
	local newCommand = Instance.new("TextChatCommand", commandsFolder)
	newCommand.Name = commandName
	newCommand.PrimaryAlias = allias
	newCommand.AutocompleteVisible = false
	newCommand.Parent = commandsFolder
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

function ServerCommands.init()
	commandsFolder = Instance.new("Folder")
	commandsFolder.Name = "ServerCommands"
	commandsFolder.Parent = TextChatService

	commandsFolder = Instance.new("Folder")
	commandsFolder.Name = "ServerCommands"
	commandsFolder.Parent = TextChatService

	createCommand("giveXp", "/xp").Triggered:Connect(function(originTextSource, unfilteredText)
		local caller = getOriginPlayer(originTextSource)
		local argsText = trim(unfilteredText or "")
		local parts = {}
		for token in string.gmatch(argsText, "%S+") do
			table.insert(parts, token)
		end

		print(parts)

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
end

return ServerCommands
