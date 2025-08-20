export type Ghost = {
    mode: "MOVE" | "FIXED",
    part: BasePart,
    aP: AlignPosition,
    aO: AlignOrientation,
    hoverOffset : CFrame,
    gui: BillboardGui,
    teleportTo: (self: Ghost, cframe: CFrame) -> nil,
    moveTo: (self: Ghost, cframe: CFrame , applyOffset : boolean) -> nil,
    Destroy: (self: Ghost) -> nil
}

local GhostModule = {}
GhostModule.__index = GhostModule

local TELEPORT_THRESHOLD = 50
local ghostTemplate: Model? = nil
local ghostFolder

type GhostMode = "MOVE" | "FIXED"

local function randomRange(min: number, max: number): number
    return min + (max - min) * math.random()
end

local function getTemplate(): Model
    if ghostTemplate and ghostTemplate.Parent ~= nil then
        return ghostTemplate
    end
    local resources = game:GetService("ReplicatedStorage"):WaitForChild("Resources", 4)
    ghostTemplate = resources:WaitForChild("GhostTemplate", 4) :: Model
    return ghostTemplate
end

function GhostModule.init(): nil
    ghostFolder = Instance.new("Folder")
    ghostFolder.Parent = workspace
    ghostFolder.Name = "Ghosts"
    getTemplate()
end

function GhostModule.new(playerName: string): Ghost
    local template = getTemplate()
    local part = template:Clone()
    part.Name = "Ghost_" .. playerName
    part.Parent = ghostFolder


    local aP = part:FindFirstChildOfClass("AlignPosition") :: AlignPosition?
    local aO = part:FindFirstChildOfClass("AlignOrientation") :: AlignOrientation?
    assert(aP and aO, "GhostTemplate missing AlignPosition or AlignOrientation")

    local gui = part:FindFirstChildOfClass("BillboardGui") :: BillboardGui?
    assert(gui, "GhostTemplate missing BillboardGui")

    local label = gui:FindFirstChildWhichIsA("TextLabel") :: TextLabel?
    if label then
        label.Text = playerName
    end

    local self = setmetatable({}, GhostModule)
    self.mode = "MOVE"
    self.part = part
    self.hoverOffset = CFrame.new(
        randomRange(-4, 4),
        0,
        randomRange(-4, 4)
    )
    self.aP = aP
    self.aO = aO
    self.gui = gui

    return self
end

function GhostModule:teleportTo(cframe: CFrame)
    self.part.CFrame = cframe
    self.aP.Position = cframe.Position
    self.aO.CFrame = cframe
end

function GhostModule:moveTo(cframe: CFrame , applyOffset : boolean)
    applyOffset = applyOffset or false
    local currentPos = self.part.Position
    local targetPos = cframe.Position
    if applyOffset then
        targetPos += self.hoverOffset.Position
    end

    if (currentPos - targetPos).Magnitude > TELEPORT_THRESHOLD then
        self:teleportTo(cframe)
    else
        self.aP.Position = targetPos
        self.aO.CFrame = cframe
    end
end

function GhostModule:Destroy()
    if self.part and self.part.Parent then
        local model = self.part:FindFirstAncestorOfClass("Model")
        if model then
            model:Destroy()
        else
            self.part:Destroy()
        end
    end

    self.mode = "MOVE"
    self.part = nil :: any
    self.aP = nil :: any
    self.aO = nil :: any
    self.gui = nil :: any
end

return GhostModule




