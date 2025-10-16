local OverheadTemplate: BillboardGui = game:GetService("ServerStorage"):WaitForChild("Overhead")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerSessionVariables = require(ModuleDirectory.Player.SessionVariables)

local Players = game:GetService("Players")

local OverheadGui = {}
local connections: { [Player]: { RBXScriptConnection } } = {}

local function giveOverhead(player : Player , character: Model)
	local newGui = OverheadTemplate:Clone()
	newGui.Parent = character
	newGui.Name = "OverheadNametag"
	newGui.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
	newGui.NameLabel.Text = player.DisplayName
	newGui.WinsLabel.Text = " ["  ..tostring(PlayerData.getWins(player) or 0) .." Wins]"
	newGui.WinsLabel.Visible = true

	if (PlayerSessionVariables.getValue(player , "isVip") or false) == true then
		newGui.NameLabel.TextColor3 = Color3.fromRGB(255, 205, 23)
		newGui.NameLabel.Text = "[VIP] " ..  player.DisplayName
	end

end

function OverheadGui.refreshForPlayer(player : Player)
	if player.Character then
		local overhead = player.Character:WaitForChild("OverheadNametag" , 2)
		if overhead then
			overhead:Destroy()
		end
		giveOverhead(player , player.Character)
	end
	
end

function OverheadGui.init()
	RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
		connections[player] = {}

        if player.Character then
            giveOverhead(player , player.Character)
        end

		local charAddedConn = player.CharacterAdded:Connect(function(character: Model) 
            giveOverhead(player , character)
        end)

		table.insert(connections[player], charAddedConn)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		if connections[player] then
			for _, conn in ipairs(connections[player]) do
				conn:Disconnect()
			end
			connections[player] = nil
		end
	end)
end

return OverheadGui
