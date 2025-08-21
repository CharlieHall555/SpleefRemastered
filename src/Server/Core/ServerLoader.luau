local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local EventHandler = require(ModuleDirectory.ServerEventHandler)

local ServerLoader = {}
local loaded = {}

-- Phase 1: require everything (recursively) and call init() once per module.
local function requireAll(tbl)
	for ModuleName, EachModulePath in pairs(tbl) do
		if type(EachModulePath) == "table" then
			requireAll(EachModulePath)
		else
			print(ModuleName, EachModulePath)
			local ok, result = pcall(require, EachModulePath)
			if not ok then
				error(("Module: %s failed to load, Reason: %s"):format(ModuleName, result))
			end

			if result ~= nil then
				if loaded[ModuleName] then
					warn(("Duplicate module name '%s' – overwriting previous entry."):format(ModuleName))
				end

				loaded[ModuleName] = result
				print("Required " .. ModuleName)

				local init_fun = result.init
				if type(init_fun) == "function" then
					init_fun()
				else
					warn(ModuleName .. " missing .init() method.")
				end
			end
		end
	end
end

function ServerLoader.init()
	-- Phase 1: require & init
	requireAll(ModuleDirectory)

	-- Phase 2: call onLoaded() exactly once per module (no recursion here)
	for ModuleName, EachModule in pairs(loaded) do
		local onLoaded = EachModule.onLoaded
		if type(onLoaded) == "function" then
			onLoaded()
		else
			warn(ModuleName .. " missing .onLoaded() method.")
		end
	end

	-- Optional final pass: onLoad() if you really need a third phase
	for ModuleName, EachModule in pairs(loaded) do
		local onLoad = EachModule.onLoad
		if type(onLoad) == "function" then
			onLoad()
		end
	end

	EventHandler.FireEvent("Server Loaded")
	print("[SERVER] all modules loaded.")
end

return ServerLoader