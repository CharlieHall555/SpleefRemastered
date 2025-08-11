local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PartPool = require(ModuleDirectory.PartPool)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = game:GetService("ServerScriptService").ServerConfigurations

export type SnowBallPickup = {
    part: Part,
    position: Vector3,
    increment : number,
    id: number
}

local Loaded: { [number]: SnowBallPickup } = {}

local SnowballAmmoPickup = {}

local _container: Folder? = nil
local _nextId = 0

local function _newId(): number
    _nextId += 1
    return _nextId
end

local function _ensureContainer(): Folder
    if _container and _container.Parent then
        return _container
    end

    local existing = workspace:FindFirstChild("SnowballPickups")
    if existing and existing:IsA("Folder") then
        _container = existing
    else
        _container = Instance.new("Folder")
        _container.Name = "SnowballPickups"
        _container.Parent = workspace
    end

    return _container
end

local function _createPart(id : number): Part
    local part = PartPool.take()
    if not part then
        part = Instance.new("Part")
    end

    part.Name = "SnowballPickup"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = true
    part.CanTouch = true
    part:AddTag("SNOWBALL_AMMO")
    part:SetAttribute("id" , id)
    part.CastShadow = false
    part.Size = Vector3.new(2, 2, 2)
    part.Material = Enum.Material.Snow
    part.Shape = Enum.PartType.Ball
    part.Color = Color3.fromRGB(255, 255, 255)
    part.Transparency = 0

    return part
end

function SnowballAmmoPickup.reset() : nil

    for id , _ in Loaded do
        SnowballAmmoPickup.remove(id)
    end

end

function SnowballAmmoPickup.init(): nil
    _ensureContainer()
    table.clear(Loaded)
end

function SnowballAmmoPickup.new(spawnPosition: Vector3): number
    local container = _ensureContainer()
    local id = _newId()

    local part = _createPart(id)

    part.CFrame = CFrame.new(spawnPosition)
    part.Parent = container
    local increment = Config.AMMO_PICKUP_VALUE or 1
    part:SetAttribute("Increment" , increment)
    part:SetAttribute("Id", id)

    Loaded[id] = {
        part = part,
        position = spawnPosition,
        id = id,
        increment = Config.increment
    }

    return id

end

function SnowballAmmoPickup.get(id: number): SnowBallPickup?
    return Loaded[id]

end

function SnowballAmmoPickup.remove(id: number): nil
    local pickup = Loaded[id]
    if not pickup then
        return
    end

    if pickup.part and pickup.part.Parent then
        pickup.part.Parent = nil
    end
    PartPool.add(pickup.part)
    Loaded[id] = nil

end

return SnowballAmmoPickup