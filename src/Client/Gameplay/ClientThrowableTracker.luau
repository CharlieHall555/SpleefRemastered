local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PartPool = require(ClientModuleDirectory.PartPool)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ThrowableData = require(ClientModuleDirectory.ThrowableData)
local VectorUtil = require(ClientModuleDirectory.VectorUtil)
local ThrowableDefinitions = require(ClientModuleDirectory.ThrowableDefinitions)

-- useful methods PartPool.add(part : Part), PartPool.take() -> Part

local ClientThrowableTracker = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = true

local GRAVITY = Vector3.new(0, -15, 0)

export type Throwable = {
	uid: string,
	position: Vector3,
	direction: Vector3,
    type : string,
	velocity: Vector3,
	part: Part,
}

local _nextId = 0
local function generateUID(): string
	_nextId += 1
	return "t_" .. tostring(_nextId)
end

local gravityTable : {[string] : Vector3} = {}

local throwables: { [string]: Throwable } = {}

function ClientThrowableTracker.init()

    for eachType , eachTable in ThrowableDefinitions do
		gravityTable[eachType] = Vector3.new(0 , -eachTable.gravity , 0)
	end

	RunService.RenderStepped:Connect(ClientThrowableTracker.mainLoop)
	RemoteEventHandler.newEventConnection("NEW_THROWABLE", ClientThrowableTracker.receiveFromServer)
end

function ClientThrowableTracker.receiveFromServer(throwableData: ThrowableData.ThrowableData)
	local startPosition = VectorUtil.DeserializeVector3(throwableData.sP)
	local direction = VectorUtil.DeserializeVector3(throwableData.d)
    local _type = throwableData.t
	local timeNow = workspace:GetServerTimeNow()
	local elapsedTime = timeNow - throwableData.s

	local speed = 80
	local initialVelocity = direction.Unit * speed

	local simulatedVelocity = initialVelocity
	local simulatedPosition = startPosition

	local timeStep = 1 / 60
	while elapsedTime > 0 do
		local step = math.min(elapsedTime, timeStep)
		simulatedVelocity += gravityTable[throwableData.t] * step
		simulatedPosition += simulatedVelocity * step
		elapsedTime -= step
	end

	ClientThrowableTracker.newThrowable(simulatedPosition, direction , _type)
end

function ClientThrowableTracker.onLoaded()
	rayParams.FilterDescendantsInstances = { workspace:WaitForChild("Blocks") }
end

function ClientThrowableTracker.mainLoop(deltaTime: number): nil
	for uid, throwable in pairs(throwables) do
		local part = throwable.part

		local oldPosition = throwable.position
		local newVelocity = throwable.velocity + GRAVITY * deltaTime
		local newPosition = oldPosition + newVelocity * deltaTime

		local result = workspace:Raycast(oldPosition, newPosition - oldPosition, rayParams)

		if result or oldPosition.Y < -100 then
			PartPool.add(part)
			part.Transparency = 1
			throwables[uid] = nil
		else
			throwable.velocity = newVelocity
			throwable.position = newPosition
			part.Position = newPosition
		end
	end
end

function ClientThrowableTracker.newThrowable(startPosition: Vector3, direction: Vector3 , _type : string): string
	local part = PartPool.take()
	if not part then
		part = Instance.new("Part")
		warn("Had to generate new part")
	end

	part.Size = ThrowableDefinitions[_type].size
	part.Position = startPosition
	part.Velocity = Vector3.zero
	part.Color = ThrowableDefinitions[_type].color
    part.Material = ThrowableDefinitions[_type].material
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball
	part.Transparency = 0
	part.Parent = workspace

	local speed = 80
	local velocity = direction.Unit * speed
	local uid = generateUID()

	throwables[uid] = {
		uid = uid,
		position = startPosition,
		direction = direction,
		velocity = velocity,
        type = _type,
		part = part,
	}

	return uid
end

function ClientThrowableTracker.removeThrowable(uid: string)
	local throwable = throwables[uid]
	if not throwable then
		return
	end

	PartPool.add(throwable.part)
	throwable.part.Transparency = 1
	throwables[uid] = nil
end

return ClientThrowableTracker
