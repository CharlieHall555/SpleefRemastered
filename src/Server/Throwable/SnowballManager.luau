local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)
local ThrowableManager = require(ModuleDirectory.Throwable.ThrowableManager)
local Throwable = require(ModuleDirectory.Throwable.Throwable)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)
local Block = require(ModuleDirectory.Map.Block)
local LoadedBlocks = require(ModuleDirectory.LoadedBlocks)
local SnowballManager = {}
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local AmmoManager = require(ModuleDirectory.Throwable.AmmoManager)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local SnowballAmmoPickup = require(ModuleDirectory.Gameplay.SnowballAmmoPickup)
local Onboarding = require(ModuleDirectory.Analytics.Onboarding)
local TutorialManager = require(ModuleDirectory.TutorialManager)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)

local _lastSnowballFired: { [number]: number } = {} -- userId -> last fire timestamp

function SnowballManager.init()
	RemoteEventHandler.newEventConnection("CREATE_SNOWBALL", SnowballManager.createSnowballFor)
	ThrowableManager.registerOnHit("snowball", SnowballManager.onHit)

	ServerHitBoxManager.setUpCallback("SNOWBALL_AMMO", function(player, otherPart)
		print("HIITTT")
		local snowballId = otherPart:GetAttribute("Id")
		local pickup = SnowballAmmoPickup.get(snowballId or -1)
		print("pickup", pickup)
		local increment = (pickup or {}).increment or 1
		AmmoManager.incrementAmmo(player, increment)
		RemoteEventHandler.FireOnClient(player, "AMMO_GAINED", increment)
		SnowballAmmoPickup.remove(snowballId)
	end)
end

function SnowballManager.onHit(throwable: Throwable.Throwable, hit: RaycastResult , tutorial : boolean)
	print("hit " .. hit.Instance.Name)
	local blockId = hit.Instance:GetAttribute("Id")
	if blockId then
		local block: Block.Block = LoadedBlocks[blockId]
		local blockPosition = hit.Instance.Position
		BlockFactory.destroyById(blockId, throwable.owner)

		if tutorial and (not hit.Instance:HasTag("TutorialBlock")) then
			return
		end

		if throwable.owner and tutorial == false then
			Onboarding.action(throwable.owner, "SNOWBALL_BROKEN_BLOCK")
		end

		if block.Regenerates == false then
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
end

function SnowballManager.createSnowballFor(player, playerPosition, direction)
	if AmmoManager.getAmmo(player) < 1 and AmmoManager.isInfiniteAmmo() == false and TutorialManager.isPlayerInTutorial(player) == false then
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

	if PlayersInGame.isAlive(player) == false and TutorialManager.isPlayerInTutorial(player) == false then
		warn("Player not alive or in tutorial.")
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

	local tutorial = TutorialManager.isPlayerInTutorial(player)

	_lastSnowballFired[userId] = now
	
	if tutorial == false then
		Onboarding.action(player, "SHOT")
		AmmoManager.incrementAmmo(player, -1)
	end

	print("now!")

	ThrowableManager.newThrowable(spawnPosition, direction, "snowball", player , tutorial)
end

return SnowballManager
