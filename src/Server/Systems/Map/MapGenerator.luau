local MapGenerator = {}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local LavaManager = require(ModuleDirectory.Gameplay.LavaManager)
local LayerGenerator = require(ModuleDirectory.Map.LayerFactory)
local PlaneFactory = require(ModuleDirectory.Map.PlaneFactory)
local MapDataFactory = require(ModuleDirectory.Map.MapDataFactory)
local MapBuilder = require(ModuleDirectory.Map.MapBuilder)
local Map = require(ModuleDirectory.Map.Map)
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
