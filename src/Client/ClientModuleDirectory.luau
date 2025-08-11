-- Client Module Directory
local Root = script.Parent
local ModuleDirectory = {}

-- Core
ModuleDirectory.ClientEventHandler = Root.Core.ClientEventHandler
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler

-- Configuration
ModuleDirectory.Config = Root.ClientConfigurations
ModuleDirectory.Throwable.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData
ModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions

-- GUI
ModuleDirectory.GUI = {}
ModuleDirectory.GUI.AlertSystem = Root.GUI.AlertSystem
ModuleDirectory.AlertSystemBindings = Root.GUI.AlertSystemBindings
ModuleDirectory.GUI.Intermission = Root.GUI.Intermission
ModuleDirectory.GUI.InGameHUD = Root.GUI.InGameHUD

ModuleDirectory.GlobalVariables = Root.GlobalVariables

ModuleDirectory.ClientSnowballAnimator = Root.Gameplay.ClientSnowballAnimator

-- Gameplay
ModuleDirectory.PlayerPositionSender = Root.Gameplay.PlayerPositionSender
ModuleDirectory.ClientThrowableTracker = Root.Gameplay.ClientThrowableTracker
ModuleDirectory.ClientDestructionHandler = Root.Gameplay.ClientDestructionHandler
ModuleDirectory.HitBoxManager = Root.Gameplay.HitBoxManager
ModuleDirectory.PlayerHighlighter = Root.Gameplay.PlayerHighlighter
ModuleDirectory.ClientAmmoTracker = Root.Gameplay.ClientAmmoTracker
ModuleDirectory.SystemMessage = Root.SystemMessage

-- State Management
ModuleDirectory.StateChangeManager = Root.StateChangeManager
ModuleDirectory.ClientStateTracker = Root.ClientStateTracker

-- Utilities (Client)
ModuleDirectory.SnowballPool = Root.ClientUtils.SnowballPool
ModuleDirectory.SoundPlayer = Root.Sound.SoundPlayer
ModuleDirectory.InputHandler = Root.Input.InputHandler
ModuleDirectory.ClientCommands = Root.ClientCommands



-- Utilities (Shared)
ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil

return ModuleDirectory
