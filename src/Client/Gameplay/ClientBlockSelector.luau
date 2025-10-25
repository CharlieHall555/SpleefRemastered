local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local MouseIcon = require(ClientModuleDirectory.Gui.MouseIcon)
local ClientToolManager = require(ClientModuleDirectory.ClientToolManager)
local PlatformDetector = require(ClientModuleDirectory.Input.PlatformDetector)
local GuiService = game:GetService("GuiService")
local Screens = require(ClientModuleDirectory.Gui.Screens)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local CrossHair = require(ClientModuleDirectory.Gui.CrossHair)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ClientBlockSelector = {}

local enabled = false

local Camera: Camera?
local highlight: Highlight?
local selectedBlock: Part?
local focusedBlock: Part? -- the block that is either looked at or selected regardless of Max_selection_distance
local _renderConn: RBXScriptConnection?

local localPlayer = game.Players.LocalPlayer

local selectionRaycast = RaycastParams.new()
selectionRaycast.CollisionGroup = "CG_BLOCK_SELECTION"
selectionRaycast.FilterType = Enum.RaycastFilterType.Exclude
selectionRaycast.FilterDescendantsInstances = {}

local RAYCAST_MAX = 300
local MAX_SELECTION_DISTANCE = 25

ClientBlockSelector.newBlockSelected = nil

function ClientBlockSelector.getFocused()
    return focusedBlock
end

function ClientBlockSelector.getMaxSelectionDistance()
    return MAX_SELECTION_DISTANCE
end

local function isMobile(): boolean
    return PlatformDetector.getPlatform() == "MOBILE"
end

local function ensureCamera(): Camera?
    if not Camera or Camera.Parent == nil then
        Camera = workspace.CurrentCamera
    end
    return Camera
end

local function setRaycastFilterToLocalCharacter()
    local char = localPlayer.Character
    if char then
        selectionRaycast.FilterType = Enum.RaycastFilterType.Exclude
        selectionRaycast.FilterDescendantsInstances = { char }
    else
        selectionRaycast.FilterDescendantsInstances = {}
    end
end

local function  withinDistance(p: Vector3): boolean
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

local function getMouseRay(): Ray
    local cam = ensureCamera()
    if not cam then
        return Ray.new(Vector3.zero, Vector3.zAxis)
    end
    local m = UserInputService:GetMouseLocation()
    local unitRay = cam:ViewportPointToRay(m.X, m.Y)
    return Ray.new(unitRay.Origin, unitRay.Direction * RAYCAST_MAX)
end

local function getCenterScreenRay(): Ray
    local cam = ensureCamera()
    if not cam then
        return Ray.new(Vector3.zero, Vector3.zAxis)
    end
    --local inset = GuiService:GetGuiInset()
    local screenSize = Screens:getGeneralSize()
    local center = (screenSize) * 0.5
    local p = center
    local unitRay = cam:ViewportPointToRay(p.X, p.Y)
    return Ray.new(unitRay.Origin, unitRay.Direction * RAYCAST_MAX)
end

function ClientBlockSelector.getMobileSelected(tapPos: Vector2): Instance? --never used as far as i can see.
    local cam = workspace.CurrentCamera
    if not cam then
        return nil
    end
    local inset = GuiService:GetGuiInset()
    local viewportPos = tapPos + Vector2.new(inset.X, inset.Y)
    local unitRay = cam:ViewportPointToRay(viewportPos.X, viewportPos.Y)
    setRaycastFilterToLocalCharacter()
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * RAYCAST_MAX, selectionRaycast)
    if result and withinDistance(result.Position) and (result.Instance:HasTag("Block") or result.Instance:HasTag("Highlightable")) then
        print(result)
        return result.Instance
    end
    return nil
end

local function fireSelectionCallback(part: Part?)
    local cb = ClientBlockSelector.newBlockSelected
    if cb then
        cb(part)
    end
end

local function focus(part: Part)
    if PlatformDetector.getPlatform() == "PC" then
        MouseIcon.shovel()
    else
        CrossHair.shovel()
    end

    selectedBlock = part
    if highlight then
        highlight.Adornee = part
        highlight.Enabled = true
        highlight.Parent = part
    end

    fireSelectionCallback(part)
end

local function unfocus()
    if PlatformDetector.getPlatform() == "PC" then
        if ClientStateTracker.getState() == "ACTIVE" or ClientStateTracker.getState() == "TUTORIAL" then
            MouseIcon.snowball()
        else
            MouseIcon.reset()
        end
    else
        CrossHair.snowball()
    end

    if selectedBlock ~= nil then
        selectedBlock = nil
        if highlight then
            highlight.Enabled = false
            highlight.Adornee = nil
            highlight.Parent = nil
        end
        fireSelectionCallback(nil)
    else
        if highlight then
            highlight.Enabled = false
            highlight.Adornee = nil
            highlight.Parent = nil
        end
    end
end

local function step(_dt: number)
    if not enabled then
        unfocus()
        return
    end

    local cam = ensureCamera()
    if not cam then
        unfocus()
        return
    end

    setRaycastFilterToLocalCharacter()

    local ray: Ray
    if isMobile() then
        ray = getCenterScreenRay()
    else
        ray = getMouseRay()
    end

    local result = workspace:Raycast(ray.Origin, ray.Direction, selectionRaycast)

    if result and result.Instance and result.Instance:IsA("Part") and (result.Instance:HasTag("Block") or result.Instance:HasTag("Highlightable")) then
        local hitPart = result.Instance :: Part
        if withinDistance(result.Position) then
            if hitPart ~= selectedBlock then
                focus(hitPart)
            end
        else
            if selectedBlock then
                unfocus()
            end
            focusedBlock = hitPart
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
    if highlight then
        highlight.Parent = nil
        highlight.Enabled = false
    end
end

function ClientBlockSelector.onLoaded()
    Camera = workspace.CurrentCamera
    if _renderConn then
        _renderConn:Disconnect()
        _renderConn = nil
    end
    _renderConn = RunService.RenderStepped:Connect(step)
    ClientBlockSelector.enable()
end

function ClientBlockSelector.getSelected(): Part?
    return selectedBlock
end

function ClientBlockSelector.enable()
    enabled = true
end

function ClientBlockSelector.disable()
    enabled = false
    unfocus()
end

return ClientBlockSelector