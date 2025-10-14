local Timer = {}
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
Timer.__index = Timer

export type Timer = {
	Time: number,
	State: string,
	EndCallback: () -> (),
	StepCallback: (time : number) -> (),
	Connection: RBXScriptConnection?,

	Start: (self: Timer , startTime : number) -> nil,
	Pause: (self: Timer) -> nil,
	Restart: (self: Timer) -> nil,
	End: (self: Timer) -> nil,
	Destroy: (self: Timer) -> nil,
}

local function tickdown(Timer: Timer, deltaTime: number)
	Timer.Time -= deltaTime
	if Timer.StepCallback then
		Timer.StepCallback(Timer.Time)
	end
	if Timer.Time <= 0 then
		if Timer.Connection then
			Timer.Connection:Disconnect()
		end
		if Timer.EndCallback then
			Timer["EndCallback"]()	
		end
	end
end

function Timer.init() end

function Timer.new(): Timer
	local newTimer = {}
	setmetatable(newTimer, Timer)
	newTimer.Time = 0
	newTimer.State = "Idle"
	newTimer.StepCallback = nil
	newTimer.EndCallback = nil
	newTimer.Connection = nil
	return newTimer
end

function Timer:Start(StartTime: number): nil
	self.Time = StartTime
	self.State = "Running"
	if self.Connection then
		self.Connection:Disconnect()
	end
	self.Connection = RunService.Stepped:Connect(function(_ , deltaTime)
		tickdown(self, deltaTime)
	end)
end

function Timer:Restart(): nil
	if self.Connection then
		self.Connection:Disconnect()
	end
	self.Connection = RunService.Stepped:Connect(function(_ ,deltaTime)
		tickdown(self, deltaTime)
	end)
end

function Timer:Pause(): nil
	self.State = "Paused"
	if self.Connection then
		self.Connection:Disconnect()
	end
end

function Timer:End(): nil
	self:Destroy()
end

function Timer:Destroy(): nil
	if self.Connection then
		self.Connection:Disconnect()
	end
	self = nil
end

return Timer
