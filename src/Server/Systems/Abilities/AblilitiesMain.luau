local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local AbilitiesDefinitions = require(ModuleDirectory.Abilities.Definitions)
local AbilitiesFunctions = require(ModuleDirectory.Abilities.Functions)
local PlayersAlive = require(ModuleDirectory.Systems.Round.PlayersInGame)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local AbilitiesEndFunctions = require(ModuleDirectory.Abilities.EndFunctions)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local SpawnProtectionManager = require(ModuleDirectory.Systems.Gameplay.SpawnProtectionManager)

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

	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
		SessionVariables.setValue(player, "abilityActive", false)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastUsed[player.UserId] = nil
	end)

	RemoteEventHandler.newEventConnection("REQUEST_ABILITY", function(player)
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
	local inTutorial = SessionVariables.getValue(player, "inTutorial")

	if not inTutorial and RoundSystem.getState() ~= "ACTIVE" then
		return
	end

	if checkCooldown(player, abilName, abilCooldown) == false then
		return
	end

	if not inTutorial and PlayersAlive.isAlive(player) == false then
		return
	end

	if SpawnProtectionManager.isActive(player) then
		return
	end

	local startFunc = AbilitiesFunctions[abilName]
	if startFunc then
		startFunc(player, player.Character)
	end

	local endFunc = AbilitiesEndFunctions[abilName]
	if endFunc and abilDef.activeTime > 0 then
		SessionVariables.setValue(player, "abilityActive", true)
		task.delay(abilDef.activeTime, function()
			SessionVariables.setValue(player, "abilityActive", false)
			endFunc(player, player.Character)
		end)
	end

	RemoteEventHandler.FireOnClient(player, "FIRE_ABILITY", abilName, {})
end

return AbilitiesMain
