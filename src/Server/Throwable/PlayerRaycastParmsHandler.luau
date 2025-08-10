local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local PlayerRaycastParamsHandler = {}

local BlockFolder = nil

type TargetConns = {
    added: RBXScriptConnection?,
    removing: RBXScriptConnection?
}

type OwnerState = {
    rp: RaycastParams,
    ignores: { Instance },
    ownerConns: { added: RBXScriptConnection?, removing: RBXScriptConnection? },
    targets: { [number]: TargetConns }
}

local _stateByUserId: { [number]: OwnerState } = {}

local function _rebuildFilter(state: OwnerState)
    state.rp.FilterDescendantsInstances = state.ignores
end

local function _ensureState(owner: Player): OwnerState
    local uid = owner.UserId
    local state = _stateByUserId[uid]
    if state then
        return state
    end

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.IgnoreWater = true
    --rp.CollisionGroup = "CG_THROW_RAYCAST"

    state = {
        rp = rp,
        ignores = {BlockFolder},
        ownerConns = { added = nil, removing = nil },
        targets = {}
    }
    _stateByUserId[uid] = state

    state.ownerConns.added = owner.CharacterAdded:Connect(function(char)
        table.insert(state.ignores, char)
        _rebuildFilter(state)
    end)

    state.ownerConns.removing = owner.CharacterRemoving:Connect(function(char)
        for i = #state.ignores, 1, -1 do
            if state.ignores[i] == char then
                table.remove(state.ignores, i)
            end
        end
        _rebuildFilter(state)
    end)

    if owner.Character then
        table.insert(state.ignores, owner.Character)
        _rebuildFilter(state)
    end

    return state
end

local function _disconnectTarget(state: OwnerState, targetUserId: number)
    local t = state.targets[targetUserId]
    if not t then
        return
    end
    if t.added then
        t.added:Disconnect()
    end
    if t.removing then
        t.removing:Disconnect()
    end
    state.targets[targetUserId] = nil
end

local function _removeInstanceFromIgnores(state: OwnerState, inst: Instance)
    for i = #state.ignores, 1, -1 do
        if state.ignores[i] == inst then
            table.remove(state.ignores, i)
        end
    end
end

local function _cleanupOwner(owner: Player)
    local uid = owner.UserId
    local state = _stateByUserId[uid]
    if not state then
        return
    end

    for _, conns in pairs(state.targets) do
        if conns.added then
            conns.added:Disconnect()
        end
        if conns.removing then
            conns.removing:Disconnect()
        end
    end
    state.targets = {}

    if state.ownerConns.added then
        state.ownerConns.added:Disconnect()
    end
    if state.ownerConns.removing then
        state.ownerConns.removing:Disconnect()
    end

    _stateByUserId[uid] = nil
end

function PlayerRaycastParamsHandler.onLoaded()
    BlockFolder = workspace:WaitForChild("Blocks", 4)
    assert(BlockFolder, "BlockFolder missing, Should be present under workspace.")

    RemoteEventHandler.newEventConnection("PLAYER_LOADED", function(player: Player)
        _ensureState(player)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        -- if this player is an owner, clean their state
        _cleanupOwner(player)

        -- if this player is a tracked target, remove their character from all owners' ignores
        for _, state in pairs(_stateByUserId) do
            _disconnectTarget(state, player.UserId)
            if player.Character then
                _removeInstanceFromIgnores(state, player.Character)
                _rebuildFilter(state)
            end
        end
    end)
end

function PlayerRaycastParamsHandler.get(owner: Player): RaycastParams
    local state = _ensureState(owner)
    return state.rp
end

function PlayerRaycastParamsHandler.excludePlayers(owner: Player, players: { Player }): nil
    local state = _ensureState(owner)

    for _, target in ipairs(players) do
        -- reset existing tracking for this target
        _disconnectTarget(state, target.UserId)

        local conns: TargetConns = { added = nil, removing = nil }
        state.targets[target.UserId] = conns

        conns.added = target.CharacterAdded:Connect(function(char)
            table.insert(state.ignores, char)
            _rebuildFilter(state)
        end)

        conns.removing = target.CharacterRemoving:Connect(function(char)
            _removeInstanceFromIgnores(state, char)
            _rebuildFilter(state)
        end)

        if target.Character then
            table.insert(state.ignores, target.Character)
            _rebuildFilter(state)
        end
    end
end

function PlayerRaycastParamsHandler.reset(owner: Player): nil
    _cleanupOwner(owner)
end

return PlayerRaycastParamsHandler
