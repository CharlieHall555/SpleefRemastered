local LavaPart: Part? -- has texture bellow

local ClientLavaManager = {}

function ClientLavaManager.onLoaded()
    LavaPart = game.Workspace:WaitForChild("Lava", 6)
	assert(LavaPart, "Lava missing")
end

function ClientLavaManager.disable()
    
end

function ClientLavaManager.enable()
    
end

return ClientLavaManager