local Root = script.Parent.Parent
local ClientEventHandler = {}

local EventConnectionsCache = {}

local BindableEvent : BindableEvent = Root:WaitForChild("BindableEvent")
local BindableFunction : BindableFunction = Root:WaitForChild("BindableFunction")

function ClientEventHandler.newEventConnection(EventName, Function)
	if not EventConnectionsCache[EventName] then
		EventConnectionsCache[EventName] = {}
	end

	table.insert(EventConnectionsCache[EventName], Function)
end

function ClientEventHandler.FireEvent(EventName: string, ...)
	local Args = { ... }
	BindableEvent:Fire(EventName, Args)
end

function ClientEventHandler.init(): nil
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

    BindableFunction.OnInvoke = function(EventName : string , Args : {any})
        if not EventConnectionsCache[EventName] then
			warn("uncaught event " .. EventName)
			return
		end

		for _, EachFunction in EventConnectionsCache[EventName] do
			return EachFunction(table.unpack(Args or {}))
		end
    end
end

return ClientEventHandler
