--Client Module Directory 
local Root = script.Parent
local ModuleDirectory = {}

ModuleDirectory.ClientEventHandler = Root.Core.ClientEventHandler
ModuleDirectory.RemoteEventHandler = game:GetService("ReplicatedStorage").RemoteEventHandler
ModuleDirectory.PlayerPositionSender = Root.Gameplay.PlayerPositionSender

ModuleDirectory.HitBoxManager = Root.Gameplay.HitBoxManager


return ModuleDirectory