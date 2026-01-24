--//====================================================
--// Imports / Services
--//====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local Screens = require(ClientModuleDirectory.Gui.Screens)
local FrameSystem = require(ClientModuleDirectory.Gui.FrameSystem)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local Voting = {}

local choicesFrame: Frame? = nil
local choice1: Frame? = nil
local choice2: Frame? = nil
local choice3: Frame? = nil
local title: TextLabel = nil

local myVote = 0

local pressedColor = Color3.fromRGB(167, 10, 143)
local normalColor = Color3.fromRGB(219, 13, 181)

-- add near the top with other locals
local RunService = game:GetService("RunService")

local voteEndTime: number? = nil
local titleBaseText = "Map Vote"
local countdownConn: RBXScriptConnection? = nil

local function setTitleCountdown(secondsLeft: number)
	if not title then
		return
	end
	if secondsLeft < 0 then
		secondsLeft = 0
	end
	title.Text = `{titleBaseText} ({secondsLeft})`
end

local function stopCountdown()
	if countdownConn then
		countdownConn:Disconnect()
		countdownConn = nil
	end
	voteEndTime = nil
end

local function startCountdown(durationSeconds: number)
	stopCountdown()

	-- Use server time so the countdown is consistent for everyone.
	-- workspace:GetServerTimeNow() exists client-side.
	local now = workspace:GetServerTimeNow()
	voteEndTime = now + math.max(0, durationSeconds)

	-- Immediate paint
	setTitleCountdown(math.ceil(voteEndTime - now))

	local lastShown: number? = nil
	countdownConn = RunService.Heartbeat:Connect(function()
		if not voteEndTime then
			return
		end
		if not Voting.Gui or not Voting.Gui.Visible then
			return
		end

		local t = workspace:GetServerTimeNow()
		local remaining = math.ceil(voteEndTime - t)
		if remaining < 0 then
			remaining = 0
		end

		-- only update when the displayed number changes
		if lastShown ~= remaining then
			lastShown = remaining
			setTitleCountdown(remaining)
		end

		if remaining <= 0 then
			-- countdown finished; keep UI up until END_VOTE or hide now if you prefer
			stopCountdown()
		end
	end)
end

local function resetButton(button: Frame)
	local main: Frame? = button:FindFirstChild("Main")
	if main then
		main.BackgroundColor3 = normalColor
	end
end

local function pressButton(button: Frame)
	local main: Frame? = button:FindFirstChild("Main")
	if main then
		main.BackgroundColor3 = pressedColor
	end
end

local function resetAllButtons()
	if choice1 then
		resetButton(choice1.Vote)
	end
	if choice2 then
		resetButton(choice1.Vote)
	end
	if choice3 then
		resetButton(choice1.Vote)
	end
end

local function applyMyVoteVisual()
	resetAllButtons()

	if myVote == 1 and choice1 then
		pressButton(choice1.Vote)
	elseif myVote == 2 and choice2 then
		pressButton(choice1.Vote)
	elseif myVote == 3 and choice3 then
		pressButton(choice1.Vote)
	end
end

local function setMyVote(voteIndex: number)
	myVote = voteIndex
	applyMyVoteVisual()
end

function Voting.onProfileLoaded()
	local votingGuiTemplate = GuiAssets:WaitForChild("Voting"):WaitForChild("VotingMain")
	if not votingGuiTemplate then
		warn("Voting GUI template not found!")
		return
	end

	Voting.Gui = votingGuiTemplate:Clone()
	Voting.Gui.Parent = Screens.intermissionHUD
	Voting.Gui.Visible = false

	choicesFrame = Voting.Gui:WaitForChild("Choices")
	choice1 = choicesFrame:WaitForChild("Choice1")
	choice2 = choicesFrame:WaitForChild("Choice2")
	choice3 = choicesFrame:WaitForChild("Choice3")

	title = Voting.Gui:WaitForChild("Title")

	choice1.Vote.Clickable.Activated:Connect(function()
		setMyVote(1)
		RemoteEventHandler.FireOnServer("SEND_VOTE", 1)
	end)

	choice2.Vote.Clickable.Activated:Connect(function()
		setMyVote(2)
		RemoteEventHandler.FireOnServer("SEND_VOTE", 2)
	end)

	choice3.Vote.Clickable.Activated:Connect(function()
		setMyVote(3)
		RemoteEventHandler.FireOnServer("SEND_VOTE", 3)
	end)

	Voting.Gui.CloseButton.Clickable.Activated:Connect(function()
		Voting.Gui.Visible = false
	end)

	RemoteEventHandler.newEventConnection("VOTE_CHOICES_SET", function(choices: { [number]: string })
		choice1.MapName.Text = choices[1] or "N/A"
		choice2.MapName.Text = choices[2] or "N/A"
		choice3.MapName.Text = choices[3] or "N/A"

		-- If your UI got rebuilt / choices changed, re-apply your pressed state
		applyMyVoteVisual()
	end)

	RemoteEventHandler.newEventConnection("VOTE_TALLY_UPDATED", function(tally: { [number]: string })
		choice1.Tally.Text = tally[1] or "N/A"
		choice2.Tally.Text = tally[2] or "N/A"
		choice3.Tally.Text = tally[3] or "N/A"
	end)

	RemoteEventHandler.newEventConnection("END_VOTE", function(player)
		Voting.Gui.Visible = false

		stopCountdown() -- add this

		myVote = 0
		resetAllButtons()
	end)

	RemoteEventHandler.newEventConnection("START_VOTE", function(voteLenght)
		Voting.Gui.Visible = true
		FrameSystem.setCurrent(Voting.Gui)

		myVote = 0
		resetAllButtons()

		startCountdown(tonumber(voteLenght) or 0) -- add this
	end)
end

function Voting.hide() end

function Voting.show() end

return Voting
