local LocalizationService = game:GetService("LocalizationService")
local OverheadTemplate: BillboardGui = game:GetService("ServerStorage"):WaitForChild("Overhead")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerData = require(ModuleDirectory.Player.PlayerData)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local PlayerSessionVariables = require(ModuleDirectory.Player.SessionVariables)

local Players = game:GetService("Players")

local OverheadGui = {}
local connections: { [Player]: { RBXScriptConnection } } = {}

local rankColorMappings = {
	["VIP"] = Color3.fromRGB(255, 205, 23),
	["MEMBER"] = Color3.fromRGB(0, 170, 255),
	["DEVELOPER"] = Color3.fromRGB(217, 0, 255),
}

local function computeRank(player)

	if (PlayerSessionVariables.getValue(player , "isDev") or false) == true then
		return "DEVELOPER"
	elseif (PlayerSessionVariables.getValue(player , "isVip") or false) == true then
		return "VIP"	
	elseif (PlayerSessionVariables.getValue(player , "inGroup") or false) == true then
		return "MEMBER"
	else
		return nil
	end

end

local function giveOverhead(player : Player , character: Model)

	local overhead = player.Character:FindFirstChild("OverheadNametag")
	if overhead then
		overhead:Destroy()
	end

	local newGui = OverheadTemplate:Clone()
	newGui.Parent = character
	newGui.Name = "OverheadNametag"
	newGui.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
	newGui.NameLabel.Text = player.DisplayName
	newGui.WinsLabel.Text = " ["  ..tostring(PlayerData.getWins(player) or 0) .." Wins]"
	newGui.WinsLabel.Visible = true

	local rank = computeRank(player)
	if rank then
		newGui.NameLabel.Text = "[" .. rank .. "] " .. player.DisplayName
		newGui.NameLabel.TextColor3 = rankColorMappings[rank] or Color3.fromRGB(255, 255, 255)
		newGui.NameLabel.Visible = true
	else
		newGui.NameLabel.Visible = false
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
