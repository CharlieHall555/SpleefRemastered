local ClientThrowableTracker = {}

export type Throwable = {
	uid: string,
	startPosition: Vector3,
	initialVelocity: Vector3,
	type: string,
	launchTime: number,
	displayTime: number,
	targetTime: number,
	part: Part,
}

local RunService = game:GetService("RunService")
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local PartPool = require(ClientModuleDirectory.PartPool)
local SnowballPool = require(ClientModuleDirectory.SnowballPool)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ThrowableData = require(ClientModuleDirectory.ThrowableData)
local VectorUtil = require(ClientModuleDirectory.VectorUtil)
local ThrowableDefinitions = require(ClientModuleDirectory.ThrowableDefinitions)
local localPlayer = game.Players.LocalPlayer

local rayParams = RaycastParams.new()

local function computePosition(startPos: Vector3, vel: Vector3, gravity: Vector3, t: number, result: Vector3?)
	-- result param allows reuse of an existing Vector3 if you want to go all-in on zero-allocation
	local pos = startPos + vel * t + 0.5 * gravity * t * t
	if result then
		-- If reusing, set components instead of creating a new Vector3
		result = Vector3.new(pos.X, pos.Y, pos.Z)
		return result
	end
	return pos
end

local gravityTable: { [string]: Vector3 } = {}
local throwables: { [string]: Throwable } = {}
local typeHitFunctions: { [string]: (Throwable, RaycastResult) -> () } = {}

local newTable: { [string]: () -> Part } = {}

function newTable.snowball()
	local newThrowable = SnowballPool.take()
	return newThrowable
end

local _nextId = 0
local function generateUID(): string
	_nextId += 1
	return "c_" .. tostring(_nextId)
end

-- How far behind the actual position we start the visual interpolation (in seconds)
local INTERPOLATION_OFFSET = 0.2

function ClientThrowableTracker.init()
	for eachType, def in ThrowableDefinitions do
		gravityTable[eachType] = Vector3.new(0, -def.gravity, 0)
	end
	RunService.RenderStepped:Connect(ClientThrowableTracker.mainLoop)
	RemoteEventHandler.newEventConnection("NEW_THROWABLE", ClientThrowableTracker.receiveFromServer)

	RemoteEventHandler.newEventConnection("DELETE_THROWABLE", ClientThrowableTracker.removeThrowable)

	ClientThrowableTracker.pollPing()

end

function ClientThrowableTracker.onLoaded()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	rayParams.CollisionGroup = "CG_GAMEPLAY"
	rayParams.FilterDescendantsInstances = { localPlayer.Character }

	localPlayer.CharacterAdded:Connect(function(new_character)
		rayParams.FilterDescendantsInstances = { new_character }
	end)
end

local function average(table)
  	local sum = 0
	for _, v in ipairs(table) do
		sum += v
	end
	return sum / (#table)
end

function ClientThrowableTracker.pollPing()
    task.spawn(function()
        local pingSamples = {}
        local sampleSize = 5

        while localPlayer and localPlayer.Parent do 
            local success, err = pcall(function()
                local ping = math.max(0, localPlayer:GetNetworkPing())
                ping = math.min(ping, 0.5) -- cap max ping to 0.5 seconds

                -- store sample
                table.insert(pingSamples, ping)
                if #pingSamples > sampleSize then
                    table.remove(pingSamples, 1)
                end

				if RunService:IsStudio() then
					INTERPOLATION_OFFSET = 0.08 -- remove in production
				else
                	INTERPOLATION_OFFSET = average(pingSamples) / 2
				end
            end)

            if not success then
                warn("[ClientThrowableTracker.pollPing] Error:", err)
            end

            task.wait(0.5)
        end
    end)
end

function ClientThrowableTracker.receiveFromServer(data: ThrowableData.ThrowableData)
	local startPosition = VectorUtil.DeserializeVector3(data.sP)
	local velocity = VectorUtil.DeserializeVector3(data.v)
	local typeName = data.t
	local launchTime = data.s
	local uid = data.uid
	ClientThrowableTracker.newThrowable(startPosition, velocity, typeName, launchTime , uid)
end

function ClientThrowableTracker.mainLoop(dt: number)
	local now = workspace:GetServerTimeNow()
	for uid, throwable in pairs(throwables) do
		-- Update targetTime each frame so interpolation continues
		throwable.targetTime = now

		-- Interpolate displayTime toward the true server time
		local oldDisplay = throwable.displayTime
		local newDisplay = math.min(throwable.targetTime, oldDisplay + dt)
		throwable.displayTime = newDisplay

		local gravity = gravityTable[throwable.type]
		-- compute positions at old and new display times
		local dtPrev = oldDisplay - throwable.launchTime
		local dtNow = newDisplay - throwable.launchTime

		local prevPos = computePosition(throwable.startPosition, throwable.initialVelocity, gravity, dtPrev)
		local newPos = computePosition(throwable.startPosition, throwable.initialVelocity, gravity, dtNow)
		local direction = newPos - prevPos
		local result = workspace:Raycast(prevPos, direction, rayParams)

		if newPos.Y < -100 then
			ClientThrowableTracker.removeThrowable(uid)
		elseif result then
			local hitFunc = typeHitFunctions[throwable.type]
            if hitFunc then
                hitFunc(throwable, result)
            end
			ClientThrowableTracker.removeThrowable(uid)
		else
			throwable.part.Position = newPos
		end
	end
end

function ClientThrowableTracker.newThrowable(
	startPosition: Vector3,
	initialVelocity: Vector3,
	typeName: string,
	launchTime: number,
	given_uid : number?
): string
	local g = newTable[typeName]
	local part
	if g then
		part = g()
	end

	if not part then
		part = Instance.new("Part")
		warn("Had to generate new part")
	end

	local def = ThrowableDefinitions[typeName]
	part.Size = def.size
	part.Color = def.color
	part.Material = def.material
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0
	part.Parent = workspace

	-- Determine display start time (slightly behind actual)
	local now = workspace:GetServerTimeNow()
	local displayTime = math.max(launchTime, now - INTERPOLATION_OFFSET)
	local targetTime = now

	-- compute and set initial visual position
	local gravity = gravityTable[typeName]
	local dtDisplay = displayTime - launchTime
	local currentPos = startPosition + initialVelocity * dtDisplay + 0.5 * gravity * dtDisplay * dtDisplay
	part.Position = currentPos

	-- store throwable state
	local uid = given_uid or generateUID()
	throwables[uid] = {
		uid = uid,
		startPosition = startPosition,
		initialVelocity = initialVelocity,
		type = typeName,
		launchTime = launchTime,
		displayTime = displayTime,
		targetTime = targetTime,
		part = part,
	}

	return uid
end

function ClientThrowableTracker.removeThrowable(uid: string)
	local t = throwables[uid]
	if not t then
		return
	end
	PartPool.add(t.part)
	t.part.Transparency = 1
	throwables[uid] = nil
end

function ClientThrowableTracker.registerOnHit(typeName: string, func: (Throwable, RaycastResult) -> ())
	typeHitFunctions[typeName] = func
end

return ClientThrowableTracker
