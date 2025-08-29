local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SynchronousBridge: RemoteFunction = ReplicatedStorage:WaitForChild("Synchronous")
local ASynchronousBridge: RemoteEvent = ReplicatedStorage:WaitForChild("Asynchronous")
-- Note: variable name kept as provided for compatibility (typo included).
local UnrelaibleASynchronousBridge: RemoteEvent = ReplicatedStorage:WaitForChild("UnreliableAsynchronous")

local IsServer = RunService:IsServer()

type ConnectionMap = { [string]: (player: Player, ...any) -> any? }
local EventConnectionsCache: { [string]: ConnectionMap } = {}
local MissedEventCache: { [string]: { any } } = {}

local RemoteEventHandler = {}

function RemoteEventHandler.newEventConnection(eventName: string, callback: (player: Player, ...any) -> any?): string
	if not EventConnectionsCache[eventName] then
		EventConnectionsCache[eventName] = {}
	end
	local uid = HttpService:GenerateGUID(false)
	EventConnectionsCache[eventName][uid] = callback

	if MissedEventCache[eventName] then
		for _, args in ipairs(MissedEventCache[eventName]) do
			callback(table.unpack(args))
		end
		MissedEventCache[eventName] = nil
	end

	return uid
end

function RemoteEventHandler.removeConnection(eventName: string, uid: string): nil
	local connections = EventConnectionsCache[eventName]
	if connections and connections[uid] then
		connections[uid] = nil
		if next(connections) == nil then
			EventConnectionsCache[eventName] = nil
		end
	else
		error("Failed to remove connection: " .. eventName .. ". UID not found")
	end
end

-- =========================
-- Reliable fire helpers
-- =========================
function RemoteEventHandler.FireOnClient(player: Player, eventName: string, ...): nil
	if not IsServer then
		error("Failed to fire: " .. eventName .. ". Cannot call FireOnClient on client.")
	end
	local args = { ... }
	ASynchronousBridge:FireClient(player, eventName, args)
end

function RemoteEventHandler.FireOnClients(list: { Player }, eventName: string, ...): nil
	for _, eachPlayer in ipairs(list) do
		RemoteEventHandler.FireOnClient(eachPlayer, eventName, ...)
	end
end

function RemoteEventHandler.FireOnAllClients(eventName: string, ...): nil
	if not IsServer then
		error("Failed to fire: " .. eventName .. ". Cannot call FireOnAllClients on client.")
	end
	local args = { ... }
	for _, player in ipairs(Players:GetPlayers()) do
		ASynchronousBridge:FireClient(player, eventName, args)
	end
end

function RemoteEventHandler.FireOnServer(eventName: string, ...): nil
	if IsServer then
		error("Failed to fire: " .. eventName .. ". Cannot call FireOnServer on server.")
	end
	local args = { ... }
	ASynchronousBridge:FireServer(eventName, args)
end

-- =========================
-- Unreliable fire helpers
-- =========================
function RemoteEventHandler.FireUnreliableOnClient(player: Player, eventName: string, ...): nil
	if not IsServer then
		error("Failed to fire (unreliable): " .. eventName .. ". Cannot call FireUnreliableOnClient on client.")
	end
	local args = { ... }
	UnrelaibleASynchronousBridge:FireClient(player, eventName, args)
end

function RemoteEventHandler.FireUnreliableOnClients(list: { Player }, eventName: string, ...): nil
	for _, eachPlayer in ipairs(list) do
		RemoteEventHandler.FireUnreliableOnClient(eachPlayer, eventName, ...)
	end
end

function RemoteEventHandler.FireUnreliableOnAllClients(eventName: string, ...): nil
	if not IsServer then
		error("Failed to fire (unreliable): " .. eventName .. ". Cannot call FireUnreliableOnAllClients on client.")
	end
	local args = { ... }
	for _, player in ipairs(Players:GetPlayers()) do
		UnrelaibleASynchronousBridge:FireClient(player, eventName, args)
	end
end

function RemoteEventHandler.FireUnreliableOnServer(eventName: string, ...): nil
	if IsServer then
		error("Failed to fire (unreliable): " .. eventName .. ". Cannot call FireUnreliableOnServer on server.")
	end
	local args = { ... }
	UnrelaibleASynchronousBridge:FireServer(eventName, args)
end

-- =========================
-- Synchronous (Invoke) API
-- =========================
function RemoteEventHandler.InvokeOnServer(eventName: string, timeout: number?, ...): ...any
	if IsServer then
		error("Failed to invoke: " .. eventName .. ". Cannot call InvokeOnServer on server.")
	end

	timeout = timeout or 5 -- default 5s
	local args = { ... }
	local remoteFunction = SynchronousBridge

	local result
	local done = false

	task.spawn(function()
		local success, response = pcall(function()
			return remoteFunction:InvokeServer(eventName, args)
		end)
		if success then
			result = response
		end
		done = true
	end)

	local start = os.clock()
	while not done and os.clock() - start < timeout do
		task.wait()
	end

	if not done then
		return nil
	end

	return result
end

-- =========================
-- Init and shared dispatch
-- =========================
local function dispatchToConnections_Server(player: Player, eventName: string, argsArray: { any }?)
	local connections = EventConnectionsCache[eventName]
	if connections == nil then
		warn("Event connection by name not set up for " .. tostring(eventName))
		return
	end
	for _, fn in pairs(connections) do
		local ok, err = pcall(function()
			fn(player, table.unpack(argsArray or {}))
		end)
		if not ok then
			warn("Caught Error with " .. tostring(eventName) .. " : " .. tostring(err))
		end
	end
end

local function dispatchToConnections_Client(eventName: string, argsArray: { any }?)
	local connections = EventConnectionsCache[eventName]
	if not connections then
		warn("No event function set up for " .. tostring(eventName))
		if not MissedEventCache[eventName] then
			MissedEventCache[eventName] = {}
		end
		table.insert(MissedEventCache[eventName], argsArray)
		return
	end
	for _, fn in pairs(connections) do
		local ok, err = pcall(function()
			-- client-side callbacks do not have a Player param
			fn(table.unpack(argsArray or {}))
		end)
		if not ok then
			warn("Caught Error with " .. tostring(eventName) .. " : " .. tostring(err))
		end
	end
end

function RemoteEventHandler.init(): nil
	assert(ASynchronousBridge, "Missing remote event 'Asynchronous'")
	assert(SynchronousBridge, "Missing function event 'Synchronous'")
	assert(UnrelaibleASynchronousBridge, "Missing remote event 'UnreliableAsynchronous'")

	if IsServer then
		-- Reliable path
		ASynchronousBridge.OnServerEvent:Connect(function(player, eventName, args)
			dispatchToConnections_Server(player, eventName, args)
		end)
		-- Unreliable path (same dispatch table)
		UnrelaibleASynchronousBridge.OnServerEvent:Connect(function(player, eventName, args)
			dispatchToConnections_Server(player, eventName, args)
		end)

		SynchronousBridge.OnServerInvoke = function(player, eventName, args)
			local connections = EventConnectionsCache[eventName]
			assert(connections, "Synchronous connection by name not set up for " .. (tostring(eventName) or "NIL"))
			local results = {}
			for _, fn in pairs(connections) do
				local ok, err = pcall(function()
					table.insert(results, fn(player, table.unpack(args or {})))
				end)
				if not ok then
					warn("Caught Error with " .. tostring(eventName) .. " : " .. tostring(err))
					return
				end
			end
			return table.unpack(results)
		end
	else
		-- Reliable path
		ASynchronousBridge.OnClientEvent:Connect(function(eventName, args)
			dispatchToConnections_Client(eventName, args)
		end)
		-- Unreliable path (same dispatch table)
		UnrelaibleASynchronousBridge.OnClientEvent:Connect(function(eventName, args)
			dispatchToConnections_Client(eventName, args)
		end)
	end
end

return RemoteEventHandler
