local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local AbilitiesDefinitions = require(ModuleDirectory.Abilities.Definitions)
local AbilitiesFunctions = require(ModuleDirectory.Abilities.Functions)

local AbilitiesMain = {}

-- Track last-used timestamps per player
local lastUsed = {}

local function checkCooldown(player: Player, abilityName: string, cooldown: number): boolean
	local now = os.clock()
	local forgiveness = cooldown * 0.1 -- 10% forgiveness

	-- If player has never used ability before, allow it
	if not lastUsed[player.UserId] then
		lastUsed[player.UserId] = {}
	end

	local lastTime = lastUsed[player.UserId][abilityName]
	if not lastTime then
		lastUsed[player.UserId][abilityName] = now
		return true
	end

	-- Check if cooldown (with forgiveness) has passed
	if now - lastTime >= cooldown - forgiveness then
		lastUsed[player.UserId][abilityName] = now
		return true
	end

	return false
end

function AbilitiesMain.init()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastUsed[player.UserId] = nil
	end)

    RemoteEventHandler.newEventConnection("REQUEST_ABILITY" , function(player)
        AbilitiesMain.fireAbility(player)
    end)
end

function AbilitiesMain.fireAbility(player: Player)
	local abilName = PlayerData.getAbility(player)
	local abilDef = AbilitiesDefinitions[abilName]
	if not abilDef then
		warn("Ability not defined for: " .. abilName)
		return
	end

	local abilCooldown = abilDef.cooldown

	if checkCooldown(player, abilName, abilCooldown) == false then
        return
    end

    local func = AbilitiesFunctions[abilName]
    if func then
        func(player , player.Character)
    end


end

return AbilitiesMain
