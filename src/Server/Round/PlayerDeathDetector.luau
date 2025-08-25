local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RoundSystem = require(ModuleDirectory.Round.RoundSystem)
local PlayersInGame = require(ModuleDirectory.Round.PlayersInGame)
local Players = game:GetService("Players")

local connections = {}

local onDeathCallback : (player : Player , wasAlive : boolean) -> () = nil
local PlayerDeathDetector = {}

export type playerDeathRecord = {
	userId: number,
	timeOfDeath: number,
}

local playerDeathCache: { [number]: playerDeathRecord } = {}

function PlayerDeathDetector.init()
	
    for _ , eachPlayer in Players:GetPlayers() do
        print(eachPlayer)
        PlayerDeathDetector.setUpConnection(eachPlayer)
    end

	Players.PlayerAdded:Connect(PlayerDeathDetector.setUpConnection)

	Players.PlayerRemoving:Connect(function(player)
		local connection = connections[player.UserId]
		if connection then
			connection:Disconnect()
		end
	end)
end

local function onDied(player)
	local wasAlive = false
    print(player.Name .. " died")
    if RoundSystem.getState() == "ACTIVE" or RoundSystem.getState() == "PREPARING" then
		wasAlive = PlayersInGame.isAlive(player) or false
        PlayersInGame.removePlayer(player)

        playerDeathCache[player.UserId] = {
            userId = player.UserId,
            timeOfDeath = time(),
        }
    end
    if onDeathCallback then
        onDeathCallback(player , wasAlive)
    end
end

function PlayerDeathDetector.setUpConnection(player: Player)
	local deathConnection = nil

    if player.Character then
        local humanoid =  player.Character:WaitForChild("Humanoid")
		deathConnection = humanoid.Died:Connect(function()
			onDied(player)
		end)
    end

	connections[player.UserId] = player.CharacterAdded:Connect(function(character)
		if deathConnection then
			deathConnection:Disconnect()
		end
		local humanoid = character:WaitForChild("Humanoid")
		deathConnection = humanoid.Died:Connect(function()
			onDied(player)
		end)
	end)
end

function PlayerDeathDetector.getDeathTime(player: Player): number?
	local record = playerDeathCache[player.UserId]
	if record then
		return record.timeOfDeath
	else
		return nil
	end
end

function PlayerDeathDetector.clearCache()
	for eachKey, _ in playerDeathCache do
		playerDeathCache[eachKey] = nil
	end
end

function PlayerDeathDetector.setCallback(func: (player : Player , wasAlive : boolean) -> ())
	onDeathCallback = func
end

return PlayerDeathDetector
