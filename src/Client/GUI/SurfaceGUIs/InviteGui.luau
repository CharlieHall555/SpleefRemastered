local Players = game:GetService("Players")

local Root = Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local InvitePart = game.Workspace.Lobby.InvitePart

local InviteGui = {}

local inviteGui : Frame

local canInvite : boolean

function InviteGui.onProfileLoaded()

    canInvite = SocialService:CanSendCallInviteAsync(LocalPlayer)

    inviteGui = GuiAssets.LobbyGUIs.InviteFriendGui
    inviteGui.Parent = LocalPlayer.PlayerGui
    inviteGui.Adornee = InvitePart

    inviteGui.Main.InviteButton.Clickable.Activated:Connect(function(inputObject, clickCount)
        
        SocialService:PromptGameInvite(LocalPlayer)

    end)

    inviteGui.Enabled = canInvite

end

return InviteGui