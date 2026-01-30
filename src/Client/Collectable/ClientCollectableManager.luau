local Root = game.Players.LocalPlayer.PlayerScripts
local LocalPlayer = game.Players.LocalPlayer
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local CollectableData = require(script.Parent.CollectableDefinitions)

local HitBoxManager = require(ClientModuleDirectory.HitBoxManager)
local ParticlePlayer = require(ClientModuleDirectory.ParticlePlayer)

local CollectableSpinSpeed = 1

local ClientCollectableManager = {}

local collectableFolder: Folder?
local activeCollectable: { [string]: Instance } = {}

local function collectableDestroyed(id: string)
	local collectable = activeCollectable[id]
	if collectable then
		activeCollectable[id] = nil
		if collectable.Parent then
			collectable:Destroy()
		end
	end
end

local function spin(model: Model | Part)
	local targetPart: BasePart?

	if model.ClassName == "Model" then
		targetPart = model.PrimaryPart
		if not targetPart then
			-- Find the first part in the model
			for _, child in pairs(model:GetChildren()) do
				if child:IsA("BasePart") then
					targetPart = child
					break
				end
			end
		end
	elseif model.ClassName == "Part" then
		targetPart = model
	end

	if not targetPart then
		return
	end

	-- Unanchor the part
	targetPart.Anchored = false

	-- Create attachment
	local attachment = Instance.new("Attachment")
	attachment.Parent = targetPart

	-- Create angular velocity for spinning
	local angularVelocity = Instance.new("AngularVelocity")
	angularVelocity.Attachment0 = attachment
	angularVelocity.AngularVelocity = Vector3.new(0, CollectableSpinSpeed, 0)
	angularVelocity.MaxTorque = math.huge
	angularVelocity.Parent = targetPart

	-- Create linear velocity to keep it floating
	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	linearVelocity.Parent = targetPart
end

local function newCollectable(id: string, collectableType: string, worldPosition: Vector3, lifeSpan)
	local collectableDef = CollectableData[collectableType]
	if not collectableDef then
		return
	end

	local newCollectable: Model | Part = collectableDef.template:Clone()

	if newCollectable.ClassName == "Model" then
		local currentCFrame = newCollectable:GetPivot()
		newCollectable.PrimaryPart:AddTag("COLLECTABLE")
		newCollectable.PrimaryPart:SetAttribute("collectableId", id)
		newCollectable.PrimaryPart:SetAttribute("collectableType", collectableType)
		newCollectable:PivotTo(CFrame.new(worldPosition) * (currentCFrame - currentCFrame.Position))
	elseif newCollectable.ClassName == "Part" then
		local currentCFrame = newCollectable.CFrame
		newCollectable:AddTag("COLLECTABLE")
		newCollectable:SetAttribute("collectableId", id)
		newCollectable:SetAttribute("collectableType", collectableType)
		newCollectable.CFrame = CFrame.new(worldPosition) * (currentCFrame - currentCFrame.Position)
	end

	if collectableType == "ammo" then
		if newCollectable.ClassName == "Model" and newCollectable.PrimaryPart then
			newCollectable.PrimaryPart:AddTag("SNOWBALL_AMMO")
		else
			newCollectable:AddTag("SNOWBALL_AMMO")
		end
	elseif collectableType == "coin" then
		if newCollectable.ClassName == "Model" and newCollectable.PrimaryPart then
			newCollectable.PrimaryPart:AddTag("COIN_PICKUP")
		else
			newCollectable:AddTag("COIN_PICKUP")
		end
	end

	-- Store in active collectables and parent to workspace
	activeCollectable[id] = newCollectable
	newCollectable.Parent = collectableFolder

	-- Make it spin
	spin(newCollectable)
end

function ClientCollectableManager.onLoaded()
	collectableFolder = Instance.new("Folder", workspace)
	collectableFolder.Name = "Collectable"

	HitBoxManager.setUpCallback("COLLECTABLE", function(otherPart: Part)
		local collectableId = otherPart:GetAttribute("collectableId")
		if collectableId then
			RemoteEventHandler.FireOnServer("REQUEST_PICKUP", collectableId)
			print("rah")
		end
	end)

	HitBoxManager.setUpCallback("SNOWBALL_AMMO", function(otherPart: Part)
		SoundPlayer.playSound("ammo_pickup", { volume = 0.4 })
		if otherPart then
			ParticlePlayer.queueEmission("ammo_pickup", otherPart.Position)
			otherPart.Transparency = 1
		end
	end)

	HitBoxManager.setUpCallback("COIN_PICKUP", function(part: BasePart)
		ParticlePlayer.queueEmission("coin", part.Position, 12)
		SoundPlayer.playSound("coin_ding")
	end)

	RemoteEventHandler.newEventConnection("NEW_COLLECTABLE", newCollectable)

	RemoteEventHandler.newEventConnection("COLLECTABLE_DESTROYED", collectableDestroyed)
end

return ClientCollectableManager
