-- Client Module Directory
local Root = script.Parent
local SharedRoot = game:GetService("ReplicatedStorage")
local ClientModuleDirectory = {}

--//====================================================
--// Core
--//====================================================
ClientModuleDirectory.ClientEventHandler = Root.Core.ClientEventHandler
ClientModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler
ClientModuleDirectory.Config = Root.ClientConfigurations
ClientModuleDirectory.StateChangeManager = Root.Core.StateChangeManager
ClientModuleDirectory.ClientStateTracker = Root.Core.ClientStateTracker

ClientModuleDirectory.MiscBindings = Root.MiscBindings

--//====================================================
--// GUI
--//====================================================

ClientModuleDirectory.Gui = {}
ClientModuleDirectory.Gui.Screens = Root.Gui.Screens
--ClientModuleDirectory.Gui.InivteGUI = Root.Gui.Intermission.InviteGui
ClientModuleDirectory.Gui.AlertSystem = Root.Gui.AlertSystem.AlertSystem
ClientModuleDirectory.Gui.AlertSystemBindings = Root.Gui.AlertSystem.AlertSystemBindings
ClientModuleDirectory.Gui.RoundStatus = Root.Gui.Active.Status
ClientModuleDirectory.Gui.Ammo = Root.Gui.Active.Ammo
ClientModuleDirectory.Gui.IntermissionStatus = Root.Gui.Intermission.Status
ClientModuleDirectory.Gui.ButtonUtilities = Root.Gui.Utilities.ButtonUtilities
ClientModuleDirectory.Gui.ToolBarUtilities = Root.Gui.Utilities.ToolBarUtilities
ClientModuleDirectory.Gui.ScaleUtilities = Root.Gui.Utilities.ScaleUtilities
ClientModuleDirectory.Gui.SpectateButton = Root.Gui.Spectate.SpectateButton
ClientModuleDirectory.Gui.MobileSettingsButton = Root.Gui.Settings.MobileSettingsButton
ClientModuleDirectory.Gui.MobileSettingsWidget = Root.Gui.Settings.MobileSettingsWidget
ClientModuleDirectory.Gui.ExperienceBar = Root.Gui.Intermission.ExperienceBar
ClientModuleDirectory.Gui.TutorialStatus = Root.Gui.Tutorial.TutorialStatus
ClientModuleDirectory.Gui.TutorialLeave = Root.Gui.Tutorial.TutorialLeave
ClientModuleDirectory.Gui.FrameSystem = Root.Gui.Intermission.FrameSystem
ClientModuleDirectory.Gui.MobileShopButton = Root.Gui.Intermission.MobileShopButton
ClientModuleDirectory.Gui.MobileRewardButton = Root.Gui.Intermission.MobileRewardButton
ClientModuleDirectory.Gui.AbilityBar = Root.Gui.Active.AbilityBar
ClientModuleDirectory.Gui.Coin = Root.Gui.Active.Coin
ClientModuleDirectory.Gui.ReviveMessage = Root.Gui.Active.ReviveMessage
ClientModuleDirectory.Gui.TutorialTip = Root.Gui.Tutorial.TutorialTip
ClientModuleDirectory.Gui.ConfirmLeave = Root.Gui.Tutorial.ConfirmLeave -- tutorial leave gui


ClientModuleDirectory.BackShovel = Root.Visuals.BackShovel

--ClientModuleDirectory.Gui.NameTag = Root.Gui.NameTag

ClientModuleDirectory.Gui.EliminationScreen = Root.Gui.Intermission.EliminationScreen
ClientModuleDirectory.Gui.RespawnScreen = Root.Gui.Intermission.RespawnScreen

ClientModuleDirectory.Gui.TouchButtons = Root.Gui.Input.TouchButtons

ClientModuleDirectory.Gui.CrossHair = Root.Gui.Input.CrossHair
ClientModuleDirectory.Gui.PCSettingsWidget = Root.Gui.Settings.PCSettingsWidget

ClientModuleDirectory.Gui.ParticleText = Root.Gui.Particles.ParticleText
ClientModuleDirectory.Gui.HowToPlay = Root.Gui.Intermission.HowToPlay
ClientModuleDirectory.Gui.MouseIcon = Root.Gui.MouseIcon
--ClientModuleDirectory.Gui.Coins = Root.Gui.Intermission.Coins
ClientModuleDirectory.Gui.Transition = Root.Gui.Transition
ClientModuleDirectory.Gui.CurrencyGui = Root.Gui.Intermission.CurrencyGui
ClientModuleDirectory.Gui.LeaderboardHandler = Root.Gui.SurfaceGUIs.LeaderboardHandler
ClientModuleDirectory.Gui.TutorialAmmo = Root.Gui.Tutorial.TutorialAmmo
ClientModuleDirectory.Gui.OverheadGui = Root.ClientUtils.ClientOverheadGui

ClientModuleDirectory.Gui.SpectateControls = Root.Gui.Spectate.Controls

ClientModuleDirectory.Gui.SummaryWidget = Root.Gui.Intermission.SummaryWidget

ClientModuleDirectory.Gui.Shop = {} 
ClientModuleDirectory.Gui.Shop.Main = Root.Gui.Intermission.Shop.Main
ClientModuleDirectory.Gui.Shop.ExtraLives = Root.Gui.Intermission.Shop.ExtraLives
ClientModuleDirectory.Gui.Shop.Abilities = Root.Gui.Intermission.Shop.Abilities
ClientModuleDirectory.Gui.Shop.Shovels = Root.Gui.Intermission.Shop.Shovels
ClientModuleDirectory.Gui.Shop.Coins = Root.Gui.Intermission.Shop.Coins 
ClientModuleDirectory.Gui.Shop.Gamepass = Root.Gui.Intermission.Shop.Gamepass

ClientModuleDirectory.Gui.AFKWarning = Root.Gui.Active.AFKWarning
ClientModuleDirectory.Gui.VotingGui = Root.Gui.Intermission.VotingGui

ClientModuleDirectory.Gui.DailyRewardsGui = Root.Gui.Intermission.DailyRewards

--ClientModuleDirectory.Gui.InivteGUI = Root.Gui.SurfaceGUIs.InviteGui

--//====================================================
--// Input Handler
--//====================================================
ClientModuleDirectory.Input = {}
ClientModuleDirectory.Input.InputHandler = Root.Input.InputHandler
ClientModuleDirectory.Input.ActionHandler = Root.Input.ActionHandler
ClientModuleDirectory.Input.PlatformDetector = Root.Input.PlatformDetector
ClientModuleDirectory.Input.MobileCamera = Root.Input.MobileCamera
ClientModuleDirectory.Input.MobileCameraMovement = Root.Input.MobileCameraMovement
ClientModuleDirectory.Input.MobileControls = Root.Input.MobileControls
ClientModuleDirectory.Input.AimAssistController = Root.Input.AimAssistController
ClientModuleDirectory.Input.BackwardsEdgeDetector = Root.Input.BackwardsEdgeDetector
ClientModuleDirectory.Input.MovementDampener = Root.Input.MovementDampener
ClientModuleDirectory.Input.ModeDetector = Root.Input.ModeDetector
ClientModuleDirectory.Input.AbilityActionHandler = Root.Input.AbilityActionHander 

ClientModuleDirectory.Abilities = {}
ClientModuleDirectory.Abilities.Main = Root.Gameplay.Abilities.ClientAbilities
ClientModuleDirectory.Abilities.Functions = Root.Gameplay.Abilities.AbilitiesFunctions

--//====================================================
--// Gameplay
--//====================================================
ClientModuleDirectory.ClientSnowballAnimator = Root.Gameplay.ClientSnowballAnimator
ClientModuleDirectory.PlayerHighlighter = Root.Gameplay.PlayerHighlighter
ClientModuleDirectory.ClientDestructionHandler = Root.Gameplay.ClientDestructionHandler
ClientModuleDirectory.ClientThrowableTracker = Root.Gameplay.ClientThrowableTracker
ClientModuleDirectory.ClientToolManager = Root.Gameplay.ClientToolManager
ClientModuleDirectory.PlayerPositionSender = Root.Gameplay.PlayerPositionSender
ClientModuleDirectory.HitBoxManager = Root.Gameplay.HitBoxManager
ClientModuleDirectory.ClientAmmoTracker = Root.Gameplay.ClientAmmoTracker
ClientModuleDirectory.ClientKnockback = Root.Gameplay.ClientKnockback
ClientModuleDirectory.ClientBlockSelector = Root.Gameplay.ClientBlockSelector
ClientModuleDirectory.PostDeathSystem = Root.Gameplay.PostDeathSystem
ClientModuleDirectory.CooldownPredicter = Root.Gameplay.CooldownPredicter


ClientModuleDirectory.AnimationManager = Root.Visuals.AnimationManager

--//====================================================
--// Profile
--//====================================================

ClientModuleDirectory.Variables = {}
ClientModuleDirectory.Variables.ProfileVariables = Root.Variables.ProfileVariables
ClientModuleDirectory.Variables.SessionVariables = Root.Variables.SessionVariables
ClientModuleDirectory.Variables.ServerConstants = Root.Variables.ServerConstants

--//====================================================
--// Chat
--//====================================================

ClientModuleDirectory.Chat = {}
ClientModuleDirectory.Chat.SystemMessage = Root.Chat.SystemMessage
ClientModuleDirectory.Chat.ClientCommands = Root.Chat.ClientCommands

--//====================================================
--// Client Utilities
--//====================================================

ClientModuleDirectory.SnowballPool = Root.ClientUtils.SnowballPool

ClientModuleDirectory.VibrationService = Root.Visuals.VibrationService


--//====================================================
--// Visuals
--//====================================================

ClientModuleDirectory.ParticlePlayer = Root.Visuals.ParticlePlayer
ClientModuleDirectory.EmitterDefs = Root.Visuals.EmitterDefs
ClientModuleDirectory.ClientLavaManager = Root.Visuals.ClientLavaManager
ClientModuleDirectory.CheerEffect = Root.Visuals.CheerEffect
ClientModuleDirectory.EliminationEffect = Root.Visuals.EliminationEffect
ClientModuleDirectory.CrownOverhead = Root.Visuals.CrownOverhead
ClientModuleDirectory.WinnerEffect = Root.Visuals.WinnerEffect
ClientModuleDirectory.ClientSnowballVisuals = Root.Visuals.ClientSnowballVisuals
ClientModuleDirectory.HighlightBlocks = Root.Visuals.HighlightBlocks

ClientModuleDirectory.Spectate= {}
ClientModuleDirectory.Spectate.Ghost = Root.Spectate.Ghost
ClientModuleDirectory.Spectate.FreecamMode = Root.Spectate.FreecamMode
ClientModuleDirectory.Spectate.Controller = Root.Spectate.SpectateController
ClientModuleDirectory.Spectate.CelebrationTracker = Root.Spectate.CelebrationTracker


ClientModuleDirectory.Weather = {}
ClientModuleDirectory.Weather.WeatherData = Root.Weather.WeatherData
ClientModuleDirectory.Weather.WeatherManager = Root.Weather.WeatherManager

--//====================================================
--// Sound
--//====================================================

ClientModuleDirectory.Sound = {}
ClientModuleDirectory.Sound.SoundPlayer = Root.Sound.SoundPlayer
ClientModuleDirectory.Sound.MusicPlayer = Root.Sound.MusicPlayer

--//====================================================
--// Debug Tools
--//====================================================

ClientModuleDirectory.test = Root.DebugTools.testModule
ClientModuleDirectory.TapDebugView = Root.DebugTools.TapDebugView

ClientModuleDirectory.TutorialAnnouncer = Root.Tutorial.TutorialAnnouncer


--//====================================================
--// Shared Utilities
--//====================================================

ClientModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ClientModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil
ClientModuleDirectory.TextUtilities = game:GetService("ReplicatedStorage").Utilities.TextUtilities


--//====================================================
--// Resources Handler
--//====================================================

ClientModuleDirectory.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData
ClientModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions


ClientModuleDirectory.Libs = {}
ClientModuleDirectory.Libs.UIParticleEmitter = Root.Libs.UIParticleEmitter

ClientModuleDirectory.LogHandler = game:GetService("ReplicatedStorage").Utilities.LogHandler

ClientModuleDirectory.LevelUtilities = game:GetService("ReplicatedStorage").Utilities.LevelUtilities

ClientModuleDirectory.ProductList = game:GetService("ReplicatedStorage").ProductsList

ClientModuleDirectory.KnockbackUtilities = game:GetService("ReplicatedStorage").Utilities.KnockbackUtilities

ClientModuleDirectory.ClientTutorial = Root.Tutorial.ClientTutorial

ClientModuleDirectory.ShopItem = game:GetService("ReplicatedStorage").Data.ShopData.ShopItem
ClientModuleDirectory.ExtraLives = game:GetService("ReplicatedStorage").Data.ShopData.ExtraLives
ClientModuleDirectory.GamePassData = game:GetService("ReplicatedStorage").Data.ShopData.Gamepasses
ClientModuleDirectory.Coins = game:GetService("ReplicatedStorage").Data.ShopData.Coins

ClientModuleDirectory.ClientVoice = Root.Chat.ClientVoice

ClientModuleDirectory.Gui.InviteGui = Root.Gui.Intermission.InviteGui

ClientModuleDirectory.AbilitiesData = SharedRoot.Data.AbilitiesDefinitions
ClientModuleDirectory.ShovelsData = SharedRoot.Data.ShovelDefinitions

ClientModuleDirectory.RewardsData = SharedRoot.Data.DailyRewards

ClientModuleDirectory.TutorialData = Root.Tutorial.TutorialData
ClientModuleDirectory.TutorialFunctions = Root.Tutorial.TutorialFunctions

ClientModuleDirectory.ClolorNumberMapping = SharedRoot.Data.ColorNumberMapping

ClientModuleDirectory.ClientCollectableManager = Root.Collectable.ClientCollectableManager

return ClientModuleDirectory

