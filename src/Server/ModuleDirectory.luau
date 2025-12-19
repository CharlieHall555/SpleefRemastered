local serverRoot = game:GetService("ServerScriptService")
local sharedRoot = game:GetService("ReplicatedStorage")
local ModuleDirectory = {}

-- Core Scripts
ModuleDirectory.ServerEventHandler = serverRoot.Core.ServerEventHandler
ModuleDirectory.ValueBinder = serverRoot.Core.ValueBinder
ModuleDirectory.RemoteEventHandler = sharedRoot.RemoteEventHandler
ModuleDirectory.Setup = serverRoot.Core.Setup
ModuleDirectory.ServerStatus = serverRoot.ServerStatus

ModuleDirectory.Systems = {}

--//====================================================
--// Round System
--//====================================================


ModuleDirectory.Systems.Round = {}
ModuleDirectory.Systems.Round.PlayerPool = serverRoot.Systems.Round.PlayerPool
ModuleDirectory.Systems.Round.PlayersInGame =serverRoot.Systems.Round.PlayersInGame
ModuleDirectory.Systems.Round.PlayerDeathDetector = serverRoot.Systems.Round.PlayerDeathDetector
ModuleDirectory.Systems.Round.TeleportManager = serverRoot.Systems.Round.TeleportManager
ModuleDirectory.Systems.Round.RoundManager = serverRoot.Systems.Round.RoundManager
ModuleDirectory.Systems.Round.RoundSystem = serverRoot.Systems.Round.RoundSystem
ModuleDirectory.Systems.Round.SuddenDeath = serverRoot.Systems.Round.SuddenDeath
ModuleDirectory.Systems.Round.MapSelection = serverRoot.Systems.Round.MapSelection
ModuleDirectory.Systems.Round.ClearLobby = serverRoot.Systems.Round.ClearLobby
ModuleDirectory.Systems.Round.PodiumManager = serverRoot.Systems.Round.PodiumManager
ModuleDirectory.Systems.Round.AFKTracker = serverRoot.Systems.Round.AFKTracker

ModuleDirectory.Abilities = {}
ModuleDirectory.Abilities.Main = serverRoot.Systems.Abilities.AblilitiesMain
ModuleDirectory.Abilities.Functions = serverRoot.Systems.Abilities.AbilitiesFunctions
ModuleDirectory.Abilities.Definitions = sharedRoot.Data.AbilitiesDefinitions
ModuleDirectory.Abilities.EndFunctions = serverRoot.Systems.Abilities.EndFunctions
ModuleDirectory.Abilities.TeleportAbility = serverRoot.Systems.Abilities.TeleportAbility


--//====================================================
--// AGENT System
--//====================================================

ModuleDirectory.Systems.Agent = {}
ModuleDirectory.Systems.Agent.AgentManager = serverRoot.Systems.Agent.AgentManager
ModuleDirectory.Systems.Agent.Agent = serverRoot.Systems.Agent.Agent
ModuleDirectory.Systems.Agent.CharacterGeneration = serverRoot.Systems.Agent.CharacterGeneration
ModuleDirectory.Systems.Agent.Movement = serverRoot.Systems.Agent.Components.AgentMovement
ModuleDirectory.Systems.Agent.Combat = serverRoot.Systems.Agent.Components.AgentCombat
ModuleDirectory.Systems.Agent.TileScoring = serverRoot.Systems.Agent.TileScoring

--//====================================================
--// StatsTracker System
--//====================================================

ModuleDirectory.Systems.Stats = {}
ModuleDirectory.Systems.Stats.WinnerDetection = serverRoot.Systems.StatsTrackers.WinnerDetection
ModuleDirectory.Systems.Stats.TouchedBlockTracker = serverRoot.Systems.StatsTrackers.TouchedBlockTracker
ModuleDirectory.Systems.Stats.RoundSummary =  serverRoot.Systems.StatsTrackers.RoundSummary
ModuleDirectory.Systems.Stats.KnockbackTracker = serverRoot.Systems.StatsTrackers.KnockbackTracker
ModuleDirectory.Systems.Stats.EliminationTracker = serverRoot.Systems.StatsTrackers.EliminationTracker

--//====================================================
--// Throwable System
--//====================================================

ModuleDirectory.Throwable = {}
ModuleDirectory.Throwable.Throwable = serverRoot.Systems.Throwable.Throwable
ModuleDirectory.Throwable.ThrowableManager = serverRoot.Systems.Throwable.ThrowableManager
ModuleDirectory.Throwable.ThrowableData = sharedRoot.Types.ThrowableData
ModuleDirectory.Throwable.PlayerRaycastParamsHandler = serverRoot.Systems.Throwable.PlayerRaycastParmsHandler
ModuleDirectory.Throwable.SnowballManager = serverRoot.Systems.Throwable.SnowballManager

ModuleDirectory.Overhead = serverRoot.Systems.OtherGameplay.OverheadGui

ModuleDirectory.Coins = {}
ModuleDirectory.Coins.CoinPickup = serverRoot.Systems.CoinPickup.CoinPickup
ModuleDirectory.Coins.CoinPickupManager = serverRoot.Systems.CoinPickup.CoinPickupManager

ModuleDirectory.Bomb = {}
ModuleDirectory.Bomb.Bomb = serverRoot.Systems.Bomb.Bomb
ModuleDirectory.Bomb.BombManager = serverRoot.Systems.Bomb.BombManager

--//====================================================
--// Map System
--//====================================================

ModuleDirectory.Map = {}
-- Models
ModuleDirectory.Map.Block = serverRoot.Systems.Map.Model.Block
ModuleDirectory.Map.Layer = serverRoot.Systems.Map.Model.Layer
ModuleDirectory.Map.Map = serverRoot.Systems.Map.Model.Map
ModuleDirectory.Map.Saves = serverRoot.Systems.Map.MapSaves.List
ModuleDirectory.Map.Obstacle = serverRoot.Systems.Map.Model.Obstacle
ModuleDirectory.Map.MapUtilities = serverRoot.Systems.Map.MapUtilities

-- Factories
ModuleDirectory.Map.BlockFactory = serverRoot.Systems.Map.BlockFactory
ModuleDirectory.Map.PlaneFactory = serverRoot.Systems.Map.PlaneFactory
ModuleDirectory.Map.LayerFactory = serverRoot.Systems.Map.LayerFactory
ModuleDirectory.Map.MapDataFactory = serverRoot.Systems.Map.MapDataFactory
ModuleDirectory.Map.ObstacleFactory = serverRoot.Systems.Map.ObstacleFactory

-- Builders / Generators
ModuleDirectory.Map.MapBuilder = serverRoot.Systems.Map.MapBuilder
ModuleDirectory.Map.MapGenerator = serverRoot.Systems.Map.MapGenerator

ModuleDirectory.Map.Materials = serverRoot.Systems.Map.MapSaves.Materials

ModuleDirectory.Map.LoadedBlocks = serverRoot.Systems.Map.Loaded.Block
ModuleDirectory.Map.LoadedLayers = serverRoot.Systems.Map.Loaded.Layer

--//====================================================
--// Gameplay Managers
--//====================================================

ModuleDirectory.Ammo = {}
ModuleDirectory.Ammo.SnowballAmmoPickup = serverRoot.Systems.Ammo.SnowballAmmoPickup
ModuleDirectory.Ammo.AmmoPickupManager =  serverRoot.Systems.Ammo.AmmoPickupManager
ModuleDirectory.Ammo.AmmoManager =  serverRoot.Systems.Ammo.AmmoManager

ModuleDirectory.Gameplay = {}

ModuleDirectory.Gameplay.BlockDestructionTracker = serverRoot.Systems.OtherGameplay.BlockDestructionTracker
ModuleDirectory.Gameplay.ServerHitBoxManager = serverRoot.Systems.OtherGameplay.ServerHitBoxManager
ModuleDirectory.Gameplay.KickManager = serverRoot.Services.KickManager

ModuleDirectory.Gameplay.KnockBackManager = serverRoot.Systems.OtherGameplay.KnockbackManager
ModuleDirectory.Gameplay.BlockDestruction = serverRoot.Systems.OtherGameplay.BlockDestruction
ModuleDirectory.Gameplay.LavaManager = serverRoot.Systems.OtherGameplay.LavaManager

ModuleDirectory.Gameplay.SpawnProtectionManager = serverRoot.Systems.OtherGameplay.SpawnProtectionManager
ModuleDirectory.Gameplay.RespawnManager = serverRoot.Systems.OtherGameplay.RespawnManager

ModuleDirectory.ServerSpectateController = serverRoot.Systems.Spectate.ServerSpectateController

ModuleDirectory.Tool = {}
ModuleDirectory.Tool.ToolManager = serverRoot.Systems.Tools.ToolManager
ModuleDirectory.Tool.BackShovel = serverRoot.Systems.Tools.BackShovel
ModuleDirectory.Tool.ShovelCustomization = serverRoot.Systems.Tools.ShovelCustomization


--//====================================================
--// Tutorial
--//====================================================

ModuleDirectory.Tutorial = {}
ModuleDirectory.Tutorial.TutorialManager = serverRoot.Systems.Tutorial.TutorialManager
ModuleDirectory.Tutorial.tutorialMapGenerator = serverRoot.Systems.Tutorial.TutorialMapGenerator
ModuleDirectory.Tutorial.Dummy = serverRoot.Systems.Tutorial.Npc

--//====================================================
--// Player Systems
--//====================================================
ModuleDirectory.Player = {}
ModuleDirectory.Player.PlayerData = serverRoot.Player.PlayerData
ModuleDirectory.Player.Leaderstats = serverRoot.Player.Leaderstats
ModuleDirectory.Player.PlayerManager = serverRoot.Player.PlayerManager
ModuleDirectory.Player.PlayerPositionTracker = serverRoot.Player.PlayerPositionTracker
ModuleDirectory.Player.SessionVariables = serverRoot.Player.SessionVariables
ModuleDirectory.Player.ProfileManager = serverRoot.Player.ProfileManager
ModuleDirectory.Player.ConstraintManager = serverRoot.Player.ConstraintManager
ModuleDirectory.Player.PlayTimeTracker = serverRoot.Player.PlayTimeTracker

--//====================================================
--// Utilities
--//====================================================
ModuleDirectory.PartPool = sharedRoot.Utilities.PartPool
ModuleDirectory.VectorUtil = sharedRoot.Utilities.VectorUtil
ModuleDirectory.Timer = sharedRoot.Utilities.Timer
ModuleDirectory.ThrowableDefinitions = sharedRoot.Data.ThrowableDefinitions
ModuleDirectory.LogHandler = sharedRoot.Utilities.LogHandler
ModuleDirectory.ListUtil = sharedRoot.Utilities.ListUtil

--//====================================================
--// Utilities
--//====================================================

ModuleDirectory.Rewards = {}
ModuleDirectory.Rewards.RewardsMain = serverRoot.Systems.Rewards.RewardsMain
ModuleDirectory.Rewards.RewardData = sharedRoot.Data.DailyRewards

-- Loaded Assets


ModuleDirectory.Monetization = {}
ModuleDirectory.Monetization.ProductManager = serverRoot.Services.Monetization.ProductManager
ModuleDirectory.Monetization.ProductBindings = serverRoot.Services.Monetization.ProductBindings
ModuleDirectory.Monetization.CoinManager = serverRoot.Services.Monetization.CoinManager
ModuleDirectory.Monetization.ShovelShopManager = serverRoot.Services.Monetization.ShovelShopManager
ModuleDirectory.Monetization.GamepassManager = serverRoot.Services.Monetization.GamepassManager
ModuleDirectory.Monetization.AbilityShopManager = serverRoot.Services.Monetization.AbilityShopManager

ModuleDirectory.Monetization.GamepassData = sharedRoot.Data.ShopData.Gamepasses 

--//====================================================
--// Analytics
--//====================================================
ModuleDirectory.Analytics = {}
ModuleDirectory.Analytics.Onboarding = serverRoot.Services.Analytics.Onboarding
ModuleDirectory.Analytics.Main =serverRoot.Services.Analytics.AnalyticsMain
ModuleDirectory.Analytics.LeaderboardUpdater = serverRoot.Services.Analytics.LeaderboardUpdater
ModuleDirectory.Analytics.LeaderboardGetter = serverRoot.Services.Analytics.LeaderboardGetter
ModuleDirectory.Analytics.EventAnalytics = serverRoot.Services.Analytics.EventAnalytics
ModuleDirectory.Analytics.EconomyAnalytics = serverRoot.Services.Analytics.EconomyAnalytics

ModuleDirectory.Challenge = {}
ModuleDirectory.Challenge.LobbyChallengeMain = serverRoot.Systems.LobbyChallenges.LobbyChallengeMain
ModuleDirectory.Challenge.ChallengeStart = serverRoot.Systems.LobbyChallenges.ChallengeStart        
ModuleDirectory.Challenge.ChallengeEnd = serverRoot.Systems.LobbyChallenges.ChallengeEnd
ModuleDirectory.Challenge.ChallengeLoop = serverRoot.Systems.LobbyChallenges.ChallengeLoop
ModuleDirectory.Challenge.ChallengeSnowball = serverRoot.Systems.LobbyChallenges.Models.ChallengeSnowball

ModuleDirectory.Badges = {}
ModuleDirectory.Badges.PlayerBadgeHandler = serverRoot.Services.Badges.PlayerBadgeHander
ModuleDirectory.Badges.WinBadgeHandler = serverRoot.Services.Badges.WinBadgeHandler

ModuleDirectory.LogHandler = sharedRoot.Utilities.LogHandler

ModuleDirectory.LevelSystem = {}
ModuleDirectory.LevelSystem.LevelUtilities = sharedRoot.Utilities.LevelUtilities
ModuleDirectory.LevelSystem.LevelController = serverRoot.Player.LevelSystem.LevelController

ModuleDirectory.Chat = {}
ModuleDirectory.Chat.ServerCommands = serverRoot.Services.Chat.ServerCommands
ModuleDirectory.Chat.ServerVoice = serverRoot.Services.Chat.ServerVoice

ModuleDirectory.ProductList = sharedRoot.ProductsList

ModuleDirectory.KnockbackUtilities = sharedRoot.Utilities.KnockbackUtilities

ModuleDirectory.ShovelDefinitions = sharedRoot.Data.ShovelDefinitions

ModuleDirectory.Set = sharedRoot.Utilities.Set

ModuleDirectory.GroupRanks = serverRoot.Systems.OtherGameplay.GroupRanks

ModuleDirectory.LayerUtilities = sharedRoot.Utilities.LayerUtilities

-- Remote Handlers

return ModuleDirectory