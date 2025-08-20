local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerHitBoxManager = {}

local tagCallback = {}

local _characterAddedConnections: {[number]: RBXScriptConnection} = {}
local _touchedConnections: {[number]: RBXScriptConnection} = {}
local _hitBoxes: {[number]: Part} = {}

local function createPlayerHitbox(): Part
    local hitbox = Instance.new("Part")
    hitbox.Name = "CentralHitbox"
    hitbox.Size = Vector3.new(4, 6, 4)
    hitbox.Transparency = 1
    hitbox.Color = Color3.new(0.145098, 0.839215, 0.050980)
    hitbox.Anchored = false
    hitbox.CanCollide = false
    hitbox.Massless = true
    hitbox.CastShadow = false
	hitbox:AddTag("PLAYER_HITBOX")
    hitbox.CollisionGroup = "CG_GAMEPLAY"
    hitbox.CanQuery = true
    hitbox.CanTouch = true
    hitbox.TopSurface = Enum.SurfaceType.Smooth
    hitbox.BottomSurface = Enum.SurfaceType.Smooth
    hitbox.Parent = workspace
    return hitbox
end

local function weldToCharacter(hitbox: Part, character: Model)
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then
        warn("Failed to find HumanoidRootPart to weld hitbox to")
        return
    end

    hitbox.Parent = character
    hitbox.Anchored = false
    hitbox.CFrame = hrp.CFrame

    for _, child in ipairs(hitbox:GetChildren()) do
        if child:IsA("WeldConstraint") then
            child:Destroy()
        end
    end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hitbox
    weld.Part1 = hrp
    weld.Parent = hitbox
end

local function cleanupPlayer(player: Player)
    local uid = player.UserId

    local touchConn = _touchedConnections[uid]
    if touchConn then
        touchConn:Disconnect()
        _touchedConnections[uid] = nil
    end

    local charConn = _characterAddedConnections[uid]
    if charConn then
        charConn:Disconnect()
        _characterAddedConnections[uid] = nil
    end

    local hitbox = _hitBoxes[uid]
    if hitbox then
        if hitbox.Parent then
            hitbox.Parent = nil
        end
        hitbox:Destroy()
        _hitBoxes[uid] = nil
    end
end

function ServerHitBoxManager.setUpCallback(tagName: string, callback: (player: Player, otherPart: Instance) -> nil)
    tagCallback[tagName] = callback
end

function ServerHitBoxManager.init()
    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        -- ensure previous state is cleared if re-fired
        cleanupPlayer(player)

        local uid = player.UserId
        local hitbox = createPlayerHitbox()
        _hitBoxes[uid] = hitbox

        if player.Character then
            weldToCharacter(hitbox, player.Character)
        end

        _characterAddedConnections[uid] = player.CharacterAdded:Connect(function(character)
            weldToCharacter(hitbox, character)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Died:Once(function()
                    -- detach and stop receiving touches on death
                    local tConn = _touchedConnections[uid]
                    if tConn then
                        tConn:Disconnect()
                        _touchedConnections[uid] = nil
                    end
                    hitbox.Anchored = true
                    hitbox.Parent = nil
                end)
            end
        end)

        _touchedConnections[uid] = hitbox.Touched:Connect(function(otherPart: BasePart)
            local tags = otherPart:GetTags()
            for _, each in tags do
                local f = tagCallback[each]
                if f then
                    f(player, otherPart)
                end
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        cleanupPlayer(player)
    end)
end

return ServerHitBoxManager
