local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local TextChatService = game:GetService("TextChatService")
local RBXSystem : TextChannel?
local LogHandler = require(ClientModuleDirectory.LogHandler)


local SystemMessage = {}

local SystemPrefix = "[SYSTEM]"

-- Converts Color3 -> hex string for rich text
local function _colorToHex(color: Color3): string
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

-- Escapes special XML characters so rich text doesn’t break
local function _escapeRichText(text: string): string
	return text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
end

function SystemMessage.send(text: string, color: Color3?, bold: boolean?)
	assert(type(text) == "string" and text ~= "", "SystemMessage.chat requires a non-empty string")

	local formatted = _escapeRichText(text)

    formatted = SystemPrefix .. " " .. formatted

	if bold then
		formatted = string.format("<b>%s</b>", formatted)
	end

	if color then
		formatted = string.format('<font color="%s">%s</font>', _colorToHex(color), formatted)
	end

	RBXSystem:DisplaySystemMessage(formatted)
end

function SystemMessage.init() --#region

    local channels = TextChatService:WaitForChild("TextChannels" , 4)
    if channels == nil then
        LogHandler.error("TextChatService missing TextChannels folder.")
        return
    end
    RBXSystem = channels:WaitForChild("RBXSystem")
    if RBXSystem == nil then
        LogHandler.error("TextChannels folder missing RBXSystem.")
        return
    end
   
	RemoteEventHandler.newEventConnection("RECEIVE_SYSTEM_MESSAGE", SystemMessage.send)

end

return SystemMessage
