local ModuleDirectory = {}

-- Core Scripts
ModuleDirectory.ServerEventHandler = game:GetService("ServerScriptService").Core.ServerEventHandler
ModuleDirectory.ValueBinder = game:GetService("ServerScriptService").Core.ValueBinder

-- Model Inventory
ModuleDirectory.Container = game:GetService("ServerScriptService").Model.Inventory.Container
ModuleDirectory.Slot = game:GetService("ServerScriptService").Model.Inventory.Slot

ModuleDirectory.PlayerPool = game:GetService("ServerScriptService").Round.PlayerPool
ModuleDirectory.PlayersInGame = game:GetService("ServerScriptService").Round.PlayersInGame
ModuleDirectory.PlayerDeathDetector = game:GetService("ServerScriptService").Round.PlayerDeathDetector
ModuleDirectory.TeleportManager = game:GetService("ServerScriptService").Round.TeleportManager
ModuleDirectory.RoundManager = game:GetService("ServerScriptService").Round.RoundManager
ModuleDirectory.PlayerPositionTracker = game:GetService("ServerScriptService").Gameplay.PlayerPositionTracker
ModuleDirectory.WinnerDetection = game:GetService("ServerScriptService").Round.WinnerDetection

ModuleDirectory.Throwable = game:GetService("ServerScriptService").Throwable.Throwable
ModuleDirectory.ThrowableManager = game:GetService("ServerScriptService").Throwable.ThrowableManager
ModuleDirectory.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData

-- Map Generation System
ModuleDirectory.Map = {}
ModuleDirectory.Map.Block = game:GetService("ServerScriptService").Map.Model.Block
ModuleDirectory.Map.Layer = game:GetService("ServerScriptService").Map.Model.Layer
ModuleDirectory.Map.Map = game:GetService("ServerScriptService").Map.Model.Map
ModuleDirectory.Map.BlockFactory = game:GetService("ServerScriptService").Map.BlockFactory

ModuleDirectory.Map.PlaneFactory = game:GetService("ServerScriptService").Map.PlaneFactory
ModuleDirectory.Map.LayerFactory = game:GetService("ServerScriptService").Map.LayerFactory
ModuleDirectory.Map.MapDataFactory = game:GetService("ServerScriptService").Map.MapDataFactory
ModuleDirectory.Map.MapBuilder = game:GetService("ServerScriptService").Map.MapBuilder
ModuleDirectory.Map.MapGenerator = game:GetService("ServerScriptService").Map.MapGenerator

ModuleDirectory.RoundSystem = game:GetService("ServerScriptService").Round.RoundSystem

ModuleDirectory.SnowballManager = game:GetService("ServerScriptService").Throwable.SnowballManager
ModuleDirectory.SuddenDeath = game:GetService("ServerScriptService").Round.SuddenDeath

-- Model Player
ModuleDirectory.PlayerData = game:GetService("ServerScriptService").Model.Player.PlayerData

-- Utilities
ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil
ModuleDirectory.Timer = game:GetService("ReplicatedStorage").Utilities.Timer
ModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions

-- Resources
ModuleDirectory.Materials = game:GetService("ServerScriptService").Resources.Materials

-- Loaded Assets
ModuleDirectory.LoadedBlocks = game:GetService("ServerScriptService").Loaded.Block
ModuleDirectory.LoadedLayers = game:GetService("ServerScriptService").Loaded.Layer


-- Remote Handlers
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler

return ModuleDirectory