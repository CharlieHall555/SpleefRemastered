-- InputHandler.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = game.Players.LocalPlayer

export type InputAction = {
	input: InputObject,
	keyCode: Enum.KeyCode?,
	data: any?,
}

export type EndAction = {
	input: InputObject,
	keyCode: Enum.KeyCode?,
	data: any?,
	length: number,
}

local InputHandler = {}
local inputQueue: { InputAction } = {}
local endQueue: { EndAction } = {}
local startBindings: { [Enum.UserInputType]: { [string]: (InputAction) -> () } } = {}
local endBindings: { [Enum.UserInputType]: { [string]: (InputAction) -> () } } = {}

local keyBindings: { [Enum.KeyCode]: { [string]: (InputAction) -> () } } = {}

local inputStartTimes: { [InputObject]: number } = {} --[InputObject] to time


local function isAreaClear(xPos: number, yPos: number): boolean
	for Index, EachGui: GuiObject in Player.PlayerGui:GetGuiObjectsAtPosition(xPos, yPos) do
		if UserInputService.TouchEnabled then
			if EachGui.Name == "DynamicThumbstickFrame" or EachGui.Name == "JumpButton" then
				return false
			end
		end

		if EachGui.BackgroundTransparency ~= 1 and EachGui.Visible then
			return false
		end
	end

	return true
end

local function processInputs()
	while #inputQueue > 0 do
		local action = table.remove(inputQueue, 1)
		if action.input.UserInputType == Enum.UserInputType.Keyboard then
			local handlers = action.keyCode and keyBindings[action.keyCode]
			if handlers then
				for _, cb in pairs(handlers) do
					cb(action)
				end
			end
		else
			local handlers = startBindings[action.input.UserInputType]
			if handlers then
				for _, cb in pairs(handlers) do
					cb(action)
				end
			end
		end
	end
	while #endQueue > 0 do
		local action : EndAction = table.remove(endQueue, 1)
        local handlers = endBindings[action.input.UserInputType]
        if handlers then
            for _, cb in pairs(handlers) do cb(action) end
        end
	end
end


function InputHandler.queueInput(input: InputObject, data: any?)
	inputStartTimes[input] = time()
	table.insert(inputQueue, {
		input = input,
		keyCode = input.KeyCode,
		data = data,
	})
end

function InputHandler.queueEnd(input: EndAction, data: any?)
	local endTime = time()
	local length = endTime - (inputStartTimes[input] or endTime)
	inputStartTimes[input] = nil
	table.insert(endQueue, {
		input = input,
		keyCode = input.KeyCode,
		data = data,
		length = length,
	})
end

function InputHandler.bindActionStart(actionType: Enum.UserInputType, callback: (InputAction) -> ())
	local uid = HttpService:GenerateGUID(false)
	startBindings[actionType] = startBindings[actionType] or {}
	startBindings[actionType][uid] = callback
	return uid
end

function InputHandler.bindActionEnd(actionType: Enum.UserInputType, callback: (InputAction) -> ())
	local uid = HttpService:GenerateGUID(false)
	endBindings[actionType] = endBindings[actionType] or {}
	endBindings[actionType][uid] = callback
	return uid
end

function InputHandler.isInputDown(input: InputObject) : boolean
	if inputStartTimes[input] then
		return true
	else
		return false
	end
end

function InputHandler.bindKey(keyCode: Enum.KeyCode, callback: (InputAction) -> ()) 
	local uid = HttpService:GenerateGUID(false)
	keyBindings[keyCode] = keyBindings[keyCode] or {}
	keyBindings[keyCode][uid] = callback
	return uid
end

function InputHandler.unbind(uid: string)
	-- remove from actionBindings
	for actionType, handlers in pairs(startBindings) do
		if handlers[uid] then
			handlers[uid] = nil
			if next(handlers) == nil then
				startBindings[actionType] = nil
			end
			return
		end
	end
	-- remove from keyBindings
	for keyCode, handlers in pairs(keyBindings) do
		if handlers[uid] then
			handlers[uid] = nil
			if next(handlers) == nil then
				keyBindings[keyCode] = nil
			end
			return
		end
	end

	for actionType, handlers in pairs(endBindings) do
		if handlers[uid] then
			handlers[uid] = nil
			if next(handlers) == nil then
				endBindings[actionType] = nil
			end
			return
		end
	end
end


function InputHandler.init()
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed)
		if gameProcessed then
			return
		end
		local data = {}
		if input.UserInputType == Enum.UserInputType.Touch then
			data.isClearOfUI = isAreaClear(input.Position.X, input.Position.Y)
		end
		InputHandler.queueInput(input, data)
	end)

	UserInputService.InputEnded:Connect(function(input: EndAction, gameProcessed)
		if gameProcessed then
			return
		end
		local data = {}
		if input.UserInputType == Enum.UserInputType.Touch then
			data.isClearOfUI = isAreaClear(input.Position.X, input.Position.Y)
		end
		InputHandler.queueEnd(input, data)
	end)

	RunService.RenderStepped:Connect(processInputs)
end

return InputHandler
