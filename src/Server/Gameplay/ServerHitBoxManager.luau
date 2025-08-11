local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Players = game:GetService("Players")
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerHitBoxManager = {}

local tagCallback = {}



local characterAddedConnections : {[number] : RBXScriptConnection} = {}
local hitBoxes : {[number] : Part} = {}

-- Creates the hitbox part (only once)
local function createPlayerHitbox()
	local hitbox = Instance.new("Part")
	hitbox.Name = "CentralHitbox"
	hitbox.Size = Vector3.new(2, 6, 2) -- adjust to desired player volume
	hitbox.Transparency = 0.5
	hitbox.Color = Color3.new(0.145098, 0.839215, 0.050980)
	hitbox.Anchored = false
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.CastShadow = false
	hitbox.CollisionGroup = "CG_GAMEPLAY"
	hitbox.CanQuery = true
	hitbox.CanTouch = true
	hitbox.TopSurface = Enum.SurfaceType.Smooth
	hitbox.BottomSurface = Enum.SurfaceType.Smooth
	hitbox.Parent = workspace -- initial parent; will be reparented when attached
	return hitbox
end

-- Welds the hitbox to the character's HumanoidRootPart so it follows cleanly
local function weldToCharacter(hitbox, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("Failed to find HumanoidRootPart to weld hitbox to")
		return
	end

	-- Reparent the hitbox under the character for cleanliness
	hitbox.Parent = character
	hitbox.Anchored = false

	-- Position it to match
	hitbox.CFrame = hrp.CFrame

	-- Remove any existing welds on the hitbox
	for _, child in ipairs(hitbox:GetChildren()) do
		if child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hitbox
	weld.Part1 = hrp
	weld.Parent = hitbox
end

function ServerHitBoxManager.setUpCallback(tagName: string, callback: (player : Player , otherPart: Instance) -> nil)
	tagCallback[tagName] = callback
end

function ServerHitBoxManager.init()
	-- Ensure single hitbox exists

	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player)
        hitBoxes[player.UserId] = createPlayerHitbox()
        local hitbox = hitBoxes[player.UserId]

		if player.Character then
			weldToCharacter(hitbox, player.Character)
		end

		characterAddedConnections[player.UserId] = player.CharacterAdded:Connect(function(character)
			weldToCharacter(hitbox,character)

			character.Humanoid.Died:Once(function()
				hitbox.Anchored = true
				hitbox.Parent = nil
			end)
		end)

		hitbox.Touched:Connect(function(otherPart)
			local tags = otherPart:GetTags()
			for _, each in tags do
				local f = tagCallback[each]
				if f then
					f(player , otherPart)
				end
			end
		end)
	end)

    Players.PlayerRemoving:Connect(function(player)
        
        if characterAddedConnections[player.UserId] then
            characterAddedConnections[player.UserId]:Disconnect()
        end

        if hitBoxes[player.UserId] then
             hitBoxes[player.UserId]:Destroy()
        end


    end)

end

return ServerHitBoxManager
