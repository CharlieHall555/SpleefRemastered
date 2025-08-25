-- ModuleScript: ToolBarUtilities.lua
-- No CoreGui access. Uses PlatformDetector + ViewportSize + GuiService:GetGuiInset()

local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)

local ToolBarUtilities = {}
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

-- Is the Backpack (hotbar) enabled?
local function backpackEnabled(): boolean
	local ok, enabled = pcall(function()
		return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
	end)
	return ok and enabled == true
end

-- Bottom/right OS insets (e.g., home indicator). GetGuiInset returns (topLeft, bottomRight).
local function bottomInsetPx(): number
	local ok, topLeft, bottomRight = pcall(function()
		return GuiService:GetGuiInset()
	end)
	if ok and typeof(bottomRight) == "Vector2" then
		return bottomRight.Y or 0
	end
	return 0
end

-- Heuristic hotbar height in px from viewport height + platform
local function estimateToolbarPx(viewH: number, platform: string): number
	platform = string.upper(platform or "")
	if platform == "MOBILE" or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
		-- 0.085 * 0.85 = 0.07225 ; clamps also reduced ~15%
		return math.clamp(math.floor(viewH * 0.07225 + 0.5), 61, 109)
	else
		return math.clamp(math.floor(viewH * 0.060 + 0.5), 56, 96)
	end
end

-- Returns the Y scale (0..1) of the TOP of the estimated hotbar.
-- opts = { marginPx?: number, includeSafeArea?: boolean, platform?: "PC"|"MOBILE" }
function ToolBarUtilities.hotBarAnchorPoint(opts: { marginPx: number?, includeSafeArea: boolean?, platform: string? }?): number?
	opts = opts or {}
	local marginPx = opts.marginPx ~= nil and opts.marginPx or 8
	local includeSafe = (opts.includeSafeArea ~= false)

	local cam = workspace.CurrentCamera
	if not cam then return nil end

	local viewH = cam.ViewportSize.Y
	if viewH <= 0 then return nil end

	local platform = opts.platform or (PlatformDetector.getPlatform and PlatformDetector.getPlatform()) or (UserInputService.TouchEnabled and "MOBILE" or "PC")

	local reservePx = 0
	if backpackEnabled() then
		reservePx = estimateToolbarPx(viewH, platform)
	end

	local safePx = includeSafe and bottomInsetPx() or 0

	local yScale = 1 - ((reservePx + safePx + marginPx) / viewH)
	if yScale < 0 then yScale = 0 end
	if yScale > 1 then yScale = 1 end
	return yScale
end

-- Convenience: suggested Position + AnchorPoint for a bottom HUD sitting above the toolbar.
function ToolBarUtilities.suggestBottomPosition(marginPx: number?, includeSafeArea: boolean?, platform: string?)
	local y = ToolBarUtilities.hotBarAnchorPoint({
		marginPx = marginPx,
		includeSafeArea = includeSafeArea,
		platform = platform,
	})
	if not y then return nil end
	return UDim2.new(0.5, 0, y, 0), Vector2.new(0.5, 1)
end

return ToolBarUtilities
