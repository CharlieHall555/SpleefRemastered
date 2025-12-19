local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local SessionVariables = require(ModuleDirectory.Player.SessionVariables)
local RoundSystem = require(ModuleDirectory.Systems.Round.RoundSystem)
local PlayersInGame = require(ModuleDirectory.Systems.Round.PlayersInGame)
local PlayerPositionTracker = require(ModuleDirectory.Player.PlayerPositionTracker)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local RunService = game:GetService("RunService")

local AFKTracker = {}

local AFK_ELIMINATION_TIME = 25

local lastPositionByUid: { [number]: Vector3 } = {}


function systemMessage(player: Player, message: string)
	RemoteEventHandler.FireOnClient(player, "RECEIVE_SYSTEM_MESSAGE", message)
end

local function getAfkTime(player: Player): number
    local t = SessionVariables.getValue(player, "afkTime")
    if typeof(t) ~= "number" then
        return 0
    end
    return t
end

local function setAfkTime(player: Player, value: number)
    SessionVariables.setValue(player, "afkTime", value)
end

local function processPlayer(deltaTime: number, player: Player)
    if not PlayersInGame.isAlive(player) then
        return
    end

    local pos: Vector3? = PlayerPositionTracker.getPosition(player)
    if not pos then
        return
    end

    local uid = player.UserId
    local last = lastPositionByUid[uid]

    if last and last == pos then
        local newAfk = getAfkTime(player) + deltaTime
        setAfkTime(player, newAfk)

        if newAfk >= AFK_ELIMINATION_TIME then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
                if humanoid and humanoid.Health > 0 then
                    humanoid.Health = 0
					systemMessage(player , "ELIMINATED DUE TO AFK IN GAME.")
                end
            end
        end
    else
        setAfkTime(player, 0)
        lastPositionByUid[uid] = pos
    end
end

function AFKTracker.init()
    Players.PlayerRemoving:Connect(function(p)
        lastPositionByUid[p.UserId] = nil
    end)

    RunService.Heartbeat:Connect(function(deltaTime)
        if RoundSystem.getState() ~= "ACTIVE" then
            return
        end

        for _, player in Players:GetPlayers() do
            processPlayer(deltaTime, player)
        end
    end)
end

return AFKTracker
