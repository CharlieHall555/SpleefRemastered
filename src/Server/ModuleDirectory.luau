local GuiService = game:GetService("GuiService")
local serverRoot = game:GetService("ServerScriptService")
local shareRoot = game:GetService("ReplicatedStorage")
local ModuleDirectory = {}

-- Core Scripts
ModuleDirectory.ServerEventHandler = serverRoot.Core.ServerEventHandler
ModuleDirectory.ValueBinder = serverRoot.Core.ValueBinder
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler
ModuleDirectory.Setup = serverRoot.Core.Setup
ModuleDirectory.ServerStatus = serverRoot.ServerStatus

--//====================================================
--// Round System
--//====================================================

ModuleDirectory.Round = {}
ModuleDirectory.Round.PlayerPool = serverRoot.Systems.Round.PlayerPool
ModuleDirectory.Round.PlayersInGame =serverRoot.Systems.Round.PlayersInGame
ModuleDirectory.Round.PlayerDeathDetector = serverRoot.Systems.Round.PlayerDeathDetector
ModuleDirectory.Round.TeleportManager = serverRoot.Systems.Round.TeleportManager
ModuleDirectory.Round.RoundManager = serverRoot.Systems.Round.RoundManager
ModuleDirectory.Round.RoundSystem = serverRoot.Systems.Round.RoundSystem
ModuleDirectory.Round.SuddenDeath = serverRoot.Systems.Round.SuddenDeath
ModuleDirectory.Round.MapSelection = serverRoot.Systems.Round.MapSelection
ModuleDirectory.Round.ClearLobby = serverRoot.Systems.Round.ClearLobby
ModuleDirectory.Round.PodiumManager = serverRoot.Systems.Round.PodiumManager
ModuleDirectory.Round.AFKTracker = serverRoot.Systems.Round.AFKTracker

ModuleDirectory.Abilities = {}
ModuleDirectory.Abilities.Main = serverRoot.Systems.Abilities.AblilitiesMain
ModuleDirectory.Abilities.Functions = serverRoot.Systems.Abilities.AbilitiesFunctions
ModuleDirectory.Abilities.Definitions = shareRoot.Data.AbilitiesDefinitions
ModuleDirectory.Abilities.EndFunctions = serverRoot.Systems.Abilities.EndFunctions
ModuleDirectory.Abilities.TeleportAbility = serverRoot.Systems.Abilities.TeleportAbility


--//====================================================
--// StatsTracker System
--//====================================================

ModuleDirectory.Stats = {}
ModuleDirectory.Stats.WinnerDetection = serverRoot.Systems.StatsTrackers.WinnerDetection
ModuleDirectory.Stats.TouchedBlockTracker = serverRoot.Systems.StatsTrackers.TouchedBlockTracker
ModuleDirectory.Stats.RoundSummary =  serverRoot.Systems.StatsTrackers.RoundSummary
ModuleDirectory.Stats.KnockbackTracker = serverRoot.Systems.StatsTrackers.KnockbackTracker
ModuleDirectory.Stats.EliminationTracker = serverRoot.Systems.StatsTrackers.EliminationTracker

--//====================================================
--// Throwable System
--//====================================================

ModuleDirectory.Throwable = {}
ModuleDirectory.Throwable.Throwable = serverRoot.Systems.Throwable.Throwable
ModuleDirectory.Throwable.ThrowableManager = serverRoot.Systems.Throwable.ThrowableManager
ModuleDirectory.Throwable.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData
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
ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil
ModuleDirectory.Timer = game:GetService("ReplicatedStorage").Utilities.Timer
ModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions
ModuleDirectory.LogHandler = game:GetService("ReplicatedStorage").Utilities.LogHandler
ModuleDirectory.ListUtil = game:GetService("ReplicatedStorage").Utilities.ListUtil

--//====================================================
--// Utilities
--//====================================================

ModuleDirectory.Rewards = {}
ModuleDirectory.Rewards.RewardsMain = serverRoot.Systems.Rewards.RewardsMain
ModuleDirectory.Rewards.RewardData = game:GetService("ReplicatedStorage").Data.DailyRewards

-- Loaded Assets


ModuleDirectory.Monetization = {}
ModuleDirectory.Monetization.ProductManager = serverRoot.Services.Monetization.ProductManager
ModuleDirectory.Monetization.ProductBindings = serverRoot.Services.Monetization.ProductBindings
ModuleDirectory.Monetization.CoinManager = serverRoot.Services.Monetization.CoinManager
ModuleDirectory.Monetization.ShovelShopManager = serverRoot.Services.Monetization.ShovelShopManager
ModuleDirectory.Monetization.GamepassManager = serverRoot.Services.Monetization.GamepassManager
ModuleDirectory.Monetization.AbilityShopManager = serverRoot.Services.Monetization.AbilityShopManager

ModuleDirectory.Monetization.GamepassData = game:GetService("ReplicatedStorage").Data.ShopData.Gamepasses 

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

ModuleDirectory.LogHandler = game:GetService("ReplicatedStorage").Utilities.LogHandler

ModuleDirectory.LevelSystem = {}
ModuleDirectory.LevelSystem.LevelUtilities = game:GetService("ReplicatedStorage").Utilities.LevelUtilities
ModuleDirectory.LevelSystem.LevelController = serverRoot.Player.LevelSystem.LevelController

ModuleDirectory.Chat = {}
ModuleDirectory.Chat.ServerCommands = serverRoot.Services.Chat.ServerCommands
ModuleDirectory.Chat.ServerVoice = serverRoot.Services.Chat.ServerVoice

ModuleDirectory.ProductList = game:GetService("ReplicatedStorage").ProductsList

ModuleDirectory.KnockbackUtilities = game:GetService("ReplicatedStorage").Utilities.KnockbackUtilities

ModuleDirectory.ShovelDefinitions = game:GetService("ReplicatedStorage").Data.ShovelDefinitions

ModuleDirectory.Set = game:GetService("ReplicatedStorage").Utilities.Set

ModuleDirectory.GroupRanks = serverRoot.Systems.OtherGameplay.GroupRanks

-- Remote Handlers

return ModuleDirectory