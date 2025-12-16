local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local localPlayer = game.Players.LocalPlayer
local SocialService = game:GetService("SocialService")

local InviteFriendsZone = {}

local Zones: Folder
local ZonePart: Part
local lastOpenTime = 0
local cooldown = 3 -- seconds

function InviteFriendsZone.onLoaded()
	Zones = game.Workspace:WaitForChild("Zones", 5)

	if not Zones then
		warn("InviteFriendsZone: Zones folder not found in Workspace")
		return
	end

	ZonePart = Zones:WaitForChild("InviteFriends", 5)

	if not ZonePart then
		warn("InviteFriendsZone: InviteFriendsZone zone part not found in Zones folder")
		return
	end

	task.spawn(function()
        local CanInvite = false
        local ok , err = pcall(function()
		    CanInvite = SocialService:CanSendCallInviteAsync(localPlayer)
        end)

        CanInvite = ok and CanInvite

		if CanInvite and ZonePart then
			ZonePart.Touched:Connect(function(hit: BasePart)
				local character = hit.Parent
				if character and character:FindFirstChild("Humanoid") then
					local player = game.Players:GetPlayerFromCharacter(character)
					if player and player == localPlayer then
						local now = tick()
						if now - lastOpenTime >= cooldown then
							lastOpenTime = now
							local ok, err = pcall(function()
                                print("open")
								SocialService:PromptGameInvite(localPlayer)
							end)
						end
					end
				end
			end)
		else
			ZonePart:Destroy()
		end
	end)
end

return InviteFriendsZone
