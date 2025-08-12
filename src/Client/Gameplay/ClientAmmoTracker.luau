local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local RunService = game:GetService("RunService")

workspace:GetServerTimeNow()

export type expectedAmmoChange = "Increase" | "Decrease"

local ClientAmmoTracker = {}

local maxAmmo = 0
local predictedRegenProgress = 0
local predictedAmmo = 0

local AMMO_REGEN_INTERVAL = 0
local _heartbeatConn: RBXScriptConnection? = nil

-- callbacks
local _onAmmoChanged: ((number, number) -> ())? = nil -- (ammo, maxAmmo)
local _onRegenProgressChanged: ((number, number) -> ())? = nil -- (progressSeconds, interval)
local _onMaxAmmoChanged: ((number) -> ())? = nil -- (maxAmmo)

-- last emitted values (to avoid redundant calls)
local _lastAmmo: number = predictedAmmo
local _lastProgress: number = predictedRegenProgress
local _lastMax: number = maxAmmo

local function clamp(n: number, minv: number, maxv: number): number
	return math.max(minv, math.min(maxv, n))
end

local function emitAmmoIfChanged()
	if predictedAmmo ~= _lastAmmo then
		_lastAmmo = predictedAmmo
		if _onAmmoChanged then
			_onAmmoChanged(predictedAmmo , maxAmmo)
		end
	end
end

local function emitProgressIfChanged()
	if predictedRegenProgress ~= _lastProgress then
		_lastProgress = predictedRegenProgress
		if _onRegenProgressChanged then
			_onRegenProgressChanged(predictedRegenProgress, AMMO_REGEN_INTERVAL)
		end
	end
end

local function emitMaxIfChanged()
	if maxAmmo ~= _lastMax then
		_lastMax = maxAmmo
		if _onMaxAmmoChanged then
			_onMaxAmmoChanged(maxAmmo)
		end
	end
end

local function ensureHeartbeat()
	if _heartbeatConn then
		return
	end
	_heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		local interval = AMMO_REGEN_INTERVAL
		if interval and interval > 0 and maxAmmo > 0 and predictedAmmo < maxAmmo then
			local beforeProgress = predictedRegenProgress
			local beforeAmmo = predictedAmmo

			predictedRegenProgress += dt
			while predictedRegenProgress >= interval and predictedAmmo < maxAmmo do
				predictedRegenProgress -= interval
				predictedAmmo += 1
			end

			if predictedAmmo >= maxAmmo then
				predictedAmmo = maxAmmo
				predictedRegenProgress = 0
			else
				predictedRegenProgress = clamp(predictedRegenProgress, 0, interval)
			end

			if predictedAmmo ~= beforeAmmo then
				emitAmmoIfChanged()
			end
			if predictedRegenProgress ~= beforeProgress then
				emitProgressIfChanged()
			end
		else
			if predictedRegenProgress ~= 0 then
				predictedRegenProgress = 0
				emitProgressIfChanged()
			end
		end
	end)
end

function ClientAmmoTracker.init(): nil
	AMMO_REGEN_INTERVAL = RemoteEventHandler.InvokeOnServer("QUERY_AMMO_REGEN_INTERVAL") or 2
	emitProgressIfChanged()
	ensureHeartbeat()

	RemoteEventHandler.newEventConnection("SET_MAX_AMMO", function(newMaxAmmo)
		if typeof(newMaxAmmo) == "number" then
			local oldMax = maxAmmo
			maxAmmo = math.max(0, math.floor(newMaxAmmo))
			if maxAmmo ~= oldMax then
				-- clamp current ammo and possibly reset progress
				local oldAmmo = predictedAmmo
				predictedAmmo = clamp(predictedAmmo, 0, maxAmmo)
				if maxAmmo > 0 and predictedAmmo >= maxAmmo then
					if predictedRegenProgress ~= 0 then
						predictedRegenProgress = 0
						emitProgressIfChanged()
					end
				end
				emitMaxIfChanged()
				if predictedAmmo ~= oldAmmo then
					emitAmmoIfChanged()
				end
			end
		end
	end)

	RemoteEventHandler.newEventConnection("AMMO_CHANGED", function(newValue: number)
		if typeof(newValue) == "number" then
			local newAmmo = clamp(math.floor(newValue + 0.5), 0, maxAmmo > 0 and maxAmmo or math.huge)
			if newAmmo ~= predictedAmmo then
				predictedAmmo = newAmmo
				emitAmmoIfChanged()
			end
			if maxAmmo > 0 and predictedAmmo >= maxAmmo then
				if predictedRegenProgress ~= 0 then
					predictedRegenProgress = 0
					emitProgressIfChanged()
				end
			end
		end
	end)

	RemoteEventHandler.newEventConnection("AMMO_REGEN", function(serverTime: number, newAmmoValue: number)
		local changed = false
		if typeof(newAmmoValue) == "number" then
			local newAmmo = clamp(math.floor(newAmmoValue + 0.5), 0, maxAmmo > 0 and maxAmmo or math.huge)
			if newAmmo ~= predictedAmmo then
				predictedAmmo = newAmmo
				changed = true
				emitAmmoIfChanged()
			end
		end

		local interval = AMMO_REGEN_INTERVAL
		if typeof(serverTime) == "number" and interval and interval > 0 and predictedAmmo < maxAmmo then
			local now = workspace:GetServerTimeNow()
			local since = clamp(now - serverTime, 0, interval)
			if since ~= predictedRegenProgress then
				predictedRegenProgress = since
				emitProgressIfChanged()
			end
		else
			if predictedRegenProgress ~= 0 then
				predictedRegenProgress = 0
				emitProgressIfChanged()
			end
		end

		if changed and maxAmmo > 0 and predictedAmmo >= maxAmmo then
			if predictedRegenProgress ~= 0 then
				predictedRegenProgress = 0
				emitProgressIfChanged()
			end
		end
	end)
end

function ClientAmmoTracker.onProfileLoaded(): nil
	ensureHeartbeat()
end

function ClientAmmoTracker.predictIncrement(value: number): nil
	if typeof(value) ~= "number" or value == 0 then
		return
	end

	local beforeAmmo = predictedAmmo
	local newAmmo = predictedAmmo + value
	if maxAmmo > 0 then
		newAmmo = clamp(newAmmo, 0, maxAmmo)
	else
		newAmmo = math.max(0, newAmmo)
	end

	predictedAmmo = newAmmo
	if predictedAmmo ~= beforeAmmo then
		emitAmmoIfChanged()
	end

	if maxAmmo > 0 and predictedAmmo >= maxAmmo then
		if predictedRegenProgress ~= 0 then
			predictedRegenProgress = 0
			emitProgressIfChanged()
		end
	end
end

-- callback setters
function ClientAmmoTracker.setOnAmmoChanged(cb: ((newAmmo : number , maxAmmo : number) -> ())?): nil
	_onAmmoChanged = cb
	emitAmmoIfChanged()
end

function ClientAmmoTracker.setOnRegenProgressChanged(cb: ((progress : number, interval : number) -> ())?): nil
	_onRegenProgressChanged = cb
	emitProgressIfChanged()
end

function ClientAmmoTracker.setOnMaxAmmoChanged(cb: ((newMax : number) -> ())?): nil
	_onMaxAmmoChanged = cb
	emitMaxIfChanged()
end

function ClientAmmoTracker.getAmmo(): number
	return predictedAmmo
end

function ClientAmmoTracker.getMaxAmmo(): number
	return maxAmmo
end

function ClientAmmoTracker.getRegenProgress(): number
	return predictedRegenProgress
end

return ClientAmmoTracker