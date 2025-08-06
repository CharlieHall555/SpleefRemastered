-- ServerScriptService/ModuleDirectory/ThrowableManager.lua
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local Throwable = require(ModuleDirectory.Throwable)
local VectorUtil = require(ModuleDirectory.VectorUtil)
local ThrowableDefinitions = require(ModuleDirectory.ThrowableDefinitions)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)
local ThrowableManager = {}

-- internal state
local loadedThrowables = {}
local _nextId = 0

-- physics constants
local gravityTable : {[string] : Vector3} = {}

local rayParams = RaycastParams.new()

local function generateUID() : string
	_nextId += 1
	return "s_" .. tostring(_nextId)
end

function ThrowableManager.init() : nil

	for eachType , eachTable in ThrowableDefinitions do
		gravityTable[eachType] = Vector3.new(0 , -eachTable.gravity , 0)
	end

	RunService.Heartbeat:Connect(ThrowableManager.mainLoop)
end

function ThrowableManager.onLoaded() : nil
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = { workspace:WaitForChild("Blocks") }
    rayParams.IgnoreWater = true   
end

function ThrowableManager.mainLoop(dt : number)
	for uid, th : Throwable.Throwable in pairs(loadedThrowables) do
		
		local oldPos = th.position
		local newVel = th.velocity + gravityTable[th.type] * dt
		local newPos = oldPos + newVel * dt

		local hit = workspace:Raycast(oldPos, newPos - oldPos, rayParams)
		if hit or oldPos.Y < -100 then
			ThrowableManager.onHit(th)
			ThrowableManager.removeThrowable(uid)
		else
			th.velocity = newVel
			th.position = newPos
		end
	end
end

local function updateClients(newThrowable : Throwable.Throwable)
	local dataToSend = {
		sP = VectorUtil.SerializeVector3(newThrowable.position), -- in here the position is nil?
		v = VectorUtil.SerializeVector3(newThrowable.velocity),
		t = newThrowable.type,
		s = workspace:GetServerTimeNow(),
		uid = newThrowable.uid
	}
    RemoteEventHandler.FireOnAllClients("NEW_THROWABLE" , dataToSend)
	
end

-- spawn a new server-tracked throwable
-- clients will receive the event and generate their own Part
-- returns the uid string
function ThrowableManager.newThrowable(position: Vector3, direction: Vector3 , _type : string) : string
	assert(typeof(position) == "Vector3", "ThrowableManager.newThrowable: 'position' must be a Vector3")
	assert(typeof(direction) == "Vector3", "ThrowableManager.newThrowable: 'direction' must be a Vector3")
	assert(typeof(_type) == "string" and _type ~= "", "ThrowableManager.newThrowable: '_type' must be a non-empty string")

	local uid = generateUID()

	local speed = 80
	local velocity = direction.Unit * speed

	local new = {
		uid = uid,
		direction = direction,
		position = position,
		velocity = velocity,
		type = _type
	}
	loadedThrowables[uid] = new

	-- notify clients to spawn a local part
	updateClients(new)
	return uid
end

function ThrowableManager.onHit(throwable : Throwable.Throwable)
	print("hit")
end


-- optional server-side manual cleanup
function ThrowableManager.removeThrowable(uid: string)
	if loadedThrowables[uid] then
		loadedThrowables[uid] = nil
	end
end

return ThrowableManager
