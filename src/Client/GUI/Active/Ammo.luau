local Ammo = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local TouchButtons = require(ClientModuleDirectory.Gui.TouchButtons)

local AmmoGui : Frame?

function Ammo.onProfileLoaded()
	AmmoGui = GuiAssets:WaitForChild("InGame"):WaitForChild("Ammo")
	AmmoGui.Parent = Screens.gameHUD

	ClientAmmoTracker.setOnMaxAmmoChanged(function(maxammo)
		AmmoGui.Count.Text = 0 .. " / " .. maxammo
		AmmoGui.OutOfAmmo.Visible = true
	end)

	ClientAmmoTracker.setOnAmmoChanged(function(newAmmo, maxammo)
		AmmoGui.Count.Text = newAmmo .. " / " .. maxammo
		if newAmmo == 0 then
			AmmoGui.OutOfAmmo.Visible = true
		else
			AmmoGui.OutOfAmmo.Visible = false
		end
	end)

	if PlatformDetector.getPlatform() == "MOBILE" then
		
		AmmoGui.AnchorPoint = Vector2.new(AmmoGui.AnchorPoint.X , 1)
		local touchButtonsGui = TouchButtons.getGui()
		
		local yScale = touchButtonsGui.Position.Y.Scale - touchButtonsGui.Size.Y.Scale

		print("yscale" , yScale)

		AmmoGui.Position = UDim2.new(UDim.new(1 , 0) , UDim.new(yScale , 0))
		AmmoGui.UIScale.Scale = 1.2

	end

end



return Ammo
