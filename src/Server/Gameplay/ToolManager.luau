local ToolManager = {}

local _shovelTemplate: Tool? = nil
local _handedOutTools: {Tool} = {}

function ToolManager.onLoaded()
    local serverStorage = game:GetService("ServerStorage")
    local shovelsFolder = serverStorage:WaitForChild("Shovels")
    _shovelTemplate = shovelsFolder:WaitForChild("Shovel" , 4) :: Tool
    assert(_shovelTemplate, "BasicShovel template missing in ServerStorage/Shovels")
end

function ToolManager.giveTools(players: {Player}): nil
    assert(_shovelTemplate, "ToolManager not loaded. Call onLoaded() first.")
    for _, player in ipairs(players) do
        if player and player.Parent then
            local backpack = player:FindFirstChildOfClass("Backpack")
            if backpack and not backpack:FindFirstChild(_shovelTemplate.Name) then
                local tool = _shovelTemplate:Clone()
                tool.Parent = backpack
                table.insert(_handedOutTools, tool)
            end
        end
    end
end

function ToolManager.reset(): nil
    for i = #_handedOutTools, 1, -1 do
        local tool = _handedOutTools[i]
        if tool and tool.Parent then
            tool:Destroy()
        end
        _handedOutTools[i] = nil
    end
end

return ToolManager