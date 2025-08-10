local TweenService = game:GetService("TweenService")

type TweenRecord = {
    spinTween: Tween?,
    bobTween: Tween?,
    angle: NumberValue?,
    playing: boolean
}

local ClientSnowballAnimator = {}

local _FOLDER_NAME = "SnowballPickups"
local _container: Folder? = nil
local _tweensByPart: { [BasePart]: TweenRecord } = {}
local _folderAddedConn: RBXScriptConnection? = nil
local _childAddedConn: RBXScriptConnection? = nil
local _childRemovedConn: RBXScriptConnection? = nil
local _enabled = true

local function _stopForPart(part: BasePart)
    local rec = _tweensByPart[part]
    if not rec then
        return
    end

    if rec.spinTween then
        rec.spinTween:Cancel()
        rec.spinTween:Destroy()
        rec.spinTween = nil
    end
    if rec.bobTween then
        rec.bobTween:Cancel()
        rec.bobTween:Destroy()
        rec.bobTween = nil
    end
    if rec.angle then
        rec.angle:Destroy()
        rec.angle = nil
    end

    rec.playing = false
end

local function _isPlaying(part: BasePart): boolean
    local rec = _tweensByPart[part]
    if not rec then
        return false
    end
    if rec.playing then
        return true
    end
    if rec.spinTween and rec.spinTween.PlaybackState == Enum.PlaybackState.Playing then
        return true
    end
    if rec.bobTween and rec.bobTween.PlaybackState == Enum.PlaybackState.Playing then
        return true
    end
    return false
end

local function _animatePart(part: BasePart)
    if not _enabled then
        return
    end
    if _isPlaying(part) then
        return
    end

    if not _tweensByPart[part] then
        _tweensByPart[part] = {
            spinTween = nil,
            bobTween = nil,
            angle = nil,
            playing = false
        }
    end

    local baseOri = part.Orientation
    local angle = Instance.new("NumberValue")
    angle.Value = 0

    local spinInfo = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge, false, 0)
    local spinTween = TweenService:Create(angle, spinInfo, { Value = 360 })

    local angleConn: RBXScriptConnection
    angleConn = angle:GetPropertyChangedSignal("Value"):Connect(function()
        if not part.Parent then
            if angleConn then
                angleConn:Disconnect()
            end
            return
        end
        part.Orientation = Vector3.new(baseOri.X, baseOri.Y + angle.Value, baseOri.Z)
    end)

    spinTween:Play()

    local startPos = part.Position
    local bobGoal = { Position = Vector3.new(startPos.X, startPos.Y + 0.4, startPos.Z) }
    local bobInfo = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, math.huge, true, 0)
    local bobTween = TweenService:Create(part, bobInfo, bobGoal)
    bobTween:Play()

    _tweensByPart[part].spinTween = spinTween
    _tweensByPart[part].bobTween = bobTween
    _tweensByPart[part].angle = angle
    _tweensByPart[part].playing = true

    local ancestryConn
    ancestryConn = part.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            _stopForPart(part)
            _tweensByPart[part] = nil
            if ancestryConn then
                ancestryConn:Disconnect()
            end
        end
    end)
end

local function _handleChildAdded(child: Instance)
    if not _enabled then
        return
    end
    if child:IsA("BasePart") then
        _animatePart(child)
    elseif child:IsA("Model") then
        for _, desc in ipairs(child:GetDescendants()) do
            if desc:IsA("BasePart") then
                _animatePart(desc)
            end
        end
        child.DescendantAdded:Connect(function(desc)
            if not _enabled then
                return
            end
            if desc:IsA("BasePart") then
                _animatePart(desc)
            end
        end)
        child.DescendantRemoving:Connect(function(desc)
            if desc:IsA("BasePart") then
                _stopForPart(desc)
                _tweensByPart[desc] = nil
            end
        end)
    end
end

local function _handleChildRemoved(child: Instance)
    if child:IsA("BasePart") then
        _stopForPart(child)
        _tweensByPart[child] = nil
    elseif child:IsA("Model") then
        for _, desc in ipairs(child:GetDescendants()) do
            if desc:IsA("BasePart") then
                _stopForPart(desc)
                _tweensByPart[desc] = nil
            end
        end
    end
end

local function _connectFolder(folder: Folder)
    if _childAddedConn then
        _childAddedConn:Disconnect()
    end
    if _childRemovedConn then
        _childRemovedConn:Disconnect()
    end

    _childAddedConn = folder.ChildAdded:Connect(_handleChildAdded)
    _childRemovedConn = folder.ChildRemoved:Connect(_handleChildRemoved)

    for _, child in ipairs(folder:GetChildren()) do
        if _enabled then
            _handleChildAdded(child)
        end
    end
end

local function _ensureContainer()
    if _container and _container.Parent then
        return
    end

    local found = workspace:FindFirstChild(_FOLDER_NAME)
    if found and found:IsA("Folder") then
        _container = found
        _connectFolder(_container)
        return
    end

    if _folderAddedConn then
        _folderAddedConn:Disconnect()
        _folderAddedConn = nil
    end

    _folderAddedConn = workspace.ChildAdded:Connect(function(inst)
        if inst.Name == _FOLDER_NAME and inst:IsA("Folder") then
            _container = inst
            _connectFolder(_container)
        end
    end)
end

function ClientSnowballAnimator.init()
    _ensureContainer()
end

function ClientSnowballAnimator.stopAll()
    for part, _ in pairs(_tweensByPart) do
        _stopForPart(part)
    end
end

function ClientSnowballAnimator.restart()
    if not _enabled then
        return
    end
    if not _container or not _container.Parent then
        _ensureContainer()
    end
    if not _container then
        return
    end

    for _, child in ipairs(_container:GetDescendants()) do
        if child:IsA("BasePart") then
            if not _isPlaying(child) then
                _animatePart(child)
            end
        end
    end
end

function ClientSnowballAnimator.isEnabled(): boolean
    return _enabled
end

function ClientSnowballAnimator.toggle(enabled: boolean?)
    if enabled == nil then
        _enabled = not _enabled
    else
        _enabled = enabled
    end
    print(_enabled)

    if _enabled == false then
        ClientSnowballAnimator.stopAll()
    else
        ClientSnowballAnimator.restart()
    end
end

return ClientSnowballAnimator
