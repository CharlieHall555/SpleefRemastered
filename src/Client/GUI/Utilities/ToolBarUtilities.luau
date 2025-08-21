local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local ToolBarUtilities = {}
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local LocalizationService = game:GetService("LocalizationService")

function ToolBarUtilities.getHotBar() : Frame?
	-- Try to find the CoreGui hotbar safely
	local ok, hotbar = pcall(function()
		local RobloxGui = CoreGui:FindFirstChild("RobloxGui")
		if not RobloxGui then return nil end

		local Backpack = RobloxGui:FindFirstChild("Backpack")
		if not Backpack then return nil end

		-- Different client versions sometimes vary name casing
		return Backpack:FindFirstChild("Hotbar")
			or Backpack:FindFirstChild("HotBar")
			or Backpack:FindFirstChild("HotBarFrame")
	end)

	if ok then
		if hotbar and hotbar:IsA("Frame") then
			return hotbar
		end
	end
	return nil
end

-- Returns the Y scale (0..1) of the TOP of the hotbar.
-- Use this to position your UI right above the toolbar:
--   local yScale = ToolBarUtilities.hotBarAnchorPoint()
--   myFrame.Position = UDim2.new(0.5, 0, yScale, -8) -- 8px margin above
function ToolBarUtilities.hotBarAnchorPoint(considerInset : boolean) : number?
	considerInset = considerInset or false
	local HotBar = ToolBarUtilities.getHotBar()
	if not HotBar then
		return nil
	end

	-- GetGuiInset returns (topLeftInset, bottomRightInset); not needed
	-- but shown here in case you want it:
	local yInset = GuiService:GetGuiInset().Y

	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local screenSizeY = camera.ViewportSize.Y
	if screenSizeY <= 0 then
		return nil
	end

	local absoluteY = HotBar.AbsolutePosition.Y  -- pixel Y of hotbar TOP

	if considerInset then
		absoluteY += yInset
	end

	local yScale = absoluteY / screenSizeY
	-- Clamp to safe range
	if yScale < 0 then yScale = 0 end
	if yScale > 1 then yScale = 1 end

	return yScale
end

return ToolBarUtilities
