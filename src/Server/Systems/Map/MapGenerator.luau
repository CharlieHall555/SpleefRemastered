local MapGenerator = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LavaManager = require(ModuleDirectory.Systems.Gameplay.LavaManager)
local LayerGenerator = require(ModuleDirectory.Systems.Map.LayerFactory)
local PlaneFactory = require(ModuleDirectory.Systems.Map.PlaneFactory)
local MapDataFactory = require(ModuleDirectory.Systems.Map.MapDataFactory)
local MapBuilder = require(ModuleDirectory.Systems.Map.MapBuilder)
local Map = require(ModuleDirectory.Systems.Map.Map)
local BackgroundFolder : Folder?

function MapGenerator.init()
    BackgroundFolder = game:GetService("ServerStorage"):WaitForChild("Background")
    assert(BackgroundFolder)
end

function MapGenerator.generate(params : MapDataFactory.MapDataCreationParams) : Map.Map
    
    local backgroundName = params.background

    --load background
    local template = BackgroundFolder:FindFirstChild(backgroundName) or BackgroundFolder.Background1
    local newBackground = template:Clone()

    if newBackground.PrimaryPart == nil then
        error("Background model " .. newBackground.Name .. " is missing a PrimaryPart.")
    end

    newBackground:PivotTo(CFrame.new(params.originPosition or Vector3.new(0,0,0)))
    newBackground.Parent = game.Workspace

    local origin = newBackground.MapOrigin.Position or Vector3.new(0,0,0)
    params.originPosition = origin

    local MapData = MapDataFactory.create(params)
    print("generate complete.")
    local map = MapBuilder.build(MapData)
    map.background = newBackground
    newBackground.Name = "background"
    LavaManager.setLava(newBackground:FindFirstChild("Lava"))
    return map

end

return MapGenerator
