local ServerEventHandler = {}

local EventConnectionsCache = {}

local BindableEvent: BindableEvent = game:GetService("ServerScriptService"):WaitForChild("BindableEvent")
local BindableFunction: BindableFunction = game:GetService("ServerScriptService"):WaitForChild("BindableFunction")

function ServerEventHandler.newEventConnection(EventName, Function)
	if not EventConnectionsCache[EventName] then
		EventConnectionsCache[EventName] = {}
	end

	table.insert(EventConnectionsCache[EventName], Function)
end

function ServerEventHandler.FireEvent(EventName: string, ...)
	local Args = { ... }
	BindableEvent:Fire(EventName, Args)
end

function ServerEventHandler.init(): nil
	assert(BindableEvent, "Missing Event 'BindableEvent'")
	assert(BindableFunction, "Missing BindableFunction 'BindableFunction'")

	BindableEvent.Event:Connect(function(EventName: string, Args: { any })
		if not EventConnectionsCache[EventName] then
			warn("uncaught event " .. EventName)
			return
		end

		for _, EachFunction in EventConnectionsCache[EventName] do
			EachFunction(table.unpack(Args or {}))
		end
	end)

	BindableFunction.OnInvoke = function(EventName: string, Args: { any })
		if not EventConnectionsCache[EventName] then
			warn("uncaught event " .. EventName)
			return
		end

		for _, EachFunction in EventConnectionsCache[EventName] do
			return EachFunction(table.unpack(Args or {}))
		end
	end
end

return ServerEventHandler
