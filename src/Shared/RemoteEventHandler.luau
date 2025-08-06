export type RemoteEventHandler = {
	removeConnection: (eventName: string, uid: string) -> nil,
	newEventConnection: (eventName: string, callback: (player: Player, ...any) -> any?) -> string,
	FireOnClient: (player: Player, eventName: string, ...any) -> nil,
	FireOnClients: (list: { Player }, eventName: string, ...any) -> nil,
	FireOnAllClients: (eventName: string, ...any) -> nil,
	FireOnServer: (eventName: string, ...any) -> nil,
	InvokeOnServer: (eventName: string, ...any) -> ...any,
	init: () -> nil,
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SynchronousBridge = ReplicatedStorage:WaitForChild("Synchronous")
local ASynchronousBridge = ReplicatedStorage:WaitForChild("Asynchronous")
local IsServer = RunService:IsServer()

local EventConnectionsCache: { [string]: { [string]: (player: Player, ...any) -> any? } } = {}
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

function RemoteEventHandler.InvokeOnServer(eventName: string, ...): ...any
	if IsServer then
		error("Failed to invoke: " .. eventName .. ". Cannot call InvokeOnServer on server.")
	end
	local args = { ... }
	return SynchronousBridge:InvokeServer(eventName, args)
end

function RemoteEventHandler.init(): nil
	assert(ASynchronousBridge, "Missing remote event 'Asynchronous'")
	assert(SynchronousBridge, "Missing function event 'Synchronous'")
	if IsServer then
		ASynchronousBridge.OnServerEvent:Connect(function(player, eventName, args)
			local connections = EventConnectionsCache[eventName]
			assert(connections, "Event connection by name not set up for " .. eventName)
			for _, fn in pairs(connections) do
				fn(player, table.unpack(args or {}))
			end
		end)

		SynchronousBridge.OnServerInvoke = function(player, eventName, args)
			local connections = EventConnectionsCache[eventName]
			assert(connections, "Synchronous connection by name not set up for " .. eventName)
			local results = {}
			for _, fn in pairs(connections) do
				table.insert(results, fn(player, table.unpack(args or {})))
			end
			return table.unpack(results)
		end
	else
		ASynchronousBridge.OnClientEvent:Connect(function(eventName, args)
			local connections = EventConnectionsCache[eventName]
			if not connections then
				warn("No event function set up for " .. eventName)
				if not MissedEventCache[eventName] then
					MissedEventCache[eventName] = {}
				end
				table.insert(MissedEventCache[eventName], args)
				return
			end
			for _, fn in pairs(connections) do
				fn(table.unpack(args or {}))
			end
		end)
	end
end

return RemoteEventHandler
