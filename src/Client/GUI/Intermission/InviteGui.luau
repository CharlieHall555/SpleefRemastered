--//====================================================
--// Imports / Services
--//====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local inviteGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("Invite")
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local Invite = {}

function Invite.onProfileLoaded()

	if PlatformDetector.getPlatform() == "MOBILE" then
		inviteGui = GuiAssets:WaitForChild("Intermission"):WaitForChild("InviteMobile")
	end

    inviteGui.Parent = Screens.intermissionHUD
	inviteGui.Visible = false
    
    inviteGui.InviteButton.Clickable.Activated:Connect(function(inputObject, clickCount)
        
        SocialService:PromptGameInvite(LocalPlayer)

    end)

	inviteGui.CloseButton.Clickable.Activated:Connect(function(inputObject, clickCount)
		
		inviteGui.Visible = false
		FrameSystem.setCurrent(nil)

	end)

end

function Invite.show()

	inviteGui.Visible = true
	FrameSystem.setCurrent(inviteGui)

end

return Invite
