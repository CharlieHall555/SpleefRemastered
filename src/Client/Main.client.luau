local Root = script.Parent
local QueryLoaded = game:GetService("ReplicatedStorage"):WaitForChild("QueryLoaded")
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local Player = game.Players.LocalPlayer
local loadingScreen = Player.PlayerGui:WaitForChild("Loading")
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local isServerLoaded = false
while isServerLoaded == false do
	isServerLoaded = QueryLoaded:InvokeServer()
	print(isServerLoaded)
	task.wait(0.1)
end

local ClientLoader = require(Root.Core.ClientLoader)
ClientLoader.init()
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local ProfileLoaded = false
while ProfileLoaded == false do
	ProfileLoaded = RemoteEventHandler.InvokeOnServer("QUERY_PROFILE_LOAD", 1)
	print("profileload", ProfileLoaded)
	task.wait(0.1)
end

local UserProfile = require(ClientModuleDirectory.Profile.UserProfile)
UserProfile.loadProfile()
ClientLoader.profileLoaded()

local ButtonUtilities = require(ClientModuleDirectory.Gui.ButtonUtilities)
ButtonUtilities.parseRoot()

pcall(function()
	loadingScreen.removeEvent:Fire()
end)

RemoteEventHandler.FireOnServer("PLAYER_LOADED", PlatformDetector.getPlatform())

local ClientThrowableTracker = require(ClientModuleDirectory.ClientThrowableTracker)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)
local ClientBlockSelector = require(ClientModuleDirectory.ClientBlockSelector)
local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local player = game.Players.LocalPlayer

HitBoxManager.setUpCallback("SNOWBALL_AMMO", function(otherPart: Part)
	local increment = otherPart:GetAttribute("Increment") or 1
	SoundPlayer.playSound("rbxassetid://18919192805", { volume = 0.4 })
	--ClientAmmoTracker.predictIncrement(increment)
	otherPart.Transparency = 1
end)

local ClientDestructionHandler = require(ClientModuleDirectory.ClientDestructionHandler)

ClientThrowableTracker.registerOnHit("snowball", function(throwable: ClientThrowableTracker.Throwable, hit)
	if hit.Instance and hit.Instance:IsA("Part") then
		--redudant client side destruction prediciton became to hard to sync so stopped work for now.
		--ClientDestructionHandler.destroyBlock(hit.Instance)
	end
end)

local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)

local AlertSystem = require(ClientModuleDirectory.Gui.AlertSystem)

local n = 0

local SystemMessage = require(ClientModuleDirectory.Chat.SystemMessage)

local MouseIcon = require(ClientModuleDirectory.Gui.MouseIcon)

local Ghost = require(ClientModuleDirectory.Spectate.Ghost)

local freecam = require(ClientModuleDirectory.Spectate.FreecamMode)

local cheerEffect = require(ClientModuleDirectory.CheerEffect)

local MobileCamera = require(ClientModuleDirectory.Input.MobileCamera)

local LogHandler = require(ClientModuleDirectory.LogHandler)

RemoteEventHandler.newEventConnection("ROUND_SUMMARY" , function(value)
	print("RECORD" ,  value)
	
end)

local BackwardsEdgeDetector = require(ClientModuleDirectory.Input.BackwardsEdgeDetector)
