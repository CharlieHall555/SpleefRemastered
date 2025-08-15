--//====================================================
--// Type Defs (if needed)
--//====================================================

local LogHandler = {}
--//====================================================
--// Imports / Services
--//====================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)

--//====================================================
--// Local Variables / Constants
--//====================================================

local output_severity = 1
local default_severity = 1

local errorWrapper = function(message : string)
    error(message , 2)
end

local severity_def = {
	[1] = { tag = "[Info]", f = print },
	[2] = { tag = "[Warn]", f = warn },
	[3] = { tag = "[Error]", f = warn },
	[4] = { tag = "[Critical]", f = errorWrapper },
}

local onCriticalError: (() -> ())? = nil

--//====================================================
--// Exposed Function
--//====================================================
function LogHandler.log(message: string, severity: number?): nil 
    severity = severity or default_severity
    if output_severity <= severity then
        
        local f = severity_def[severity].f
        local tag = severity_def[severity].tag
        if severity == 4 and onCriticalError then
            onCriticalError()
        end
        if f and tag then
            f(tag .. " " .. message)
        end
    end
end

function LogHandler.setOnCritical(fn: () -> ()): nil
	onCriticalError = fn
end

function LogHandler.setOutPutSeverity(v : number): nil
	output_severity = v
end

return LogHandler
