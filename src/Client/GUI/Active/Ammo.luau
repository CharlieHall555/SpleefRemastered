local Ammo = {}

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local localPlayer = game.Players.LocalPlayer
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientAmmoTracker = require(ClientModuleDirectory.ClientAmmoTracker)
local Screens = require(ClientModuleDirectory.Gui.Screens)

local AmmoGui

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

    ClientAmmoTracker.setOnRegenProgressChanged(function(newProgress , maxProgress)
		AmmoGui.Regen.Fillable.Size = UDim2.fromScale(newProgress / maxProgress , 1) 

        if AmmoGui.Regen.Fillable.Size.X.Scale <= 0.01 then
            AmmoGui.Regen.Fillable.UIStroke.Enabled = false
        else
            AmmoGui.Regen.Fillable.UIStroke.Enabled = true
        end
	end)

	
end



return Ammo
