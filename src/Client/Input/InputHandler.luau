-- InputHandler.lua
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

export type InputAction = {
    input: InputObject,
    keyCode: Enum.KeyCode?,
    data: any?,
    context : string
}

local InputHandler = {}
local inputQueue: { InputAction } = {}
local currentContext: string = "GAME"
local actionBindings: { [Enum.UserInputType]: { [string]: (InputAction) -> () } } = {}
local keyBindings: { [Enum.KeyCode]: { [string]: (InputAction) -> () } } = {}

function InputHandler.setContext(newContext: string)
    currentContext = newContext
end

function InputHandler.queueInput(input: InputObject, data: any?)
    local code: Enum.KeyCode? = nil
    if input.UserInputType == Enum.UserInputType.Keyboard then
        print("keycode")
        code = input.KeyCode
    end
    table.insert(inputQueue, {
        input = input,
        keyCode = code,
        data = data,
        context = currentContext
    })
end

function InputHandler.bindAction(actionType: Enum.UserInputType, callback: (InputAction) -> ())
    local uid = HttpService:GenerateGUID(false)
    actionBindings[actionType] = actionBindings[actionType] or {}
    actionBindings[actionType][uid] = callback
    return uid
end

function InputHandler.bindKey(keyCode: Enum.KeyCode, callback: (InputAction) -> ())
    local uid = HttpService:GenerateGUID(false)
    keyBindings[keyCode] = keyBindings[keyCode] or {}
    keyBindings[keyCode][uid] = callback
    return uid
end

function InputHandler.unbind(uid: string)
    -- remove from actionBindings
    for actionType, handlers in pairs(actionBindings) do
        if handlers[uid] then
            handlers[uid] = nil
            if next(handlers) == nil then
                actionBindings[actionType] = nil
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
end

function InputHandler.processInputs()
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
            local handlers = actionBindings[action.input.UserInputType]
            if handlers then
                for _, cb in pairs(handlers) do
                    cb(action)
                end
            end
        end
    end
end

function InputHandler.init()
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed)
        if gameProcessed then return end
        InputHandler.queueInput(input)
    end)
    RunService.RenderStepped:Connect(InputHandler.processInputs)
end

return InputHandler