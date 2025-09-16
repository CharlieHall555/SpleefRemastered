local OverheadTemplate: BillboardGui = game:GetService("ServerStorage"):WaitForChild("Overhead")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local Players = game:GetService("Players")

local OverheadGui = {}
local connections: { [Player]: { RBXScriptConnection } } = {}

local function giveOverhead(player : Player , character: Model)
	local newGui = OverheadTemplate:Clone()
	newGui.Parent = character
	newGui.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
	newGui.NameLabel.Text = player.DisplayName
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
