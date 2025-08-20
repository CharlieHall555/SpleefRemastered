local Players = game:GetService("Players")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local GUISpectateControls = require(ClientModuleDirectory.Gui.SpectateControls)
local LocalPlayer = Players.LocalPlayer

local SpectateController = {}

local playersAlive: { Player } = {}

local enabled = false

local currentIndex: number? = nil
local currentTarget: Player? = nil
local camera: Camera? = nil
local charDestroyedConnection: RBXScriptConnection? = nil

local function setUpGuiConnections()
    
    GUISpectateControls.connectOnExit(function()
        SpectateController.exit()
    end)

    GUISpectateControls.connectOnBack(function()
        SpectateController.previousIndex()
    end)

    GUISpectateControls.connectOnNext(function()
        SpectateController.nextIndex()
    end)

    GUISpectateControls.connectOnCelebrate(function()
        SpectateController.exit()
    end)

end

local function bindIndex(index: number, list: {})
    local n = #list
    if n == 0 then
        return nil
    end
    return ((index - 1) % n) + 1
end

local function clearCharConn()
    if charDestroyedConnection then
        charDestroyedConnection:Disconnect()
        charDestroyedConnection = nil
    end
end

local function setCameraToLocal()
    if not camera then
        return
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    camera.CameraType = Enum.CameraType.Custom
    if hum then
        camera.CameraSubject = hum
    end
end

local function setTarget(player: Player): boolean
    if not camera then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then
        return false
    end

    clearCharConn()
    charDestroyedConnection = player.CharacterRemoving:Connect(function()
        -- When this target's character is removed, drop them from the list.
        local pos = table.find(playersAlive, player)
        if pos then
            table.remove(playersAlive, pos)
        end
        currentTarget = nil
        SpectateController.previousIndex()
    end)

    camera.CameraType = Enum.CameraType.Follow
    camera.CameraSubject = hum
    GUISpectateControls.setPlayerSpectating(player.Name)

    currentTarget = player
    return true
end

local function onPlayerListUpdate()
    if not enabled then
        return
    end

    if #playersAlive == 0 then
        currentIndex = nil
        currentTarget = nil
        clearCharConn()
        SpectateController.exit()
        return
    end

    if currentTarget then
        local pos = table.find(playersAlive, currentTarget)
        if pos then
            currentIndex = pos
            return
        end
    end

    local nextIndex = bindIndex((currentIndex or 1) - 1, playersAlive)
    if nextIndex then
        currentIndex = nextIndex
        setTarget(playersAlive[currentIndex])
    else
        SpectateController.exit()
    end
end

local function removePlayer(player: Player)
    local pos = table.find(playersAlive, player)
    if pos then
        table.remove(playersAlive, pos)
        onPlayerListUpdate()
    end
end

local function canEnterSpecate(): boolean
    return (ClientStateTracker.getServerState() == "ACTIVE" or ClientStateTracker.getServerState() == "PREPARING") and ClientStateTracker.getState() == "INTERMISSION"
end

local function setUpHardExits()
    ClientStateTracker.connectActive(function()
        SpectateController.exit()
    end)

    ClientStateTracker.connectRoundStarting(function()
        SpectateController.exit()
    end)

    ClientStateTracker.connectServerStateChange(function(newServerState)
        if newServerState == "INTERMISSION" then
            playersAlive = {}
            SpectateController.exit()
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        SpectateController.exit()
    end)
end

function SpectateController.onLoaded()
    camera = workspace.CurrentCamera
    setUpHardExits()

    RemoteEventHandler.newEventConnection("SEND_STARTING_PLAYERS", function(startingPlayers: { Player })
        playersAlive = startingPlayers or {}
        onPlayerListUpdate()
    end)

    RemoteEventHandler.newEventConnection("PLAYER_DIED", function(player: Player)
        removePlayer(player)
    end)

    setUpGuiConnections()
end

function SpectateController.enter(): nil
    if enabled then
        return
    end

    if not canEnterSpecate() then
        return
    end

    if #playersAlive == 0 then
        playersAlive = RemoteEventHandler.InvokeOnServer("QUERY_ALIVE" , 2)
    end

    if #playersAlive == 0 then
		print("no players alive")
        return
    end

    enabled = true
    GUISpectateControls.show()

    currentIndex = currentIndex or 1
    currentIndex = bindIndex(currentIndex, playersAlive)
    if currentIndex == nil then
        enabled = false
        return
    end

    if not setTarget(playersAlive[currentIndex]) then
        -- Try to advance until a valid target is found or give up.
        for i = 1, #playersAlive do
            currentIndex = bindIndex((currentIndex or 1) + 1, playersAlive)
            if currentIndex and setTarget(playersAlive[currentIndex]) then
                break
            end
        end
        if not currentTarget then
            enabled = false
            setCameraToLocal()
        end
    end
end

function SpectateController.exit(): nil
    if not enabled then
        return
    end

    enabled = false
    GUISpectateControls.hide()
    clearCharConn()
    currentTarget = nil
    currentIndex = nil
    setCameraToLocal()
end

function SpectateController.getEnabled(): boolean
    return enabled
end

function SpectateController.nextIndex()
    if not enabled or #playersAlive == 0 then
        return
    end
    currentIndex = bindIndex((currentIndex or 1) + 1, playersAlive)
    if currentIndex then
        if not setTarget(playersAlive[currentIndex]) then
            removePlayer(playersAlive[currentIndex])
        end
    end
end

function SpectateController.previousIndex()
    if not enabled or #playersAlive == 0 then
        return
    end
    currentIndex = bindIndex((currentIndex or 1) - 1, playersAlive)
    if currentIndex then
        if not setTarget(playersAlive[currentIndex]) then
            removePlayer(playersAlive[currentIndex])
        end
    end
end

function SpectateController.toggle()

	if enabled == false then
		SpectateController.enter()
	else
		SpectateController.exit()
	end
	
end

return SpectateController
