local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PartPool = require(ModuleDirectory.PartPool)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)



export type SnowBallPickup = {
    part: Part,
    position: Vector3,
    increment : number,
    id: number
}

local SnowballAmmoPickup = {}

local Loaded: { [number]: SnowBallPickup } = {}
local snowballAmmoTemplate : Model 

local _container: Folder? = nil
local _nextId = 0

local onRemoveCallback : (idRemoved : number) -> ()?

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


function SnowballAmmoPickup.reset() : nil

    for id , _ in Loaded do
        SnowballAmmoPickup.remove(id)
    end

end

function SnowballAmmoPickup.setOnRemoveCallback(fn : (removedId : number) -> ())

    onRemoveCallback = fn

end

function SnowballAmmoPickup.init(): nil
    _ensureContainer()
    snowballAmmoTemplate = game:GetService("ReplicatedStorage"):WaitForChild("Resources"):WaitForChild("AmmoTemplate")
    table.clear(Loaded)
end

function SnowballAmmoPickup.new(spawnPosition: Vector3): number
    local container = _ensureContainer()
    local id = _newId()

    local part = snowballAmmoTemplate:Clone()
    part.CFrame = CFrame.new(spawnPosition)
    local increment = Config.AMMO_PICKUP_VALUE or 1
    part:AddTag("SNOWBALL_AMMO")
    part:SetAttribute("Increment" , increment)
    part:SetAttribute("Id", id)
    part.Parent = container

    Loaded[id] = {
        part = part,
        position = spawnPosition,
        id = id,
        increment = Config.AMMO_PICKUP_VALUE
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
    pickup.part:Destroy()
    Loaded[id] = nil

    if onRemoveCallback then
        onRemoveCallback(id)
    end

end

return SnowballAmmoPickup