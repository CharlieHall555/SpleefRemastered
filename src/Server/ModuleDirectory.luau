local ModuleDirectory = {}

-- Core Scripts
ModuleDirectory.ServerEventHandler = game:GetService("ServerScriptService").Core.ServerEventHandler
ModuleDirectory.ValueBinder = game:GetService("ServerScriptService").Core.ValueBinder

-- Model Inventory
ModuleDirectory.Container = game:GetService("ServerScriptService").Model.Inventory.Container
ModuleDirectory.Slot = game:GetService("ServerScriptService").Model.Inventory.Slot

-- Model Player
ModuleDirectory.PlayerData = game:GetService("ServerScriptService").Model.Player.PlayerData
ModuleDirectory.Map = {}
ModuleDirectory.Map.Block = game:GetService("ServerScriptService").Model.Map.Block
ModuleDirectory.Map.Grid = game:GetService("ServerScriptService").Model.Map.Grid

-- Utilities
ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool

ModuleDirectory.MapGenerator = game:GetService("ServerScriptService").Controller.MapGenerator

-- Resources
ModuleDirectory.Materials = game:GetService("ServerScriptService").Resources.Materials

-- Loaded Assets
ModuleDirectory.LoadedBlocks = game:GetService("ServerScriptService").Loaded.Block

-- Remote Handlers
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler

return ModuleDirectory