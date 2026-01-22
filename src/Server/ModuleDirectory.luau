--//====================================================
--// ModuleDirectory
--//====================================================

local serverRoot = game:GetService("ServerScriptService")
local sharedRoot = game:GetService("ReplicatedStorage")
local ModuleDirectory = {}

--//====================================================
--// Core Scripts
--//====================================================
ModuleDirectory.ServerEventHandler = serverRoot.Core.ServerEventHandler
ModuleDirectory.ValueBinder = serverRoot.Core.ValueBinder
ModuleDirectory.RemoteEventHandler = sharedRoot.RemoteEventHandler
ModuleDirectory.Setup = serverRoot.Core.Setup
ModuleDirectory.ServerStatus = serverRoot.ServerStatus
ModuleDirectory.ServerConstants = serverRoot.Core.ServerConstants

ModuleDirectory.DebugTools = {}
ModuleDirectory.DebugTools.TileScoreDebug = serverRoot.DebugTools.TileScoreDebug

--//====================================================
--// Systems Root
--//====================================================
ModuleDirectory.Systems = {}

--//====================================================
--// Round System
--//====================================================
ModuleDirectory.Systems.Round = {}
ModuleDirectory.Systems.Round.PlayerPool = serverRoot.Systems.Round.PlayerPool
ModuleDirectory.Systems.Round.PlayersInGame = serverRoot.Systems.Round.PlayersInGame
ModuleDirectory.Systems.Round.PlayerDeathDetector = serverRoot.Systems.Round.PlayerDeathDetector
ModuleDirectory.Systems.Round.TeleportManager = serverRoot.Systems.Round.TeleportManager
ModuleDirectory.Systems.Round.RoundManager = serverRoot.Systems.Round.RoundManager
ModuleDirectory.Systems.Round.RoundSystem = serverRoot.Systems.Round.RoundSystem
ModuleDirectory.Systems.Round.SuddenDeath = serverRoot.Systems.Round.SuddenDeath
ModuleDirectory.Systems.Round.MapSelection = serverRoot.Systems.Round.MapSelection
ModuleDirectory.Systems.Round.ClearLobby = serverRoot.Systems.Round.ClearLobby
ModuleDirectory.Systems.Round.PodiumManager = serverRoot.Systems.Round.PodiumManager
ModuleDirectory.Systems.Round.AFKTracker = serverRoot.Systems.Round.AFKTracker
ModuleDirectory.Systems.Round.AgentsInGame = serverRoot.Systems.Round.AgentsInGame

--//====================================================
--// Abilities System
--//====================================================
ModuleDirectory.Systems.Abilities = {}
ModuleDirectory.Systems.Abilities.Main = serverRoot.Systems.Abilities.AblilitiesMain
ModuleDirectory.Systems.Abilities.Functions = serverRoot.Systems.Abilities.AbilitiesFunctions
ModuleDirectory.Systems.Abilities.Definitions = sharedRoot.Data.AbilitiesDefinitions
ModuleDirectory.Systems.Abilities.EndFunctions = serverRoot.Systems.Abilities.EndFunctions
ModuleDirectory.Systems.Abilities.TeleportAbility = serverRoot.Systems.Abilities.TeleportAbility

--//====================================================
--// Agent System
--//====================================================
ModuleDirectory.Systems.Agent = {}
ModuleDirectory.Systems.Agent.AgentManager = serverRoot.Systems.Agent.AgentManager
ModuleDirectory.Systems.Agent.Agent = serverRoot.Systems.Agent.Agent
ModuleDirectory.Systems.Agent.AgentPersonalities = serverRoot.Systems.Agent.AgentPersonalities

ModuleDirectory.Systems.Agent.AgentMovement = serverRoot.Systems.Agent.Components.AgentMovement
ModuleDirectory.Systems.Agent.AgentCombat = serverRoot.Systems.Agent.Components.AgentCombat
ModuleDirectory.Systems.Agent.AgentAnimations = serverRoot.Systems.Agent.Components.AgentAnimations


ModuleDirectory.Systems.Agent.CharacterGeneration = serverRoot.Systems.Agent.Helpers.CharacterGeneration
ModuleDirectory.Systems.Agent.TileScoring = serverRoot.Systems.Agent.Helpers.TileScoring
ModuleDirectory.Systems.Agent.Pathfinding = serverRoot.Systems.Agent.Helpers.Pathfinding

--//====================================================
--// Stats Tracker System
--//====================================================
ModuleDirectory.Systems.Stats = {}
ModuleDirectory.Systems.Stats.WinnerDetection = serverRoot.Systems.StatsTrackers.WinnerDetection
ModuleDirectory.Systems.Stats.TouchedBlockTracker = serverRoot.Systems.StatsTrackers.TouchedBlockTracker
ModuleDirectory.Systems.Stats.RoundSummary = serverRoot.Systems.StatsTrackers.RoundSummary
ModuleDirectory.Systems.Stats.KnockbackTracker = serverRoot.Systems.StatsTrackers.KnockbackTracker
ModuleDirectory.Systems.Stats.EliminationTracker = serverRoot.Systems.StatsTrackers.EliminationTracker

--//====================================================
--// Throwable System
--//====================================================
ModuleDirectory.Systems.Throwable = {}
ModuleDirectory.Systems.Throwable.Throwable = serverRoot.Systems.Throwable.Throwable
ModuleDirectory.Systems.Throwable.ThrowableManager = serverRoot.Systems.Throwable.ThrowableManager
ModuleDirectory.Systems.Throwable.ThrowableData = sharedRoot.Types.ThrowableData
ModuleDirectory.Systems.Throwable.PlayerRaycastParamsHandler = serverRoot.Systems.Throwable.PlayerRaycastParmsHandler
ModuleDirectory.Systems.Throwable.SnowballManager = serverRoot.Systems.Throwable.SnowballManager

--//====================================================
--// Coins System
--//====================================================
ModuleDirectory.Systems.Coins = {}
ModuleDirectory.Systems.Coins.CoinPickup = serverRoot.Systems.CoinPickup.CoinPickup
ModuleDirectory.Systems.Coins.CoinPickupManager = serverRoot.Systems.CoinPickup.CoinPickupManager

--//====================================================
--// Bomb System
--//====================================================
ModuleDirectory.Systems.Bomb = {}
ModuleDirectory.Systems.Bomb.Bomb = serverRoot.Systems.Bomb.Bomb
ModuleDirectory.Systems.Bomb.BombManager = serverRoot.Systems.Bomb.BombManager

--//====================================================
--// Map System
--//====================================================
ModuleDirectory.Systems.Map = {}

-- Models
ModuleDirectory.Systems.Map.Block = serverRoot.Systems.Map.Model.Block
ModuleDirectory.Systems.Map.Layer = serverRoot.Systems.Map.Model.Layer
ModuleDirectory.Systems.Map.Map = serverRoot.Systems.Map.Model.Map
ModuleDirectory.Systems.Map.MapSaves = serverRoot.Systems.Map.MapSaves.List
ModuleDirectory.Systems.Map.Materials = serverRoot.Systems.Map.MapSaves.Materials
ModuleDirectory.Systems.Map.PlaneGenerator = serverRoot.Systems.Map.PlaneGenerator
ModuleDirectory.Systems.Map.MapGenerator = serverRoot.Systems.Map.MapGenerator
ModuleDirectory.Systems.Map.BlockDestruction = serverRoot.Systems.Map.BlockDestruction

-- Loaded

--//====================================================
--// Ammo System
--//====================================================
ModuleDirectory.Systems.Ammo = {}
ModuleDirectory.Systems.Ammo.SnowballAmmoPickup = serverRoot.Systems.Ammo.SnowballAmmoPickup
ModuleDirectory.Systems.Ammo.AmmoPickupManager = serverRoot.Systems.Ammo.AmmoPickupManager
ModuleDirectory.Systems.Ammo.AmmoManager = serverRoot.Systems.Ammo.AmmoManager

--//====================================================
--// Gameplay (OtherGameplay + Services used in gameplay)
--//====================================================
ModuleDirectory.Systems.Gameplay = {}
ModuleDirectory.Systems.Gameplay.ServerHitBoxManager = serverRoot.Systems.OtherGameplay.ServerHitBoxManager
ModuleDirectory.Systems.Gameplay.KnockBackManager = serverRoot.Systems.OtherGameplay.KnockbackManager
ModuleDirectory.Systems.Gameplay.LavaManager = serverRoot.Systems.OtherGameplay.LavaManager
ModuleDirectory.Systems.Gameplay.SpawnProtectionManager = serverRoot.Systems.OtherGameplay.SpawnProtectionManager
ModuleDirectory.Systems.Gameplay.RespawnManager = serverRoot.Systems.OtherGameplay.RespawnManager
ModuleDirectory.Systems.Gameplay.KickManager = serverRoot.Services.KickManager

-- Standalone gameplay items (kept at top-level like original)
ModuleDirectory.Overhead = serverRoot.Systems.OtherGameplay.OverheadGui
ModuleDirectory.GroupRanks = serverRoot.Systems.OtherGameplay.GroupRanks

--//====================================================
--// Spectate System
--//====================================================
ModuleDirectory.Systems.Spectate = {}
ModuleDirectory.Systems.Spectate.ServerSpectateController = serverRoot.Systems.Spectate.ServerSpectateController

--//====================================================
--// Tools System
--//====================================================
ModuleDirectory.Systems.Tool = {}
ModuleDirectory.Systems.Tool.ToolManager = serverRoot.Systems.Tools.ToolManager
ModuleDirectory.Systems.Tool.BackShovel = serverRoot.Systems.Tools.BackShovel
ModuleDirectory.Systems.Tool.ShovelCustomization = serverRoot.Systems.Tools.ShovelCustomization

--//====================================================
--// Tutorial System
--//====================================================

--//====================================================
--// Rewards System
--//====================================================
ModuleDirectory.Systems.Rewards = {}
ModuleDirectory.Systems.Rewards.RewardsMain = serverRoot.Systems.Rewards.RewardsMain
ModuleDirectory.Systems.Rewards.RewardData = sharedRoot.Data.DailyRewards

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

-- Level System (kept as top-level like original)
ModuleDirectory.LevelSystem = {}
ModuleDirectory.LevelSystem.LevelUtilities = sharedRoot.Utilities.LevelUtilities
ModuleDirectory.LevelSystem.LevelController = serverRoot.Player.LevelSystem.LevelController

--//====================================================
--// Services
--//====================================================
ModuleDirectory.Services = {}

-- Monetization
ModuleDirectory.Services.Monetization = {}
ModuleDirectory.Services.Monetization.ProductManager = serverRoot.Services.Monetization.ProductManager
ModuleDirectory.Services.Monetization.ProductBindings = serverRoot.Services.Monetization.ProductBindings
ModuleDirectory.Services.Monetization.CoinManager = serverRoot.Services.Monetization.CoinManager
ModuleDirectory.Services.Monetization.ShovelShopManager = serverRoot.Services.Monetization.ShovelShopManager
ModuleDirectory.Services.Monetization.GamepassManager = serverRoot.Services.Monetization.GamepassManager
ModuleDirectory.Services.Monetization.AbilityShopManager = serverRoot.Services.Monetization.AbilityShopManager
ModuleDirectory.Services.Monetization.GamepassData = sharedRoot.Data.ShopData.Gamepasses

-- Analytics
ModuleDirectory.Services.Analytics = {}
ModuleDirectory.Services.Analytics.Onboarding = serverRoot.Services.Analytics.Onboarding
ModuleDirectory.Services.Analytics.Main = serverRoot.Services.Analytics.AnalyticsMain
ModuleDirectory.Services.Analytics.LeaderboardUpdater = serverRoot.Services.Analytics.LeaderboardUpdater
ModuleDirectory.Services.Analytics.LeaderboardGetter = serverRoot.Services.Analytics.LeaderboardGetter
ModuleDirectory.Services.Analytics.EventAnalytics = serverRoot.Services.Analytics.EventAnalytics
ModuleDirectory.Services.Analytics.EconomyAnalytics = serverRoot.Services.Analytics.EconomyAnalytics

-- Badges
ModuleDirectory.Services.Badges = {}
ModuleDirectory.Services.Badges.PlayerBadgeHandler = serverRoot.Services.Badges.PlayerBadgeHander
ModuleDirectory.Services.Badges.WinBadgeHandler = serverRoot.Services.Badges.WinBadgeHandler

-- Chat
ModuleDirectory.Chat = {}
ModuleDirectory.Chat.ServerCommands = serverRoot.Services.Chat.ServerCommands
ModuleDirectory.Chat.ServerVoice = serverRoot.Services.Chat.ServerVoice

--//====================================================
--// Lobby Challenges
--//====================================================
ModuleDirectory.Challenge = {}
ModuleDirectory.Challenge.LobbyChallengeMain = serverRoot.Systems.LobbyChallenges.LobbyChallengeMain
ModuleDirectory.Challenge.ChallengeStart = serverRoot.Systems.LobbyChallenges.ChallengeStart
ModuleDirectory.Challenge.ChallengeEnd = serverRoot.Systems.LobbyChallenges.ChallengeEnd
ModuleDirectory.Challenge.ChallengeLoop = serverRoot.Systems.LobbyChallenges.ChallengeLoop
ModuleDirectory.Challenge.ChallengeSnowball = serverRoot.Systems.LobbyChallenges.Models.ChallengeSnowball

--//====================================================
--// Shared Utilities / Data (top-level like original)
--//====================================================
ModuleDirectory.PartPool = sharedRoot.Utilities.PartPool
ModuleDirectory.VectorUtil = sharedRoot.Utilities.VectorUtil
ModuleDirectory.Timer = sharedRoot.Utilities.Timer
ModuleDirectory.Systems.ThrowableDefinitions = sharedRoot.Data.ThrowableDefinitions
ModuleDirectory.ListUtil = sharedRoot.Utilities.ListUtil
ModuleDirectory.LogHandler = sharedRoot.Utilities.LogHandler
ModuleDirectory.KnockbackUtilities = sharedRoot.Utilities.KnockbackUtilities
ModuleDirectory.Set = sharedRoot.Utilities.Set


-- Shared definitions / lists
ModuleDirectory.ProductList = sharedRoot.ProductsList
ModuleDirectory.ShovelDefinitions = sharedRoot.Data.ShovelDefinitions

--//====================================================
--// Return
--//====================================================
return ModuleDirectory
