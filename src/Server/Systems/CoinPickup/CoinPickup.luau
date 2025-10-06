local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local Config = require(game:GetService("ServerScriptService").ServerConfigurations)



export type CoinPickup = {
    part: Part,
    position: Vector3,
    id: number
}

local CoinAmmoPickup = {}

local Loaded: { [number]: CoinPickup } = {}
local coinAmmoTemplate : Model 

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

    local existing = workspace:FindFirstChild("CoinPickups")
    if existing and existing:IsA("Folder") then
        _container = existing
    else
        _container = Instance.new("Folder")
        _container.Name = "CoinPickups"
        _container.Parent = workspace
    end

    return _container
end


function CoinAmmoPickup.reset() : nil

    for id , _ in Loaded do
        CoinAmmoPickup.remove(id)
    end

end

function CoinAmmoPickup.setOnRemoveCallback(fn : (removedId : number) -> ())

    onRemoveCallback = fn

end

function CoinAmmoPickup.init(): nil
    _ensureContainer()
    coinAmmoTemplate = game:GetService("ReplicatedStorage"):WaitForChild("Resources"):WaitForChild("Coin")
    table.clear(Loaded)
end

function CoinAmmoPickup.new(spawnPosition: Vector3): number
    local container = _ensureContainer()
    local id = _newId()

    local part = coinAmmoTemplate:Clone()
    part.CFrame = CFrame.new(spawnPosition) * CFrame.Angles(math.rad(90), 0, 0)
    local increment = Config.AMMO_PICKUP_VALUE or 1
    part:AddTag("COIN_PICKUP")
    part:SetAttribute("Id", id)
    part.Parent = container

    Loaded[id] = {
        part = part,
        position = spawnPosition,
        id = id,
    }

    return id
end

function CoinAmmoPickup.get(id: number): CoinPickup?
    return Loaded[id]

end

function CoinAmmoPickup.remove(id: number): nil
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

return CoinAmmoPickup