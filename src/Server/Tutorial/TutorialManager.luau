local Players = game:GetService("Players")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local MapGenerator = require(ModuleDirectory.Map.MapGenerator)
local TutorialMap = require(game:GetService("ServerScriptService").MapSaves.TutorialMap)
local ServerHitBoxManager = require(ModuleDirectory.Gameplay.ServerHitBoxManager)
local TeleportManager = require(ModuleDirectory.Round.TeleportManager)
local PlayerPool = require(ModuleDirectory.Round.PlayerPool)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Map = require(ModuleDirectory.Map.Map)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local ToolManager = require(ModuleDirectory.Gameplay.ToolManager)

local TutorialManager = {}

-- constants
local TUTORIAL_TELEPORT_HEIGHT = 80
local LOBBY_Y_OFFSET = 6
local TRANSITION_COOLDOWN = 1.0 -- seconds between enter/leave per player

-- state
local tutorialMap: Map.Map?
local lobbySpawn: SpawnLocation?
local inTutorial: { [number]: boolean } = {}
local charAddedConns: { [number]: RBXScriptConnection } = {}

-- NEW: transition locks and cooldown tracking
local _transitionLock: { [number]: boolean } = {}
local _lastTransitionAt: { [number]: number } = {}

-- utils
local function getMapTeleportPoint(): Vector3
	if tutorialMap and tutorialMap.OriginPosition then
		return tutorialMap.OriginPosition + Vector3.new(0, TUTORIAL_TELEPORT_HEIGHT, 0)
	end
	return Vector3.new(0, 0, 0)
end

-- NEW: basic per-player mutex + cooldown
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
			-- Note: this is a passive teleport (not a state transition), so no lock here
			TeleportManager.teleport(player, getMapTeleportPoint(), true)
		end
	end)
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
end

-- public
function TutorialManager.isPlayerInTutorial(player: Player): boolean
	return inTutorial[player.UserId] == true
end

--function TutorialManager.init(): nil
--[[
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
		PlayerPool.addToPool(player)
		--[[if PlayerData.gethasJoinedBefore(player) then
			PlayerPool.addToPool(player)
		else
			PlayerData.sethasJoinedBefore(player , true)
			task.wait(1)
			TutorialManager.playerEnterTutorialArea(player)
			RemoteEventHandler.FireOnClient(player , "START_TUTORIAL")
		end
	end)

	RemoteEventHandler.newEventConnection("TUTORIAL_COMPLETED", function(player)
		if TutorialManager.isPlayerInTutorial(player) then
			TutorialManager.playerLeaveTutorialArea(player)
		end
	end)

	lobbySpawn = workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation") :: SpawnLocation
	tutorialMap = MapGenerator.generate(TutorialMap)

	-- lava -> respawn back to tutorial spawn
	ServerHitBoxManager.setUpCallback("TestLava", function(player: Player, _otherPart: BasePart)
		if player.Character and inTutorial[player.UserId] then
			-- Not a state transition; no lock/cooldown needed
			TeleportManager.teleport(player, getMapTeleportPoint())
		end
	end)

	-- player lifecycle
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
		bindCharacterAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		cleanupPlayer(player)
	end)

	-- pool interaction
	PlayerPool.connectOnAdded(function(player: Player)
		if inTutorial[player.UserId] then
			-- Not a state transition; re-apply tutorial spawn if needed
			TutorialManager.playerEnterTutorialArea(player)
		end
	end)

	-- requests
	RemoteEventHandler.newEventConnection("REQUEST_JOIN_TUTORIAL_AREA", function(player: Player)
		if PlayersInGame.isAlive(player) == false then
			TutorialManager.playerEnterTutorialArea(player)
		else
			RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", "Cannot enter tutorial area while in game")
		end
	end)

	RemoteEventHandler.newEventConnection("REQUEST_LEAVE_TUTORIAL_AREA", function(player: Player)
		if TutorialManager.isPlayerInTutorial(player) then
			TutorialManager.playerLeaveTutorialArea(player)
		end
	end)
end ]]--

function TutorialManager.playerEnterTutorialArea(player: Player): nil
	-- Debounce/lock
	local ok, msg = canBeginTransition(player)
	if not ok then
		if msg then RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", msg) end
		return
	end
	beginTransition(player)

	-- Always clear lock at the end
	local success, err = pcall(function()
		if not tutorialMap then
			RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", "Cannot enter tutorial area: something went wrong.")
			return
		end

		RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "TUTORIAL")
		PlayerPool.removeFromPool(player)

		inTutorial[player.UserId] = true
		ToolManager.ensureTool(player)
		TeleportManager.teleport(player, getMapTeleportPoint(), true)
	end)

	endTransition(player)
	if not success then
		warn("[TutorialManager] enter failed: ", err)
	end
end

function TutorialManager.playerLeaveTutorialArea(player: Player): nil
	-- Debounce/lock
	local ok, msg = canBeginTransition(player)
	if not ok then
		if msg then RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", msg) end
		return
	end
	beginTransition(player)

	local success, err = pcall(function()
		inTutorial[player.UserId] = nil
		if player.Character and lobbySpawn then
			RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "INTERMISSION")
			task.wait(1)
			if player.Character then
				TeleportManager.teleport(player, lobbySpawn.Position + Vector3.new(0, LOBBY_Y_OFFSET, 0))
			end
			task.wait(1)
			PlayerPool.addToPool(player)
		end
	end)

	endTransition(player)
	if not success then
		warn("[TutorialManager] leave failed: ", err)
	end
end

return TutorialManager
