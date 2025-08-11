-- raycast params will just exclude the player's character; everything else will collide.
-- raycast params collision group is "CH_GAMEPLAY"

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PlayerRaycastParamsHandler = {}

local COLLISION_GROUP = "CG_GAMEPLAY"

local cache: { [number]: RaycastParams } = {}
local _characterConnections: { [number]: RBXScriptConnection } = {}

local function ensureCollisionGroup()
	local exists = false
	for _, g in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		if g.name == COLLISION_GROUP then
			exists = true
			break
		end
	end
	if not exists then
		pcall(function()
			PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
		end)
	end
end

local function newParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	params.CollisionGroup = COLLISION_GROUP
	return params
end

local function setCharacterAsExclude(player: Player)
	local params = cache[player.UserId]
	if not params then
		return
	end
	local character = player.Character
	if character and character.Parent then
		params.FilterDescendantsInstances = { character }
	else
		params.FilterDescendantsInstances = {}
	end
end

function PlayerRaycastParamsHandler.playerJoined(player: Player): nil
	ensureCollisionGroup()

	local params = cache[player.UserId]
	if not params then
		params = newParams()
		cache[player.UserId] = params
	end

	if _characterConnections[player.UserId] then
		_characterConnections[player.UserId]:Disconnect()
		_characterConnections[player.UserId] = nil
	end

	_characterConnections[player.UserId] = player.CharacterAdded:Connect(function()
		setCharacterAsExclude(player)
	end)

	setCharacterAsExclude(player)
end

function PlayerRaycastParamsHandler.playerLeft(player: Player): nil
	PlayerRaycastParamsHandler.cleanup(player)
end

function PlayerRaycastParamsHandler.onLoaded(): nil
	ensureCollisionGroup()

	for _, p in ipairs(Players:GetPlayers()) do
		PlayerRaycastParamsHandler.playerJoined(p)
	end

	Players.PlayerAdded:Connect(function(p)
		PlayerRaycastParamsHandler.playerJoined(p)
	end)

	Players.PlayerRemoving:Connect(function(p)
		PlayerRaycastParamsHandler.playerLeft(p)
	end)
end

function PlayerRaycastParamsHandler.get(player: Player): RaycastParams?
	if player == nil then
		return nil
	end
	return cache[player.UserId]
end

function PlayerRaycastParamsHandler.cleanup(player: Player): nil?
	local uid = player.UserId

	if _characterConnections[uid] then
		_characterConnections[uid]:Disconnect()
		_characterConnections[uid] = nil
	end

	if cache[uid] then
		cache[uid] = nil
	end
end

return PlayerRaycastParamsHandler
