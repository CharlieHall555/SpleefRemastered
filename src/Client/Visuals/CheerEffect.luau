local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local LocalPlayer = game.Players.LocalPlayer
local ParticleText = require(ClientModuleDirectory.Gui.ParticleText)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local cheerEffectTemplate: Part

local CheerEffect = {}

function CheerEffect.init()
	cheerEffectTemplate =
		game:GetService("ReplicatedStorage").Resources:WaitForChild("Cheer"):WaitForChild("CheerEffect")

	RemoteEventHandler.newEventConnection("CHEERED_PLAYER", CheerEffect.onCheer)
end

function CheerEffect.onCheer(target: Player, from: Player)
	task.spawn(function()
		if target.Character and target.Character.PrimaryPart then
			local playPos = target.Character.PrimaryPart.Position + Vector3.new(0, 6, 0)
			--SoundPlayer.queuePositionalSound("rbxassetid://135428675638330", playPos)

			if target == LocalPlayer or from == LocalPlayer then
				--SoundPlayer.queuePositionalSound("rbxassetid://97218547862968", playPos)
			end

			local fromString = ""
			if from then
				fromString = from.DisplayName
			end

			task.wait(1)
			CheerEffect.playParticle(playPos)

			if target == LocalPlayer then
				local parentGui = Screens.gameHUD
				local absSize = parentGui.AbsoluteSize
				local screenCenter = Vector2.new(absSize.X / 2, absSize.Y / 2)

				local opts = {
					image = "rbxassetid://113489472341219",
					speed = Vector2.new(math.random(-50, 50) / 100, math.random(20, 50) / 100),
					color = Color3.fromRGB(
						math.random(50, 255), -- avoid too-dark colors
						math.random(50, 255),
						math.random(50, 255)
					),
					lifetime = 5,
					size = UDim2.fromScale(0.144, 0.12),
				}

				ParticleText.new(
					parentGui,
					fromString .. " Cheered you on!",
					screenCenter + Vector2.new(math.random(-100, 100), math.random(-100, 100)),
					opts
				)
			end
		end
	end)
end

function CheerEffect.onWin(winnerName: string, winner: Player)
	print("win effect")
	task.spawn(function()
		task.wait(3)
		for _ = 1, 3 do
			print("hi")
			--local newWinner = Players:GetPlayerByUserId(winner.UserId) -- get a fresh copy of winner

			if winner and winner.Character and winner.Character.PrimaryPart then
				local playPos = winner.Character.PrimaryPart.Position + Vector3.new(0, 6, 0)
				local offset = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
				--SoundPlayer.queuePositionalSound("rbxassetid://135428675638330", playPos)
				task.wait(0.1)
				CheerEffect.playParticle(playPos + offset)
			else
				print(false)
			end
			task.wait(0.5)
		end
	end)
end

function CheerEffect.playParticle(position: Vector3)
	if ParticlePlayer.getVisible() then
		local newEffect = cheerEffectTemplate:Clone()
		newEffect.Position = position
		newEffect.Parent = game.Workspace
		Debris:AddItem(newEffect, 5)

		for _, each in newEffect:GetChildren() do
			if each:isA("ParticleEmitter") then
				each:Emit(10)
			end
		end
	end
end

return CheerEffect
