--Client Module Directory 
local Root = script.Parent
local ModuleDirectory = {}

ModuleDirectory.ClientEventHandler = Root.Core.ClientEventHandler
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler
ModuleDirectory.PlayerPositionSender = Root.Gameplay.PlayerPositionSender
ModuleDirectory.Config = Root.ClientConfigurations
ModuleDirectory.ThrowableData = game:GetService("ReplicatedStorage").Types.ThrowableData

ModuleDirectory.ClientThrowableTracker = Root.Gameplay.ClientThrowableTracker
ModuleDirectory.ClientDestructionHandler = Root.Gameplay.ClientDestructionHandler

ModuleDirectory.HitBoxManager = Root.Gameplay.HitBoxManager

ModuleDirectory.SnowballPool = Root.ClientUtils.SnowballPool  

ModuleDirectory.SoundPlayer = Root.SoundPlayer

ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool
ModuleDirectory.VectorUtil = game:GetService("ReplicatedStorage").Utilities.VectorUtil
ModuleDirectory.ThrowableDefinitions = game:GetService("ReplicatedStorage").Data.ThrowableDefinitions

ModuleDirectory.InputHandler = Root.Input.InputHandler

return ModuleDirectory