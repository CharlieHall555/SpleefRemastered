local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage"):WaitForChild("GuiAssets")
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local NameGuiTemplate: BillboardGui = GuiAssets:WaitForChild("NameGui") -- must contain TextLabel "NameTag"
local TAG_NAME = "NameGui"

local NameTag = {}

-- State
local enabled = false
local playerAddedConn: RBXScriptConnection? = nil
local playerRemovingConn: RBXScriptConnection? = nil
local charAddedConns: { [Player]: RBXScriptConnection } = {}
local displayNameConns: { [Player]: RBXScriptConnection } = {}
local labelByPlayer: { [Player]: TextLabel } = {}

-- Utilities
local function destroyTagOnCharacter(character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BillboardGui") and child.Name == TAG_NAME then
			child:Destroy()
		end
	end
end

local function destroyAllTags()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			destroyTagOnCharacter(plr.Character)
		end
	end
	labelByPlayer = {}
end

local function setLabelForPlayer(plr: Player, label: TextLabel?)
	if not label then
		labelByPlayer[plr] = nil
		return
	end
	label.Text = plr.DisplayName or plr.Name
	labelByPlayer[plr] = label
end

local function ensureDisplayNameHook(plr: Player)
	-- Connect once per player; reuse for new characters/labels
	if displayNameConns[plr] and displayNameConns[plr].Connected then
		return
	end
	displayNameConns[plr] = plr:GetPropertyChangedSignal("DisplayName"):Connect(function()
		local lbl = labelByPlayer[plr]
		if lbl and lbl.Parent then
			lbl.Text = plr.DisplayName or plr.Name
		end
	end)
end

local function attachToCharacter(plr: Player, character: Model)
	if not enabled then return end

	local adorneePart = character:FindFirstChild("Head") or character:WaitForChild("Head", 1) or character.PrimaryPart
	if not adorneePart then
         return 
    end

	-- Create only if missing, otherwise reuse existing
	local tag: BillboardGui? = character:FindFirstChild(TAG_NAME) :: BillboardGui?
	if not tag or not tag:IsA("BillboardGui") then
		tag = NameGuiTemplate:Clone()
		tag.Name = TAG_NAME
		tag.Adornee = adorneePart
		tag.Parent = character
	else
		-- Make sure adornee stays correct
		tag.Adornee = adorneePart
	end

	local label = tag:FindFirstChild("NameTag")
	if label and label:IsA("TextLabel") then
		setLabelForPlayer(plr, label)
	end

	ensureDisplayNameHook(plr)
end

local function hookPlayer(plr: Player)
	-- CharacterAdded hook (one per player)
	if not (charAddedConns[plr] and charAddedConns[plr].Connected) then
		charAddedConns[plr] = plr.CharacterAdded:Connect(function(char)
			if enabled then
				attachToCharacter(plr, char)
			end
		end)
	end

	-- Attach immediately if character already exists
	if enabled and plr.Character then
		attachToCharacter(plr, plr.Character)
	end
end

local function unhookPlayer(plr: Player)
	if charAddedConns[plr] then
		charAddedConns[plr]:Disconnect()
		charAddedConns[plr] = nil
	end
	if displayNameConns[plr] then
		displayNameConns[plr]:Disconnect()
		displayNameConns[plr] = nil
	end
	labelByPlayer[plr] = nil
end

-- Public API
function NameTag.init()
	NameTag.enable()

    ClientStateTracker.connectActive(function()
        
        task.spawn(NameTag.disable) 

    end)

    ClientStateTracker.connectIntermission(function()
        
        task.spawn(NameTag.enable) 

    end)


end

function NameTag.enable()
	if enabled then
		-- Already on; just ensure all players have tags
		for _, plr in ipairs(Players:GetPlayers()) do
			hookPlayer(plr)
		end
		return
	end

	enabled = true

	-- Global hooks
	if not playerAddedConn or not playerAddedConn.Connected then
		playerAddedConn = Players.PlayerAdded:Connect(function(plr)
			if not enabled then return end
			hookPlayer(plr)
		end)
	end

	if not playerRemovingConn or not playerRemovingConn.Connected then
		playerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
			unhookPlayer(plr)
		end)
	end

	-- Ensure tags for everyone currently present
	for _, plr in ipairs(Players:GetPlayers()) do
		hookPlayer(plr)
	end
end

function NameTag.disable()
	if not enabled then return end
	enabled = false

	-- Disconnect global hooks
	if playerAddedConn then playerAddedConn:Disconnect() playerAddedConn = nil end
	if playerRemovingConn then playerRemovingConn:Disconnect() playerRemovingConn = nil end

	-- Disconnect per-player hooks
	for _, plr in ipairs(Players:GetPlayers()) do
		unhookPlayer(plr)
	end

	-- Destroy all existing tags so no one has nameplates
	destroyAllTags()
end

return NameTag
