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

-- state
local tutorialMap: Map.Map?
local lobbySpawn: SpawnLocation?
local inTutorial: { [number]: boolean } = {}
local charAddedConns: { [number]: RBXScriptConnection } = {}

-- utils
local function getMapTeleportPoint(): Vector3
    if tutorialMap and tutorialMap.OriginPosition then
        return tutorialMap.OriginPosition + Vector3.new(0, TUTORIAL_TELEPORT_HEIGHT, 0)
    end
    return Vector3.new(0, 0, 0)
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
            TeleportManager.teleport(player, getMapTeleportPoint(), true)
        end
    end)
end

local function cleanupPlayer(player: Player)
    inTutorial[player.UserId] = nil
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

function TutorialManager.init(): nil

	 RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        PlayerPool.addToPool(player)
        if PlayerData.gethasJoinedBefore(player) then
            PlayerPool.addToPool(player)
		else
            task.wait(1)
            TutorialManager.playerEnterTutorialArea(player)
			task.wait(10)
			if TutorialManager.isPlayerInTutorial(player) == false then
				PlayerPool.addToPool(player)
			end
        end
    end)

    RemoteEventHandler.newEventConnection("TUTORIAL_COMPLETED" , function(player)
        
        if TutorialManager.isPlayerInTutorial(player) then
            TutorialManager.playerLeaveTutorialArea(player)
        end

    end)

    lobbySpawn = workspace:WaitForChild("Lobby"):WaitForChild("SpawnLocation") :: SpawnLocation
    tutorialMap = MapGenerator.generate(TutorialMap)

    -- lava -> respawn back to tutorial spawn
    ServerHitBoxManager.setUpCallback("TestLava", function(player: Player, _otherPart: BasePart)
        if player.Character then
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
end

function TutorialManager.playerEnterTutorialArea(player: Player): nil
    if not tutorialMap then
        RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", "Cannot enter tutorial area: something went wrong.")
        return
    end

    RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "TUTORIAL")
    PlayerPool.removeFromPool(player)

    inTutorial[player.UserId] = true
    ToolManager.ensureTool(player)
    TeleportManager.teleport(player, getMapTeleportPoint(), true)
end

function TutorialManager.playerLeaveTutorialArea(player: Player): nil
    inTutorial[player.UserId] = nil
    if player.Character and lobbySpawn then
        RemoteEventHandler.FireOnClient(player, "CHANGE_STATE", "INTERMISSION")
        task.wait(1)
        if player.Character then
            TeleportManager.teleport(player, lobbySpawn.Position + Vector3.new(0, LOBBY_Y_OFFSET, 0))
        end
    end
end

return TutorialManager
