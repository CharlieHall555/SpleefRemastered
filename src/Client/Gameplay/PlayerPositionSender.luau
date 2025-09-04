local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local player = game.Players.LocalPlayer
local ClientTutorial = require(ClientModuleDirectory.ClientTutorial)

local PlayerPositionSender = {}

function PlayerPositionSender.init()
	RunService.RenderStepped:Connect(function()
		local pos
		if player.Character and player.Character.PrimaryPart then
			pos = player.Character.PrimaryPart.Position

			if player.Character.Humanoid then
				if player.Character.Humanoid.MoveDirection.Magnitude > 0 then
					ClientTutorial.onAction("MOVE")
				end
			end
		else
			pos = nil
		end

		RemoteEventHandler.FireUnreliableOnServer("UpdatePlayerPosition", pos)
	end)
end

return PlayerPositionSender
