local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)

local AgentsInGame = {}
AgentsInGame.__index = AgentsInGame

-- Internal list of agents currently in the game
local activeAgents: { any } = {}

-- Optional callback invoked when the activeAgents list changes
local onChange: ((agents: { any }) -> ())? = nil

-- Returns the current list (caller should not mutate it directly)
function AgentsInGame.getActiveAgents(): { any }
    return activeAgents
end

function AgentsInGame.isActive(agent: any): boolean
    for _, a in ipairs(activeAgents) do
        if a == agent then
            return true
        end
    end
    return false
end

function AgentsInGame.addAgent(agent: any, fireOnChangeCallback: boolean?): nil
    -- Prevent duplicates
    for _, a in ipairs(activeAgents) do
        if a == agent then
            return
        end
    end
    table.insert(activeAgents, agent)
    if onChange and fireOnChangeCallback then
        onChange(activeAgents)
    end
end

function AgentsInGame.removeAgent(agent: any): nil
    for i, a in ipairs(activeAgents) do
        if a == agent then
            table.remove(activeAgents, i)
            if onChange then
                onChange(activeAgents)
            end
            break
        end
    end
end

function AgentsInGame.setOnChange(fn: (agents: { any }) -> ()): nil
    onChange = fn
end

function AgentsInGame.getSize(): number
    return #activeAgents
end

function AgentsInGame.clear(): nil
    activeAgents = {}
    if onChange then
        onChange(activeAgents)
    end
end

function AgentsInGame.init()
    -- Agent-specific initialization can be added here
end

return AgentsInGame
