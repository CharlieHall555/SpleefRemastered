local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local GuiAssets = game:GetService("ReplicatedStorage").GuiAssets
local TweenService = game:GetService("TweenService")
local Screens = require(ClientModuleDirectory.Gui.Screens)

local SummaryWidget = {}

local SummaryWidgetGui: Frame

local blocksDestroyedLabel: TextLabel
local elininationsLabel: TextLabel
local timeAliveLabel: TextLabel

local closeButtonClickable: TextButton

export type Record = {
	blocksDestroyed: number,
	elininations: number,
	timeAlive: number, -- seconds
}


function SummaryWidget.onProfileLoaded()
	SummaryWidgetGui = GuiAssets.Intermission.SummaryWidget
	SummaryWidgetGui.Parent = Screens.intermissionHUD
	SummaryWidgetGui.Visible = false

	blocksDestroyedLabel = SummaryWidgetGui.SummaryHolder.BlocksDestroyed.ValueLabel
	timeAliveLabel = SummaryWidgetGui.SummaryHolder.TimeAlive.ValueLabel
	elininationsLabel = SummaryWidgetGui.SummaryHolder.Eliminations.ValueLabel

	closeButtonClickable = SummaryWidgetGui.CloseButton.Clickable

	--RemoteEventHandler.newEventConnection("ROUND_SUMMARY" , SummaryWidget.show)

	closeButtonClickable.Activated:Connect(function(inputObject, clickCount)
		
		SummaryWidgetGui.Visible = false

	end)

end



function SummaryWidget.show(record : Record)

	timeAliveLabel.Text = math.floor(record.timeAlive) .. " s"
	elininationsLabel.Text = record.elininations
	blocksDestroyedLabel.Text = record.blocksDestroyed

	SummaryWidgetGui.Visible = true

	task.spawn(function()

		task.wait(10)
		SummaryWidgetGui.Visible = false
		
	end)


end




	
return SummaryWidget
