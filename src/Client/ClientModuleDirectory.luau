-- Client Module Directory
local Root = script.Parent
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
ClientModuleDirectory.Gui.InivteGUI = Root.Gui.Intermission.InviteGui
ClientModuleDirectory.Gui.AlertSystem = Root.Gui.AlertSystem.AlertSystem
ClientModuleDirectory.Gui.AlertSystemBindings = Root.Gui.AlertSystem.AlertSystemBindings
ClientModuleDirectory.Gui.RoundStatus = Root.Gui.Active.Status
ClientModuleDirectory.Gui.Ammo = Root.Gui.Active.Ammo
ClientModuleDirectory.Gui.IntermissionStatus = Root.Gui.Intermission.Status

ClientModuleDirectory.Gui.ParticleText = Root.Gui.Particles.ParticleText
ClientModuleDirectory.Gui.HowToPlay = Root.Gui.Intermission.HowToPlay
ClientModuleDirectory.Gui.MouseIcon = Root.Gui.MouseIcon
ClientModuleDirectory.Gui.Transition = Root.Gui.Transition

--//====================================================
--// Input Handler
--//====================================================
ClientModuleDirectory.Input = {}
ClientModuleDirectory.Input.InputHandler = Root.Input.InputHandler
ClientModuleDirectory.Input.ActionHandler = Root.Input.ActionHandler
ClientModuleDirectory.Input.PlatformDetector = Root.Input.PlatformDetector

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
ClientModuleDirectory.ClientLavaManager = Root.Gameplay.ClientLavaManager



--//====================================================
--// Chat
--//====================================================

ClientModuleDirectory.Chat = {}
ClientModuleDirectory.Chat.SystemMessage = Root.Chat.SystemMessage
ClientModuleDirectory.Chat.ClientCommands = Root.Chat.SystemMessage

--//====================================================
--// Client Utilities
--//====================================================

ClientModuleDirectory.SnowballPool = Root.ClientUtils.SnowballPool
ClientModuleDirectory.ParticlePlayer = Root.Visuals.ParticlePlayer
ClientModuleDirectory.EmitterDefs = Root.ClientUtils.EmitterDefs

--//====================================================
--// Sound
--//====================================================

ClientModuleDirectory.Sound = {}
ClientModuleDirectory.Sound.SoundPlayer = Root.Sound.SoundPlayer

--//====================================================
--// Debug Tools
--//====================================================

ClientModuleDirectory.test = Root.DebugTools.testModule
ClientModuleDirectory.TapDebugView = Root.DebugTools.TapDebugView

--//====================================================
--// Shared Utilities
--//====================================================

ClientModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ClientModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil

--//====================================================
--// Resources Handler
--//====================================================

ClientModuleDirectory.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData
ClientModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions

return ClientModuleDirectory
