-- TutorialManager.lua
local Players = game:GetService("Players")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local PlayerPool = require(ModuleDirectory.Round.PlayerPool)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local ToolManager = require(ModuleDirectory.Tool.ToolManager)
local Dummy = require(ModuleDirectory.Tutorial.Dummy)
local TutorialMapGen = require(ModuleDirectory.Tutorial.tutorialMapGenerator)
local EventAnalytics = require(ModuleDirectory.Analytics.EventAnalytics)
local TimeTaken = require(ModuleDirectory.Tutorial.TimeTaken)

local TutorialManager = {}

-- constants
local TUTORIAL_TELEPORT_HEIGHT = 80
local LOBBY_Y_OFFSET = 6
local TRANSITION_COOLDOWN = 1.0 -- seconds between enter/leave per player

-- state
local lobbySpawn: SpawnLocation?
local inTutorial: { [number]: boolean } = {}
local charAddedConns: { [number]: RBXScriptConnection } = {}

-- NEW: track each player's spawned dummy uid
local _dummyUIDs: { [number]: number } = {}

-- transition locks and cooldown tracking
local _transitionLock: { [number]: boolean } = {}
local _lastTransitionAt: { [number]: number } = {}

-- utils
local function getPlayerTeleportPoint(player: Player): Vector3
	local origin = TutorialMapGen.getMapOrigin(player)
	if origin then
		return origin + Vector3.new(0, TUTORIAL_TELEPORT_HEIGHT, 0)
	end
	return Vector3.new()
end

local function canBeginTransition(player: Player): (boolean, string?)
	local uid = player.UserId
	if _transitionLock[uid] then
		return false, "Please wait—you're already moving."
	end
	local now = os.clock()
	local last = _lastTransitionAt[uid]
	if last and (now - last) < TRANSITION_COOLDOWN then
		return false, "Please wait a moment before moving again."
	end
	return true, nil
end

local function beginTransition(player: Player)
	_transitionLock[player.UserId] = true
end

local function endTransition(player: Player)
	local uid = player.UserId
	_transitionLock[uid] = nil
	_lastTransitionAt[uid] = os.clock()
end

local function bindCharacterAdded(player: Player)
	-- clean any previous connection
	local existing = charAddedConns[player.UserId]
	if existing then
		existing:Disconnect()
		charAddedConns[player.UserId] = nil
	end

	charAddedConns[player.UserId] = player.CharacterAdded:Connect(function()
		task.wait(0.1)
		if inTutorial[player.UserId] then
			-- passive teleport back into the player's own map
			TeleportManager.teleport(player, getPlayerTeleportPoint(player), true)
		end
	end)
end

-- NEW: destroy that player's dummy if present
local function destroyDummyFor(player: Player)
	local uid = _dummyUIDs[player.UserId]
	if uid then
		pcall(function()
			Dummy.destroy(uid)
		end)
		_dummyUIDs[player.UserId] = nil
	end
end

-- NEW: spawn a dummy at the player's tutorial map origin (slightly above ground)
local function spawnDummyFor(player: Player)
	-- ensure map exists; spawn at map origin + Y offset
	local origin = TutorialMapGen.getMapOrigin(player)
	local spawnPoint = getPlayerTeleportPoint(player)

	-- defensively remove any old dummy first (e.g., re-entering tutorial)
	destroyDummyFor(player)

	local ok, uidOrErr = pcall(function()
		return Dummy.generateNPC(spawnPoint, player)
	end)
	if ok and typeof(uidOrErr) == "number" then
		_dummyUIDs[player.UserId] = uidOrErr
	else
		warn("[TutorialManager] Failed to spawn dummy for", player.Name, uidOrErr)
	end
end

local function cleanupPlayer(player: Player)
	inTutorial[player.UserId] = nil
	_transitionLock[player.UserId] = nil
	_lastTransitionAt[player.UserId] = nil

	local conn = charAddedConns[player.UserId]
	if conn then
		conn:Disconnect()
		charAddedConns[player.UserId] = nil
	end

	-- clean up their dummy and private tutorial world
	destroyDummyFor(player)
	TutorialMapGen.deleteMap(player)
end

-- public
function TutorialManager.isPlayerInTutorial(player: Player): boolean
	return inTutorial[player.UserId] == true
end

function TutorialManager.init(): nil
	-- First load path
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
		if PlayerData.getHasJoinedBefore(player) == false then
			PlayerData.setHasJoinedBefore(player, true)
			task.wait(1)
			TutorialManager.playerEnterTutorialArea(player)
		else
			PlayerPool.addToPool(player)
		end

		-- Always bind respawn handler
		bindCharacterAdded(player)
	end)

	RemoteEventHandler.newEventConnection("TUTORIAL_COMPLETED", function(player: Player)
		if TutorialManager.isPlayerInTutorial(player) then
			EventAnalytics.logEvent(player, "COMPLETED_TUTORIAL" , TimeTaken.get(player))
			TutorialManager.playerLeaveTutorialArea(player)
		end
	end)

	lobbySpawn = workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation") :: SpawnLocation

	-- lava -> respawn back to the player's own tutorial spawn
	ServerHitBoxManager.setUpCallback("TestLava", function(player: Player, _otherPart: BasePart)
		if player.Character and inTutorial[player.UserId] then
			TeleportManager.teleport(player, getPlayerTeleportPoint(player))
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		cleanupPlayer(player)
	end)

	-- pool interaction
	PlayerPool.connectOnAdded(function(player: Player)
		if inTutorial[player.UserId] then
			-- re-apply tutorial spawn if needed (e.g., after rejoin to server)
			TutorialManager.playerEnterTutorialArea(player)
		end
	end)

	-- requests from client
	RemoteEventHandler.newEventConnection("REQUEST_JOIN_TUTORIAL_AREA", function(player: Player)
		if PlayersInGame.isAlive(player) == false then
			TutorialManager.playerEnterTutorialArea(player)
		else
			RemoteEventHandler.FireOnClient(
				player,
				"RECEIVE_SYSTEM_MESSAGE",
				"Cannot enter tutorial area while in game"
			)
		end
	end)

	RemoteEventHandler.newEventConnection("REQUEST_LEAVE_TUTORIAL_AREA", function(player: Player)
		if TutorialManager.isPlayerInTutorial(player) then
			TutorialManager.playerLeaveTutorialArea(player)
		end
	end)
end

function TutorialManager.playerEnterTutorialArea(player: Player): nil
	print(player.Name .. "Enter")

	local ok, msg = canBeginTransition(player)
	if not ok then
		if msg then
			RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", msg)
		end
		return
	end
	beginTransition(player)

	local success, err = pcall(function()
		-- Make sure the player has a private map (created if absent)
		local _map = TutorialMapGen.ensureMap(player)

		RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "TUTORIAL")
		PlayerPool.removeFromPool(player)

		inTutorial[player.UserId] = true
		ToolManager.ensureTool(player)

		RemoteEventHandler.FireOnClient(player, "START_TUTORIAL")

		EventAnalytics.logEvent(player, "STARTED_TUTORIAL")
		TimeTaken.start(player)

		-- Teleport the player to their map spawn
		TeleportManager.teleport(player, getPlayerTeleportPoint(player), true)

		-- Spawn their tutorial dummy (NPC)
		spawnDummyFor(player)
	end)

	endTransition(player)
	if not success then
		warn("[TutorialManager] enter failed: ", err)
	end
end

function TutorialManager.playerLeaveTutorialArea(player: Player): nil
	local ok, msg = canBeginTransition(player)
	if not ok then
		if msg then
			RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", msg)
		end
		return
	end
	beginTransition(player)

	local success, err = pcall(function()
		inTutorial[player.UserId] = nil

		-- Clean up dummy and map now
		destroyDummyFor(player)
		TutorialMapGen.deleteMap(player)

		-- Return them to the lobby pool a moment later (if they didn't re-enter)
		task.spawn(function()
			task.wait(3)
			if TutorialManager.isPlayerInTutorial(player) == false then
				PlayerPool.addToPool(player)
			end
		end)

		-- Move slightly above the lobby spawn to avoid clipping
		if lobbySpawn and lobbySpawn:IsDescendantOf(workspace) then
			local pos = lobbySpawn.Position + Vector3.new(0, LOBBY_Y_OFFSET, 0)
			TeleportManager.teleport(player, pos, true)
		else
			warn("[TutorialManager] Lobby spawn not found")
			TeleportManager.teleport(player, Vector3.new(), true)
		end

		RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "INTERMISSION")
	end)

	endTransition(player)
	if not success then
		warn("[TutorialManager] leave failed: ", err)
	end
end

return TutorialManager
