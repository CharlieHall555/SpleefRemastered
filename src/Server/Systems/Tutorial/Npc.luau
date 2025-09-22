export type DummyState = {
    uid: number,
    owner: Player,
    model: Model,
    humanoid: Humanoid,
    root: BasePart,
    spawnPoint: Vector3,
    conns: { RBXScriptConnection }
}

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local DummyTemplate: Model = ServerStorage:WaitForChild("NPCTemplate") :: Model

local Dummy = {}

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
        math.random(-25 , 25),
        0,
        math.random(-25 , 25)
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

local function clearConns(state: DummyState)
    for _, c in ipairs(state.conns) do
        if c and c.Connected then
            c:Disconnect()
        end
    end
    state.conns = {}
end

local function bindStateConnections(state: DummyState)
    -- Clear existing connections first
    clearConns(state)

    -- Death connection
    local deathConn = state.humanoid.Died:Connect(function()
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

            -- Re-bind connections for the new model
            bindStateConnections(state)
        end)
    end)
    table.insert(state.conns, deathConn)

    -- Touched connection on the root part to detect "TestLava" tag
    if state.root and state.root:IsA("BasePart") then
        local touchConn = state.root.Touched:Connect(function(otherPart)
            if not otherPart or not otherPart:IsA("BasePart") then
                return
            end

            -- If the touched part has the "TestLava" tag, kill the humanoid
            if CollectionService:HasTag(otherPart, "TestLava") then
                -- Guard: humanoid may already be dead or destroyed
                if state.humanoid and state.humanoid.Health > 0 then
                    state.humanoid.Health = 0
                end
            end
        end)
        table.insert(state.conns, touchConn)
    end
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
    bindStateConnections(state)

    return uid
end

function Dummy.destroy(uid: number)
    local state = states[uid]
    if not state then
        return
    end

    clearConns(state)

    if state.model and state.model.Parent then
        state.model:Destroy()
    end

    states[uid] = nil
end

return Dummy
