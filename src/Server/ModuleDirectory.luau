local ModuleDirectory = {}

-- Core Scripts
ModuleDirectory.ServerEventHandler = game:GetService("ServerScriptService").Core.ServerEventHandler
ModuleDirectory.ValueBinder = game:GetService("ServerScriptService").Core.ValueBinder
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler
ModuleDirectory.Setup = game:GetService("ServerScriptService").Core.Setup

--//====================================================
--// Round System
--//====================================================

ModuleDirectory.Round = {}
ModuleDirectory.Round.PlayerPool = game:GetService("ServerScriptService").Round.PlayerPool
ModuleDirectory.Round.PlayersInGame = game:GetService("ServerScriptService").Round.PlayersInGame
ModuleDirectory.Round.PlayerDeathDetector = game:GetService("ServerScriptService").Round.PlayerDeathDetector
ModuleDirectory.Round.TeleportManager = game:GetService("ServerScriptService").Round.TeleportManager
ModuleDirectory.Round.RoundManager = game:GetService("ServerScriptService").Round.RoundManager
ModuleDirectory.Round.WinnerDetection = game:GetService("ServerScriptService").Round.WinnerDetection
ModuleDirectory.Round.RoundSystem = game:GetService("ServerScriptService").Round.RoundSystem
ModuleDirectory.Round.SuddenDeath = game:GetService("ServerScriptService").Round.SuddenDeath

--//====================================================
--// Throwable System
--//====================================================

ModuleDirectory.Throwable = {}
ModuleDirectory.Throwable.Throwable = game:GetService("ServerScriptService").Throwable.Throwable
ModuleDirectory.Throwable.ThrowableManager = game:GetService("ServerScriptService").Throwable.ThrowableManager
ModuleDirectory.Throwable.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData
ModuleDirectory.Throwable.AmmoManager = game:GetService("ServerScriptService").Gameplay.AmmoManager
ModuleDirectory.Throwable.PlayerRaycastParamsHandler = game:GetService("ServerScriptService").Throwable.PlayerRaycastParmsHandler
ModuleDirectory.Throwable.SnowballManager = game:GetService("ServerScriptService").Throwable.SnowballManager

--//====================================================
--// Map System
--//====================================================

ModuleDirectory.Map = {}
-- Models
ModuleDirectory.Map.Block = game:GetService("ServerScriptService").Map.Model.Block
ModuleDirectory.Map.Layer = game:GetService("ServerScriptService").Map.Model.Layer
ModuleDirectory.Map.Map = game:GetService("ServerScriptService").Map.Model.Map
ModuleDirectory.Map.Saves = game:GetService("ServerScriptService").Map.MapSaves
ModuleDirectory.Map.Obstacle = game:GetService("ServerScriptService").Map.Model.Obstacle

-- Factories
ModuleDirectory.Map.BlockFactory = game:GetService("ServerScriptService").Map.BlockFactory
ModuleDirectory.Map.PlaneFactory = game:GetService("ServerScriptService").Map.PlaneFactory
ModuleDirectory.Map.LayerFactory = game:GetService("ServerScriptService").Map.LayerFactory
ModuleDirectory.Map.MapDataFactory = game:GetService("ServerScriptService").Map.MapDataFactory
ModuleDirectory.Map.ObstacleFactory = game:GetService("ServerScriptService").Map.ObstacleFactory

-- Builders / Generators
ModuleDirectory.Map.MapBuilder = game:GetService("ServerScriptService").Map.MapBuilder
ModuleDirectory.Map.MapGenerator = game:GetService("ServerScriptService").Map.MapGenerator

--//====================================================
--// Gameplay Managers
--//====================================================
ModuleDirectory.Gameplay = {}

ModuleDirectory.Gameplay.BlockDestructionTracker = game:GetService("ServerScriptService").Gameplay.BlockDestructionTracker
ModuleDirectory.Gameplay.ServerHitBoxManager = game:GetService("ServerScriptService").Gameplay.ServerHitBoxManager
ModuleDirectory.Gameplay.KickManager = game:GetService("ServerScriptService").KickManager
ModuleDirectory.Gameplay.SnowballAmmoPickup = game:GetService("ServerScriptService").Throwable.SnowballAmmoPickup
ModuleDirectory.Gameplay.AmmoPickupManager = game:GetService("ServerScriptService").Gameplay.AmmoPickupManager
ModuleDirectory.Gameplay.ToolManager = game:GetService("ServerScriptService").Gameplay.ToolManager
ModuleDirectory.Gameplay.KnockBackManager = game:GetService("ServerScriptService").Gameplay.KnockbackManager

--//====================================================
--// Player Systems
--//====================================================
ModuleDirectory.Player = {}
ModuleDirectory.Player.PlayerData = game:GetService("ServerScriptService").Player.PlayerData
ModuleDirectory.Player.Leaderstats = game:GetService("ServerScriptService").Player.Leaderstats
ModuleDirectory.Player.PlayerManager = game:GetService("ServerScriptService").Player.PlayerManager
ModuleDirectory.Player.PlayerPositionTracker = game:GetService("ServerScriptService").Player.PlayerPositionTracker

--//====================================================
--// Utilities
--//====================================================
ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil
ModuleDirectory.Timer = game:GetService("ReplicatedStorage").Utilities.Timer
ModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions

--//====================================================
--// Utilities
--//====================================================
ModuleDirectory.Resources = {}
ModuleDirectory.Resources.Materials = game:GetService("ServerScriptService").Resources.Materials

-- Loaded Assets
ModuleDirectory.LoadedBlocks = game:GetService("ServerScriptService").Loaded.Block
ModuleDirectory.LoadedLayers = game:GetService("ServerScriptService").Loaded.Layer

--//====================================================
--// Analytics
--//====================================================
ModuleDirectory.Analytics = {}
ModuleDirectory.Analytics.Onboarding = game:GetService("ServerScriptService").Analytics.Onboarding

ModuleDirectory.Materials = game:GetService("ServerScriptService").Resources.Materials

-- Remote Handlers

return ModuleDirectory