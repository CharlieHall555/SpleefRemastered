export type Platform = "PC" | "CONSOLE" | "MOBILE" | "UNKNOWN"

local platform: Platform = "UNKNOWN"

local PlatformDetector = {}

function PlatformDetector.init()
    local UserInputService = game:GetService("UserInputService")


    if UserInputService.TouchEnabled and UserInputService.KeyboardEnabled == false then
        platform = "MOBILE"
    elseif UserInputService.GamepadEnabled == true and UserInputService.MouseEnabled == false and UserInputService.KeyboardEnabled == true then
        platform = "CONSOLE"
    elseif UserInputService.KeyboardEnabled then
        platform = "PC"
    else
        platform = "UNKNOWN"
    end
end

function PlatformDetector.getPlatform(): Platform
    return platform
end

return PlatformDetector