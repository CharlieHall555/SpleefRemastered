-- VibrationService.lua
-- Simple wrapper around HapticService for consistent haptic feedback

local HapticService = game:GetService("HapticService")

local VibrationService = {}

local COOLDOWN = 2
local lastVibration = 0

-- internal: trigger haptic motor with intensity and duration
local function vibrate(intensity: number, duration: number)
    local now = os.clock()
    if now - lastVibration < COOLDOWN then
        return
    end
    lastVibration = now

    -- For controllers
    local inputType = Enum.UserInputType.Gamepad1
    if HapticService:IsVibrationSupported(inputType) then
        HapticService:SetMotor(inputType, Enum.VibrationMotor.Large, intensity)
        task.delay(duration, function()
            HapticService:SetMotor(inputType, Enum.VibrationMotor.Large, 0)
        end)
    end

    -- For mobile
    if HapticService:IsVibrationSupported(Enum.UserInputType.Touch) then
        if intensity < 0.4 then
            HapticService:Vibrate(Enum.VibrationType.Light)
        elseif intensity < 0.7 then
            HapticService:Vibrate(Enum.VibrationType.Medium)
        else
            HapticService:Vibrate(Enum.VibrationType.Heavy)
        end
    end
end

function VibrationService.light()
    vibrate(0.2, 0.1)
end

function VibrationService.medium()
    vibrate(0.6, 0.2)
end

function VibrationService.heavy()
    vibrate(1, 0.25)
end

return VibrationService
    