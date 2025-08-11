-- Client Module Directory
local Root = script.Parent
local ClientModuleDirectory = {}

-- Core
ClientModuleDirectory.ClientEventHandler = Root.Core.ClientEventHandler
ClientModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler

-- Configuration
ClientModuleDirectory.Config = Root.ClientConfigurations
ClientModuleDirectory.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData
ClientModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions

ClientModuleDirectory.MiscBindings = Root.MiscBindings

-- GUI

ClientModuleDirectory.GUI = {}
ClientModuleDirectory.GUI.AlertSystem = Root.GUI.AlertSystem
ClientModuleDirectory.AlertSystemBindings = Root.GUI.AlertSystemBindings
ClientModuleDirectory.GUI.Intermission = Root.GUI.Intermission
ClientModuleDirectory.GUI.InGameHUD = Root.GUI.InGameHUD
ClientModuleDirectory.GlobalVariables = Root.GlobalVariables
ClientModuleDirectory.ClientSnowballAnimator = Root.Gameplay.ClientSnowballAnimator

-- Gameplay
ClientModuleDirectory.PlayerPositionSender = Root.Gameplay.PlayerPositionSender
ClientModuleDirectory.ClientThrowableTracker = Root.Gameplay.ClientThrowableTracker
ClientModuleDirectory.ClientDestructionHandler = Root.Gameplay.ClientDestructionHandler
ClientModuleDirectory.HitBoxManager = Root.Gameplay.HitBoxManager
ClientModuleDirectory.PlayerHighlighter = Root.Gameplay.PlayerHighlighter
ClientModuleDirectory.ClientAmmoTracker = Root.Gameplay.ClientAmmoTracker
ClientModuleDirectory.SystemMessage = Root.SystemMessage

-- State Management
ClientModuleDirectory.StateChangeManager = Root.StateChangeManager
ClientModuleDirectory.ClientStateTracker = Root.ClientStateTracker

-- Utilities (Client)
ClientModuleDirectory.SnowballPool = Root.ClientUtils.SnowballPool
ClientModuleDirectory.SoundPlayer = Root.Sound.SoundPlayer
ClientModuleDirectory.InputHandler = Root.Input.InputHandler
ClientModuleDirectory.ClientCommands = Root.ClientCommands



-- Utilities (Shared)
ClientModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ClientModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil

return ClientModuleDirectory
