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
local AmmoPickupManager = require(ModuleDirectory.Gameplay.AmmoPickupManager)

local _lastSnowballFired: { [number]: number } = {} -- userId -> last fire timestamp

function SnowballManager.init()
	RemoteEventHandler.newEventConnection("CREATE_SNOWBALL", SnowballManager.createSnowballFor)
	ThrowableManager.registerOnHit("snowball" , SnowballManager.onHit)

	ServerHitBoxManager.setUpCallback("SNOWBALL_AMMO" , function(player , otherPart)
		local snowballId = otherPart:GetAttribute("Id")
		local pickup = SnowballAmmoPickup.get(snowballId or -1)
		print("pickup" , pickup)
		local increment = (pickup or {}).increment or 1
		AmmoManager.incrementAmmo(player ,increment)
		SnowballAmmoPickup.remove(snowballId)
		
	end)

end

function SnowballManager.onHit(throwable : Throwable.Throwable , hit : RaycastResult)
	print("hit " .. hit.Instance.Name)
	local blockId = hit.Instance:GetAttribute("Id")
	if blockId then
		local block : Block.Block = LoadedBlocks[blockId]
		local blockPosition = hit.Instance.Position
		BlockFactory.destroyById(blockId , throwable.owner)
		RemoteEventHandler.FireOnAllClients("BLOCK_DESTROY_CONFIRMATION" , blockId , block.Type , blockPosition)
	end
end

function SnowballManager.createSnowballFor(player, playerPosition, direction)
	if RoundSystem.getState() ~= "ACTIVE" then
		return
	end

	if AmmoManager.getAmmo(player) < 1 then
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
	local now = tick()
	local lastFire = _lastSnowballFired[userId] or 0
	if now - lastFire < Config.SNOWBALL_COOLDOWN then
		warn("Snowball creation failed: cooldown active for", player)
		return
	end

	_lastSnowballFired[userId] = now
	AmmoManager.incrementAmmo(player , -1)
	ThrowableManager.newThrowable(spawnPosition, direction, "snowball" , player)
end

return SnowballManager
