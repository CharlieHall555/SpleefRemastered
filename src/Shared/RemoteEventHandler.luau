--[[

-- Remote Event Handler --
Author : c2h2 | Charlie Hall.

This is a script to replace having multiple events stored everywhere (leading to a cleaner explorer)
instead this relies on setting up connections to a string of an event name to a function.

This script has no method to invoke on client as this is bad practice and can lead to exploits.

]]

-- set up --

local RemoteEventHandler = {}

local EventConnectionsCache = {}
local MissedEventCache = {}

local MissedEventCacheParams = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

SynchronousBridge = game:GetService("ReplicatedStorage"):WaitForChild("Synchronous")
ASynchronousBridge = game:GetService("ReplicatedStorage"):WaitForChild("Asynchronous")

function RemoteEventHandler.removeConnection(EventName, Function)
	if EventConnectionsCache[EventName] then
		table.remove(EventConnectionsCache[EventName], table.find(EventConnectionsCache[EventName], Function))
	else
		error("Failed to remove connection: " .. EventName .. ". Connection by EventName not found")
	end
end

function RemoteEventHandler.newEventConnection(EventName : string, Function : (player : Player , any? ) -> any?)
	if EventConnectionsCache[EventName] then
		error("Failed to create connection: " .. EventName .. ". Connection for event name already exsists.")
	end

	EventConnectionsCache[EventName] = Function

	if table.find(MissedEventCache, EventName) then
		Function(table.unpack(MissedEventCacheParams[EventName]))

		table.remove(MissedEventCache, table.find(MissedEventCache, EventName))
		MissedEventCacheParams[EventName] = nil
	end
end

-- Fire Event Functions --

function RemoteEventHandler.FireOnClient(Player: Player, EventName: string, ...): nil
	if not IsServer then
		error("Failed to fire: " .. EventName .. ". Cannot call FireOnAllClient on client.")
	end

	local Args = { ... }

	ASynchronousBridge:FireClient(Player, EventName, Args)
end

function RemoteEventHandler.FireOnClients(List: { Player }, EventName, ...): nil
	for Index, EachPlayer in List do
		RemoteEventHandler.FireOnClient(EachPlayer, EventName, ...)
	end
end

function RemoteEventHandler.FireOnAllClients(EventName: string, ...): nil
	if not IsServer then
		error("Failed to fire: " .. EventName .. ". Cannot call FireOnAllClients on client.")
	end

	local Args = { ... }

	for Index, Player in Players:GetChildren() do
		ASynchronousBridge:FireClient(Player, EventName, Args)
	end
end

function RemoteEventHandler.FireOnServer(EventName: string, ...): nil
	if IsServer then
		error("Failed to fire: " .. EventName .. ". Cannot call FireOnServer on server.")
	end

	local Args = { ... }
	ASynchronousBridge:FireServer(EventName, Args)
end

function RemoteEventHandler.InvokeOnServer(EventName: string, ...)
	if IsServer then
		error("Failed to invoke: " .. EventName .. ". Cannot call InvokeOnServer on server.")
	end

	local Args = { ... }
	return SynchronousBridge:InvokeServer(EventName, Args)
end

-- Event Listening --
function RemoteEventHandler.init(): nil
	assert(ASynchronousBridge, "Missing remote event 'Asynchronous'")
	assert(SynchronousBridge, "Missing function event 'Synchronous'")
	if IsServer then
		ASynchronousBridge.OnServerEvent:Connect(function(Player, EventName, Args)
			local EventFunction = EventConnectionsCache[EventName]
			assert(EventFunction, "Event connection by name not set up for " .. EventName .. ".")

			EventFunction(Player, table.unpack(Args or {}))
		end)

		SynchronousBridge.OnServerInvoke = function(Player, EventName, Args)
			local EventFunction = EventConnectionsCache[EventName]
			assert(EventFunction, "Synchronous connection by name not set up.")

			return EventFunction(Player, table.unpack(Args or {}))
		end
	else
		ASynchronousBridge.OnClientEvent:Connect(function(EventName, Args)
			local EventFunction = EventConnectionsCache[EventName]

			if not EventFunction then
				warn("No event function set up for " .. EventName)

				table.insert(MissedEventCache, EventName)
				MissedEventCacheParams[EventName] = Args

				return
			end

			EventFunction(table.unpack(Args or {}))
		end)
	end
end

return RemoteEventHandler
