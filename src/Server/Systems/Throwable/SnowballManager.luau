local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local ThrowableManager = require(ModuleDirectory.Throwable.ThrowableManager)
local Throwable = require(ModuleDirectory.Throwable.Throwable)
local BlockFactory = require(ModuleDirectory.Systems.Map.BlockFactory)
local Block = require(ModuleDirectory.Systems.Map.Block)
local LoadedBlocks = require(ModuleDirectory.Systems.Map.LoadedBlocks)
local SnowballManager = {}
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local AmmoManager = require(ModuleDirectory.Systems.Ammo.AmmoManager)
local ServerHitBoxManager = require(ModuleDirectory.Systems.Gameplay.ServerHitBoxManager)
local SnowballAmmoPickup = require(ModuleDirectory.Systems.Ammo.SnowballAmmoPickup)
local Onboarding = require(ModuleDirectory.Services.Analytics.Onboarding)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)

local _lastSnowballFired: { [number]: number } = {} -- userId -> last fire timestamp

function SnowballManager.init()
	RemoteEventHandler.newEventConnection("REQUEST_SNOWBALL", SnowballManager.createSnowballFor)
	ThrowableManager.registerOnHit("snowball", SnowballManager.onHit)

	ServerHitBoxManager.setUpCallback("SNOWBALL_AMMO", function(player, otherPart)
		local snowballId = otherPart:GetAttribute("Id")
		local pickup = SnowballAmmoPickup.get(snowballId or -1)
		local increment = (pickup or {}).increment or 1
		AmmoManager.incrementAmmo(player, increment)
		RemoteEventHandler.FireOnClient(player, "AMMO_GAINED", increment)
		SnowballAmmoPickup.remove(snowballId)
	end)
end

function SnowballManager.onHit(throwable: Throwable.Throwable, hit: RaycastResult , active : boolean)
	local blockId = hit.Instance:GetAttribute("Id")
	if blockId then
		local block: Block.Block = LoadedBlocks[blockId]
		local blockPosition = hit.Instance.Position

		if active == false and hit.Instance:HasTag("TutorialBlock") == false then
			return
		end

		if block == nil then
			return
		end

		BlockFactory.destroyById(blockId, throwable.owner)
		if throwable.owner and PlayersInGame.isAlive(throwable.owner) then
			Onboarding.action(throwable.owner, "SNOWBALL_BROKEN_BLOCK")
		end

		if block and block.Regenerates == false then
			RemoteEventHandler.FireOnAllClients(
				"BLOCK_DESTROY_CONFIRMATION",
				blockId,
				block.Type,
				blockPosition,
				throwable.owner,
				"snowball"
			)
		end
	end

	RemoteEventHandler.FireUnreliableOnAllClients("SNOWBALL_IMPACT" , hit.Position , hit.Instance , throwable.owner)

end

function SnowballManager.createSnowballFor(player, playerPosition, direction)
	-- separate this logic out to make it clearer to debug
	if (PlayersInGame.isAlive(player) or SessionVariables.getValue(player, "inTutorial")) and (AmmoManager.getAmmo(player) or 0) < 1 and AmmoManager.isInfiniteAmmo() == false then
		return
	end

	if not playerPosition or not direction then
		warn("Snowball creation failed: missing position or direction for", player)
		return
	end

	local character = player.Character
	if not character then
		warn("Snowball creation failed: player has no character:", player)
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("Snowball creation failed: missing HumanoidRootPart for", player)
		return
	end

	local spawnPosition
	local distance = (playerPosition - rootPart.Position).Magnitude
	if distance > Config.SNOWBALL_DISTANCE_THRESHOLD then
		warn("Snowball creation point altered: spawn too far from player:", player)
		spawnPosition = rootPart.Position
		return
	else
		spawnPosition = playerPosition
	end

	local userId = player.UserId
	local now = time()
	local lastFire = _lastSnowballFired[userId] or 0
	if now - lastFire < Config.SNOWBALL_COOLDOWN then
		warn("Snowball creation failed: cooldown active for", player)
		return
	end

	_lastSnowballFired[userId] = now
	
	local active = PlayersInGame.isAlive(player)

	if active then
		task.spawn(function()
			pcall(function()
				Onboarding.action(player, "SHOT")
			end)
		end)
		AmmoManager.incrementAmmo(player, -1)
		print("decrease ammo")
	elseif SessionVariables.getValue(player, "inTutorial") then
		AmmoManager.incrementAmmo(player, -1)
	end

	ThrowableManager.newThrowable(spawnPosition, direction, "snowball", player ,active)
end

return SnowballManager
