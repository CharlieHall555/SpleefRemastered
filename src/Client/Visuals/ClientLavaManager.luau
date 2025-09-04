local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local TweenService = game:GetService("TweenService")

local ClientLavaManager = {}

-- config
local LAVA_TWEEN_INFO = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, false, 0)
local LAVA_OFFSET_TARGET = -6

-- state
local enabled = false
local workspaceAddedConn: RBXScriptConnection? = nil

-- per-background tracking
type Tracked = {
    model: Model,
    lava: BasePart?,
    texture: Texture?,
    tween: Tween?,
    conns: { RBXScriptConnection }
}

local trackedByModel: { [Model]: Tracked } = {}

local function stopTweenFor(tr: Tracked)
    if tr.tween then
        tr.tween:Pause()
        tr.tween:Destroy()
        tr.tween = nil
    end
end

local function cleanupTracked(model: Model)
    local tr = trackedByModel[model]
    if not tr then
        return
    end
    for _, c in ipairs(tr.conns) do
        c:Disconnect()
    end
    tr.conns = {}
    stopTweenFor(tr)
    trackedByModel[model] = nil
end

local function tryPlayTween(tr: Tracked)
    if not enabled then
        return
    end
    if not tr.model or not tr.model.Parent then
        return
    end
    local lava = tr.lava
    if not lava or not lava.Parent then
        return
    end
    local texture = tr.texture
    if not texture or not texture.Parent then
        return
    end

    stopTweenFor(tr)
    texture.OffsetStudsU = 0
    tr.tween = TweenService:Create(texture, LAVA_TWEEN_INFO, { OffsetStudsU = LAVA_OFFSET_TARGET })
    tr.tween:Play()
end

local function bindLavaReferences(tr: Tracked)
    -- attempt to find lava and texture right now
    local lava = tr.model:FindFirstChild("Lava")
    if lava and lava:IsA("BasePart") then
        tr.lava = lava
        tr.texture = lava:FindFirstChildOfClass("Texture")
    end

    -- if not present yet, watch for descendants being added
    local addedConn = tr.model.DescendantAdded:Connect(function(desc)
        if not tr.model.Parent then
            return
        end
        if not tr.lava and desc:IsA("BasePart") and desc.Name == "Lava" then
            tr.lava = desc
            tr.texture = desc:FindFirstChildOfClass("Texture")
            tryPlayTween(tr)
        elseif tr.lava and not tr.texture and desc:IsA("Texture") and desc.Parent == tr.lava then
            tr.texture = desc
            tryPlayTween(tr)
        end
    end)

    -- handle removal/cleanup when model or lava/texture go away
    local destroyingConn = tr.model.Destroying:Connect(function()
        cleanupTracked(tr.model)
    end)

    local lavaDestroyConn: RBXScriptConnection? = nil
    local function bindLavaDestroy()
        if tr.lava and not lavaDestroyConn then
            lavaDestroyConn = tr.lava.Destroying:Connect(function()
                stopTweenFor(tr)
                tr.lava = nil
                tr.texture = nil
            end)
        end
    end
    bindLavaDestroy()

    local ancestryConn = tr.model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanupTracked(tr.model)
        end
    end)

    tr.conns = { addedConn, destroyingConn, ancestryConn }
    if lavaDestroyConn then
        table.insert(tr.conns, lavaDestroyConn)
    end
end

local function trackBackgroundModel(model: Model)
    if trackedByModel[model] then
        return
    end
    local tr: Tracked = {
        model = model,
        lava = nil,
        texture = nil,
        tween = nil,
        conns = {}
    }
    trackedByModel[model] = tr
    bindLavaReferences(tr)
    tryPlayTween(tr)
end

local function scanExistingBackgrounds()
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "background" then
            trackBackgroundModel(child)
        end
    end
end

local function bindWorkspaceAdded()
    if workspaceAddedConn then
        workspaceAddedConn:Disconnect()
        workspaceAddedConn = nil
    end
    workspaceAddedConn = workspace.ChildAdded:Connect(function(inst)
        if not inst:IsA("Model") then
            return
        end
        if inst.Name == "background" then
            trackBackgroundModel(inst)
        end
    end)
end

function ClientLavaManager.onLoaded()
    ClientStateTracker.connectActive(function()
        task.spawn(function()
            ClientLavaManager.enable()
        end)
    end)
end

function ClientLavaManager.enable()
    if enabled then
        return
    end
    enabled = true
    bindWorkspaceAdded()
    scanExistingBackgrounds()
    -- resume tweens for tracked models
    for _, tr in pairs(trackedByModel) do
        tryPlayTween(tr)
    end
end

function ClientLavaManager.disable()
    if not enabled then
        return
    end
    enabled = false
    if workspaceAddedConn then
        workspaceAddedConn:Disconnect()
        workspaceAddedConn = nil
    end
    for model, tr in pairs(trackedByModel) do
        stopTweenFor(tr)
        cleanupTracked(model)
    end
end

function ClientLavaManager.getEnabled()
    return enabled
end

return ClientLavaManager
