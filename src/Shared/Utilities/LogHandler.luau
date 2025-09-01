--!strict
-- LogHandler.lua

local LogHandler = {}

--=====================
-- Types
--=====================
export type Severity = number
export type SinkFn = (msg: string) -> ()

--=====================
-- State
--=====================
local outputSeverity: Severity = 1
local defaultSeverity: Severity = 1

local function errorWrapper(message: string)
    pcall(function()
        error(message, 2)
    end)
end

local severity_def: { [Severity]: { tag: string, f: SinkFn } } = {
	[1] = { tag = "[Info]",     f = print },
	[2] = { tag = "[Warn]",     f = warn  },
	[3] = { tag = "[Error]",    f = warn  }, -- consider errorWrapper if you want exceptions here
	[4] = { tag = "[Critical]", f = errorWrapper },
}

local onCriticalError: ((message: string, severity: Severity) -> ())? = nil

--=====================
-- Internal helpers
--=====================
local function coerceSeverity(sev: number?): Severity
	local s = sev or defaultSeverity
	-- clamp into 1..4
	if s < 1 then s = 1 end
	if s > 4 then s = 4 end
	return s :: Severity
end

local function shouldLog(severity: Severity): boolean
	-- log if severity is >= threshold
	return outputSeverity <= severity
end

local function safeCallOnCritical(message: string, severity: Severity)
	if onCriticalError then
		local ok, err = pcall(onCriticalError, message, severity)
		if not ok then
			-- avoid recursion into critical, just warn
			warn("[LogHandler] onCriticalError callback failed: " .. tostring(err))
		end
	end
end

local function formatMessage(tag: string, message: string, context: string?)
	if context and #context > 0 then
		return string.format("%s [%s] %s", tag, context, message)
	else
		return string.format("%s %s", tag, message)
	end
end

--=====================
-- API
--=====================

-- Core log
function LogHandler.log(message: string, severity: number?, context: string?): nil
	local sev = coerceSeverity(severity)
	local def = severity_def[sev]
	if not def then
		-- fallback to default severity def if table is somehow altered
		def = severity_def[defaultSeverity]
	end

	if shouldLog(sev) then
		if sev == 4 then
			safeCallOnCritical(message, sev)
		end

		local out = formatMessage(def.tag, message, context)
		def.f(out)
	end
	return nil
end

-- Sugar helpers
function LogHandler.info(message: string, context: string?): nil
	return LogHandler.log(message, 1, context)
end

function LogHandler.warn(message: string, context: string?): nil
	return LogHandler.log(message, 2, context)
end

function LogHandler.error(message: string, context: string?): nil
	return LogHandler.log(message, 3, context)
end

function LogHandler.critical(message: string, context: string?): nil
	return LogHandler.log(message, 4, context)
end

-- Configuration
function LogHandler.setOnCritical(fn: (message: string, severity: Severity) -> ()): nil
	onCriticalError = fn
	return nil
end

function LogHandler.setOutputSeverity(v: number): nil
	outputSeverity = coerceSeverity(v)
	return nil
end

-- Back-compat for the original spelling
function LogHandler.setOutPutSeverity(v: number): nil
	return LogHandler.setOutputSeverity(v)
end

function LogHandler.setDefaultSeverity(v: number): nil
	defaultSeverity = coerceSeverity(v)
	return nil
end

function LogHandler.getOutputSeverity(): Severity
	return outputSeverity
end

function LogHandler.getDefaultSeverity(): Severity
	return defaultSeverity
end

-- Optional: allow overriding sinks/tags at runtime
function LogHandler.setHandler(severity: number, tag: string?, fn: SinkFn?): nil
	local sev = coerceSeverity(severity)
	local def = severity_def[sev]
	if tag then def.tag = tag end
	if fn  then def.f   = fn  end
	return nil
end

return LogHandler
