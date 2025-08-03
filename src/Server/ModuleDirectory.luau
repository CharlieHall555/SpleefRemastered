local ModuleDirectory = {}

-- Core Scripts
ModuleDirectory.ServerEventHandler = game:GetService("ServerScriptService").Core.ServerEventHandler
ModuleDirectory.ValueBinder = game:GetService("ServerScriptService").Core.ValueBinder

-- Model Inventory
ModuleDirectory.Container = game:GetService("ServerScriptService").Model.Inventory.Container
ModuleDirectory.Slot = game:GetService("ServerScriptService").Model.Inventory.Slot


-- Map Generation System
ModuleDirectory.Map = {}
ModuleDirectory.Map.Block = game:GetService("ServerScriptService").Map.Model.Block
ModuleDirectory.Map.Layer = game:GetService("ServerScriptService").Map.Model.Layer
ModuleDirectory.Map.Map = game:GetService("ServerScriptService").Map.Model.Map

ModuleDirectory.Map.PlaneFactory = game:GetService("ServerScriptService").Map.PlaneFactory
ModuleDirectory.Map.LayerFactory = game:GetService("ServerScriptService").Map.LayerFactory
ModuleDirectory.Map.MapDataFactory = game:GetService("ServerScriptService").Map.MapDataFactory
ModuleDirectory.Map.MapBuilder = game:GetService("ServerScriptService").Map.MapBuilder
ModuleDirectory.Map.MapGenerator = game:GetService("ServerScriptService").Map.MapGenerator


-- Model Player
ModuleDirectory.PlayerData = game:GetService("ServerScriptService").Model.Player.PlayerData


-- Utilities
ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool




-- Resources
ModuleDirectory.Materials = game:GetService("ServerScriptService").Resources.Materials

-- Loaded Assets
ModuleDirectory.LoadedBlocks = game:GetService("ServerScriptService").Loaded.Block

-- Remote Handlers
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler

return ModuleDirectory