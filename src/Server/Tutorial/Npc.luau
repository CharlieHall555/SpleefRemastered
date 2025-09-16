export type DummyState = {
    uid: number,
    owner: Player,
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    spawnPoint: Vector3,
    conns: { RBXScriptConnection }
}

export type Dummy = {
    init: (self: Dummy) -> (),
    generateNPC: (self: Dummy, spawnPoint: Vector3, player: Player) -> number,
    destroy: (self: Dummy, uid: number) -> ()
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local DummyTemplate: Model = ServerStorage:WaitForChild("NPCTemplate") :: Model

local Dummy: Dummy = {}

local nextUid = 1
local states: { [number]: DummyState } = {}

local function createModelAt(spawnPoint: Vector3): (Model, Humanoid, BasePart)
    local model = DummyTemplate:Clone()
    model.Name = "NPC_Dummy"

    local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
    local root = (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")) :: BasePart

    if not humanoid or not root then
        model:Destroy()
        error("NPCTemplate is missing Humanoid or HumanoidRootPart")
    end

    local randomOffset = Vector3.new(
        math.random(-5 , 5),
        0,
        math.random(-5 , 5)
    )

    model:PivotTo(CFrame.new(spawnPoint + randomOffset))

    -- Keep the dummy stationary
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    humanoid.AutoRotate = false
    model.Parent = Workspace
    humanoid.Health = humanoid.MaxHealth

    return model, humanoid, root
end

local function bindDeath(state: DummyState)
    -- Clear prior connections
    for _, c in ipairs(state.conns) do
        if c.Connected then
            c:Disconnect()
        end
    end
    state.conns = {}

    local conn = state.humanoid.Died:Connect(function()
        RemoteEventHandler.FireOnClient(state.owner, "DUMMY_DIED")

        -- Replace the dead model with a fresh one at the spawn point
        task.defer(function()
            if states[state.uid] ~= state then
                return
            end

            if state.model and state.model.Parent then
                state.model:Destroy()
            end

            local newModel, newHumanoid, newRoot = createModelAt(state.spawnPoint)
            state.model = newModel
            state.humanoid = newHumanoid
            state.root = newRoot

            bindDeath(state)
        end)
    end)

    table.insert(state.conns, conn)
end

function Dummy.init() end

function Dummy.generateNPC(spawnPoint: Vector3, player: Player): number
    local uid = nextUid
    nextUid += 1

    local model, humanoid, root = createModelAt(spawnPoint)

    local state: DummyState = {
        uid = uid,
        owner = player,
        model = model,
        humanoid = humanoid,
        root = root,
        spawnPoint = spawnPoint,
        conns = {}
    }

    states[uid] = state
    bindDeath(state)

    return uid
end

function Dummy.destroy(uid: number)
    local state = states[uid]
    if not state then
        return
    end

    for _, c in ipairs(state.conns) do
        if c.Connected then
            c:Disconnect()
        end
    end
    state.conns = {}

    if state.model and state.model.Parent then
        state.model:Destroy()
    end

    states[uid] = nil
end

return Dummy
