local Config = require(game:GetService("ServerScriptService").ServerConfigurations)

local TeleportManager = {}

-- Optional failure callback
local failureCallback: ((playerWhoFailed: Player) -> nil)?

-- Helper to normalize input to a CFrame
local function toCFrame(position)
    if typeof(position) == "Vector3" then
        return CFrame.new(position)
    elseif typeof(position) == "CFrame" then
        return position
    else
        return nil
    end
end

-- Internal single-player teleport with optional retries
local function teleportSingle(player: Player, positionCFrame: CFrame, retry: boolean)
    if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
        warn("Player instance is nil or of wrong type.")
        return
    end

    local retries = retry and (tonumber(Config.TELEPORT_RETRIES) or 3) or 0
    local delayBetween = tonumber(Config.TELEPORT_RETRY_DELAY) or 1

    for attempt = 1, 1 + retries do
        local character = player.Character
        if not character then
            if attempt < 1 + retries then
                task.wait(delayBetween)
                continue
            else
                if failureCallback then
                    failureCallback(player)
                end
                return
            end
        end

        if not character.PrimaryPart then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:IsA("BasePart") then
                character.PrimaryPart = hrp
            end
        end

        if not character.PrimaryPart or not character.PrimaryPart:IsA("BasePart") then
            if attempt < 1 + retries then
                task.wait(delayBetween)
                continue
            else
                if failureCallback then
                    failureCallback(player)
                end
                return
            end
        end

        local success, err = pcall(function()
            character:PivotTo(positionCFrame)
        end)

        if success then
            return
        else
            if attempt < 1 + retries then
                task.wait(delayBetween)
            else
                if failureCallback then
                    failureCallback(player)
                end
                return
            end
        end
    end
end

function TeleportManager.init()
    -- currently nothing to initialize
end

function TeleportManager.teleport(player: Player, position: Vector3 | CFrame, retry: boolean?)
    local targetCFrame = toCFrame(position)
    retry = retry or false
    if not targetCFrame then
        warn("TeleportManager.teleport called with invalid position type:", typeof(position))
        if failureCallback then
            failureCallback(player)
        end
        return
    end

    task.spawn(function()
        teleportSingle(player, targetCFrame, retry)
    end)
end

function TeleportManager.teleportPlayers(
    players: { Player }, position: Vector3 | CFrame, retry: boolean)
    local targetCFrame = toCFrame(position)
    if not targetCFrame then
        warn("TeleportManager.teleportPlayers called with invalid position type:", typeof(position))
        return
    end

    for _, player in ipairs(players) do
        if typeof(player) == "Instance" and player:IsA("Player") then
            task.spawn(function()
                teleportSingle(player, targetCFrame, retry)
            end)
        end
    end
end

function TeleportManager.setCallback(func: (playerWhoFailed: Player) -> nil)
    failureCallback = func
end

return TeleportManager