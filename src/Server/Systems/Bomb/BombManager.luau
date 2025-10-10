local RunService = game:GetService("RunService")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Bomb = require(ModuleDirectory.Bomb.Bomb)
local BlockFactory = require(ModuleDirectory.Map.BlockFactory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local bombs = {}

local bombOverlapParams = OverlapParams.new() 
bombOverlapParams.CollisionGroup = "CG_EXPLOSION"

local BOMB_COUNTDOWN = 3
local BOMB_EXPLOSION_RADIUS = 10

local BombManager = {}


local function onExplode(id :number, pos : number , radius : number, owner : Player?)
    
    RemoteEventHandler.FireOnAllClients("EXPLOSION" , pos , radius)

    local parts = workspace:GetPartBoundsInRadius(pos, radius, bombOverlapParams)

    for i, part in pairs(parts) do
        local blockId = part:GetAttribute("Id")
        BlockFactory.destroyById(blockId , owner)
    end

    bombs[id] = nil
    
end

function Bomb.init()
    
    RunService.Heartbeat:Connect(function(dt)
        for _, bomb in pairs(bombs) do
            bomb:loop(dt)
        end
    end)

end

function BombManager.createBomb(position) : Bomb.Bomb
    
    local newBomb = Bomb.new(BOMB_COUNTDOWN, position, BOMB_EXPLOSION_RADIUS, onExplode)
    bombs[newBomb.id] = newBomb
    return newBomb

end

return BombManager