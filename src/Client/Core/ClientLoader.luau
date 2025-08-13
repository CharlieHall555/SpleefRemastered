local Root = script.Parent.Parent
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local EventHandler = require(ClientModuleDirectory.ClientEventHandler)

local ClientLoader = {}
local loaded: { [string]: any } = {}

local function loadTable(tbl: { [any]: any }): nil
    for moduleName, entry in tbl do
        local success, result = pcall(function()
            if type(entry) == "table" then
                loadTable(entry)
                return nil
            end
            return require(entry)
        end)

        if not success then
            error("Module: " .. tostring(moduleName) .. " failed to load, Reason: " .. tostring(result))
        end

        if result ~= nil then
            loaded[tostring(moduleName)] = result
            local initFn = result.init
            if type(initFn) == "function" then
                initFn()
            else
                warn(tostring(moduleName) .. " missing .init() method.")
            end
        end
    end
end

local function runOnLoadedOnce(): nil
    for moduleName, moduleTbl in loaded do
        local onLoadedFn = moduleTbl.onLoaded
        if type(onLoadedFn) == "function" then
            onLoadedFn()
        else
            warn(tostring(moduleName) .. " missing .onLoaded() method.")
        end
    end
end

function ClientLoader.init()
    loadTable(ClientModuleDirectory)
    runOnLoadedOnce()
    EventHandler.FireEvent("ClientLoaded")
    print("[CLIENT] all modules loaded.")
end

function ClientLoader.profileLoaded()
    for _, moduleTbl in loaded do
        local fn = moduleTbl.onProfileLoaded
        if type(fn) == "function" then
            fn()
        end
    end
end

return ClientLoader