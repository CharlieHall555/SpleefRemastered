local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local UserSessionVariables = require(ClientModuleDirectory.Profile.UserSessionVariables)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local RewardsData = require(ClientModuleDirectory.RewardsData)
local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local LobbyChallenge = {}

local lobbyChallengeGui : Frame

function LobbyChallenge.onProfileLoaded()
    
    lobbyChallengeGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("IntermissionChallenge")
    lobbyChallengeGui.Parent = Screens.intermissionHUD
    lobbyChallengeGui.Visible = false

end

return LobbyChallenge