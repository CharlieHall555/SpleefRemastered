local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local MouseIcon = require(ClientModuleDirectory.MouseIcon)
local ClientToolManager = require(ClientModuleDirectory.ClientToolManager)
local PlatformDetector = (require(ClientModuleDirectory.PlatformDetector))
local ClientBlockSelector = {}
local GuiService = game:GetService("GuiService")

local enabled = false

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera: Camera?
local highlight: Highlight?

local localPlayer = game.Players.LocalPlayer

local selectionRaycast = RaycastParams.new()
selectionRaycast.CollisionGroup = "CG_BLOCK_SELECTION"
selectionRaycast.FilterType = Enum.RaycastFilterType.Exclude
selectionRaycast.FilterDescendantsInstances = {}

local RAYCAST_MAX = 300
local MAX_SELECTION_DISTANCE = 25

local selectedBlock: Part?
local _renderConn: RBXScriptConnection?

local function getMouseRay(): Ray
    if not Camera then
        return Ray.new(Vector3.zero, Vector3.zAxis)
    end
    local m = UserInputService:GetMouseLocation()
    local unitRay = Camera:ViewportPointToRay(m.X, m.Y)
    return Ray.new(unitRay.Origin, unitRay.Direction * RAYCAST_MAX)
end

local function withinDistance(p: Vector3): boolean
    local char = localPlayer.Character
    if not char then
        return false
    end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: Part?
    if not hrp then
        return false
    end
    return (hrp.Position - p).Magnitude <= MAX_SELECTION_DISTANCE
end

function ClientBlockSelector.getMobileSelected(tapPos: Vector2): Instance?
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local inset = GuiService:GetGuiInset()
    local viewportPos = tapPos + Vector2.new(inset.X, inset.Y)

    local unitRay = camera:ViewportPointToRay(viewportPos.X, viewportPos.Y)

    selectionRaycast.FilterType = Enum.RaycastFilterType.Exclude
    selectionRaycast.FilterDescendantsInstances = { game.Players.LocalPlayer.Character }

    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, selectionRaycast)
    if result then

        if withinDistance(result.Position) then
            return result.Instance
        end
    end

    return nil
end


local function focus(part: Part): nil
    MouseIcon.shovel()
    selectedBlock = part
    if highlight then
        highlight.Adornee = part
        highlight.Enabled = true
        return
    end
    if not highlight then
        return
    end
    highlight.Adornee = part
    highlight.Enabled = true

end

local function unfocus(): nil
    MouseIcon.reset()
    selectedBlock = nil
    if highlight then
        highlight.Enabled = false
        highlight.Adornee = nil
    end
end

local function step()
    if not enabled then
        unfocus()
        return
    end

    if not Camera then
        Camera = workspace.CurrentCamera
        if not Camera then
            unfocus()
            return
        end
    end

    local ray = getMouseRay()
    local result = workspace:Raycast(ray.Origin, ray.Direction, selectionRaycast)

    if result and result.Instance and result.Instance:IsA("Part") and withinDistance(result.Position) and ClientToolManager.isToolEquipped() then
        local hitPart = result.Instance :: Part
        if hitPart ~= selectedBlock then
            focus(hitPart)
        end
    else
        if selectedBlock then
            unfocus()
        end
    end
end

function ClientBlockSelector.init()
    highlight = game:GetService("ReplicatedStorage"):WaitForChild("BlockHighlight", 5) :: Highlight?
    assert(highlight, "BlockHighlight missing in ReplicatedStorage")
    highlight.Parent = game.Players.LocalPlayer.PlayerGui
    highlight.Enabled = false

 
    
end

function ClientBlockSelector.onLoaded()
    Camera = workspace.CurrentCamera
    if _renderConn then
        _renderConn:Disconnect()
        _renderConn = nil
    end
    
    _renderConn = RunService.RenderStepped:Connect(step)

    if PlatformDetector.getPlatform() == "PC" then
        ClientBlockSelector.enable()
    end
end

function ClientBlockSelector.getSelected(): Part?
    return selectedBlock
end

function ClientBlockSelector.enable(): nil
    enabled = true
end

function ClientBlockSelector.disable(): nil
    enabled = false
    unfocus()
end

return ClientBlockSelector
