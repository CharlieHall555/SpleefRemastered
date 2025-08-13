local Player = game.Players.LocalPlayer
local Root = Player.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local GuiService = game:GetService("GuiService")
local InputHandler = require(ClientModuleDirectory.InputHandler)
local Debris = game:GetService("Debris")

local TapDebugView = {}

local enabled = false

local function makeFrame(color: Color3, position: Vector2, text: string?)
	local inset = GuiService:GetGuiInset()
	local adjustedPos = Vector2.new(position.X, position.Y) + Vector2.new(inset.X, inset.Y)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(20, 20)
	frame.Position = UDim2.fromOffset(adjustedPos.X - 10, adjustedPos.Y - 10)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Parent = Player.PlayerGui.General

	if text then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.ZIndex = 5
		label.TextScaled = true
		label.TextColor3 = Color3.new(0, 0, 0)
		label.Parent = frame
	end

	Debris:AddItem(frame, 3)
end

function TapDebugView.onLoaded()
	InputHandler.bindActionStart(Enum.UserInputType.Touch, function(action)
		if action.data.isClearOfUI and enabled == true then
			makeFrame(Color3.fromRGB(255, 0, 0), action.input.Position)
		end
	end)

	InputHandler.bindActionEnd(Enum.UserInputType.Touch, function(action)
		if enabled == true then
			local lengthText = string.format("%.2f", action.length)
			makeFrame(Color3.fromRGB(0, 255, 0), action.input.Position, lengthText)
		end
	end)
end

function TapDebugView.toggle()
	enabled = not enabled
end

return TapDebugView
