--Client Module Directory 
local Root = script.Parent
local ModuleDirectory = {}

ModuleDirectory.ClientEventHandler = Root.Core.ClientEventHandler
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler
ModuleDirectory.PlayerPositionSender = Root.Gameplay.PlayerPositionSender
ModuleDirectory.Config = Root.ClientConfigurations

ModuleDirectory.ClientThrowableTracker = Root.Gameplay.ClientThrowableTracker

ModuleDirectory.HitBoxManager = Root.Gameplay.HitBoxManager

ModuleDirectory.PartPool = game:GetService("ReplicatedStorage").Utilities.PartPool

return ModuleDirectory