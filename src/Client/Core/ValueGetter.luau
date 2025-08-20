local EventHandler = require(game:GetService("ReplicatedStorage").EventHandler)
local ClientEventHandler = require(game:GetService("ReplicatedFirst").ClientEventHandler)
local HTTPService = game:GetService("HttpService")

local ValueGetter = {}

local ValueTable = {}

local BindTable = {}
local BindFunctions = {}

function ValueGetter.init(): nil
	EventHandler.newEventConnection("UpdateValue", ValueGetter.setValue)

	ClientEventHandler.newEventConnection("ClientLoaded", function()
		local SharedJson, ValuesJson = EventHandler.InvokeOnServer("GetStartingValues" , 3)
		local SharedValues = HTTPService:JSONDecode(SharedJson)

		ValueTable = HTTPService:JSONDecode(ValuesJson)

		for EachKey, Value in SharedValues do
			ValueTable[EachKey] = Value
		end

		ClientEventHandler.FireEvent("InitialValuesLoaded")
	end)
end

function ValueGetter.getValue(ValueName: string): string?
	if ValueTable[ValueName] then
		return ValueTable[ValueName]
	end
end

function ValueGetter.refreshValue(ValueName: string): nil
	local CurrentValue = ValueTable[ValueName]
	local RefreshValue = EventHandler.InvokeOnServer("RefreshValue" , 3)

	if CurrentValue ~= RefreshValue then
		ValueGetter.setValue(ValueName, RefreshValue)
	end

	return ValueGetter.getValue(ValueName)
end

function ValueGetter.setValue(ValueName: string, Value: any): nil
	ValueTable[ValueName] = Value
	if BindTable[ValueName] then
		for _, EachElement in BindTable[ValueName] do
			EachElement.Text = Value
		end
	end
	if BindFunctions[ValueName] then
		for _, EachFunction in BindFunctions[ValueName] do
			EachFunction(Value)
		end
	end
end

function ValueGetter.BindValueToLabel(ValueName: string, BindName: string, BindTarget: TextLabel | TextBox | TextButton)
	if ValueTable[ValueName] then
		BindTarget.Text = ValueTable[ValueName]
	end

	if not BindTable[ValueName] then
		BindTable[ValueName] = {}
	end

	BindTable[ValueName][BindName] = BindTarget
end

function ValueGetter.unBindValueFromLabel(ValueName: string, BindName: string): nil
	if BindTable[ValueName] then
		BindTable[ValueName][BindName] = nil
	end
end

function ValueGetter.unBindValueFromFunction(ValueName: string, BindName: string): nil
	if BindFunctions[ValueName] then
		BindFunctions[ValueName][BindName] = nil
	end
end

function ValueGetter.BindValueToFunction(ValueName: string, BindName: string, Function: any): nil
	if ValueTable[ValueName] then
		Function(ValueTable[ValueName])
	end

	if not BindFunctions[ValueName] then
		BindFunctions[ValueName] = {}
	end

	BindFunctions[ValueName][BindName] = Function
end

return ValueGetter
