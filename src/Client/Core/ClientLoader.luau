local Root = script.Parent.Parent
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

local EventHandler = require(ClientModuleDirectory.ClientEventHandler)

local ClientLoader = {}
local loaded = {}

local function loadTable(tableToLoad : {}) : nil
	
	for ModuleName, EachModulePath in tableToLoad do
		print(ModuleName , EachModulePath)
		local success, result = pcall(function()
			if type(EachModulePath) == "table" then
				loadTable(EachModulePath)
				return nil
			end
			return require(EachModulePath)
		end)

		if success == false then
			error("Module: " ..ModuleName .. " failed to load, Reason : " ..result)
			return
		end

		if result == nil then continue end 
		
		local EachModule = result
		loaded[ModuleName] = EachModule

        print(EachModule)
		local init_fun = EachModule["init"]
		if init_fun then
			init_fun()
		else
			warn(ModuleName .. " Missing .init() method.")
		end
	end
	
	
	for ModuleName , EachModule in loaded do
		
		local loaded_fun = EachModule["onLoaded"]
		if loaded_fun then
			loaded_fun()
		else
			warn(ModuleName .. " Missing .onLoaded() method.")
		end
	
	end
end

function ClientLoader.init()

	loadTable(ClientModuleDirectory)

	EventHandler.FireEvent("ClientLoaded")
	print("[CLIENT] all modules loaded.")
end

function ClientLoader.profileLoaded()

	for ModuleName , EachModule in loaded do
		
		local loaded_fun = EachModule["onProfileLoaded"]
		if loaded_fun then
			loaded_fun()
		end
	
	end

end

return ClientLoader
