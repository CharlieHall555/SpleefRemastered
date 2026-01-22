local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local SoundPlayer = require(ClientModuleDirectory.Sound.SoundPlayer)
local TextChatService = game:GetService("TextChatService")
local HitboxManager = require(ClientModuleDirectory.HitBoxManager)
local TapDebugView = require(ClientModuleDirectory.TapDebugView)
local SpectateController = require(ClientModuleDirectory.Spectate.Controller)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local SessionVariables = require(ClientModuleDirectory.Variables.SessionVariables)
local SystemMessage = require(ClientModuleDirectory.Chat.SystemMessage)


local ClientCommands = {}

local commandsFolder: Folder?

-- utils
local function createCommand(commandName: string, alias: string): TextChatCommand
    local cmd = Instance.new("TextChatCommand")
    cmd.Name = commandName
    cmd.PrimaryAlias = alias
    cmd.AutocompleteVisible = true
    cmd.Parent = commandsFolder
    return cmd
end

local function connectToTrigger(command: TextChatCommand, callback: (originTextSource: TextSource, unfilteredText: string) -> ()): nil
    command.Triggered:Connect(function(originTextSource: TextSource, unfilteredText: string)
        callback(originTextSource, unfilteredText)
    end)
end

local function muteSound(_originTextSource: TextSource, _unfilteredText: string): nil
    SoundPlayer.setMuted(not SoundPlayer.getIsMuted())
end

local function pracitceAreaToggle()
    if ClientStateTracker.getState() ~= "TUTORIAL" then
        
        RemoteEventHandler.FireOnServer("REQUEST_JOIN_TUTORIAL_AREA")
        print("rah")
    end
end


local function toggleHitboxVisible(_originTextSource: TextSource, _unfilteredText: string): nil
    local hitbox = HitboxManager.getHitbox()
    if not hitbox then
        return
    end
    hitbox.Transparency = (hitbox.Transparency < 1) and 1 or 0.5
end

local function toggleTapDebug(_originTextSource: TextSource, _unfilteredText: string): nil
    TapDebugView.toggle()
end

local function toggleSpectate(_originTextSource: TextSource, _unfilteredText: string): nil
    SpectateController.toggle()
end

local function spectateNext(_originTextSource: TextSource, _unfilteredText: string): nil
    SpectateController.nextIndex()
end

function ClientCommands.init(): nil
    commandsFolder = Instance.new("Folder")
    commandsFolder.Name = "ClientCommands"
    commandsFolder.Parent = TextChatService

    connectToTrigger(createCommand("muteSfx", "/muteSFX"), muteSound)
    connectToTrigger(createCommand("toggleHitboxVisible", "/toggleHitboxVisible"), toggleHitboxVisible)
    connectToTrigger(createCommand("toggleTapDebug", "/toggleTapDebug"), toggleTapDebug)
    connectToTrigger(createCommand("toggleSpectate", "/toggleSpectate"), toggleSpectate)
    connectToTrigger(createCommand("spectateNext", "/spectateNext"), spectateNext)
    connectToTrigger(createCommand("joinTutorial", "/pracitceArea"), pracitceAreaToggle)

    connectToTrigger(createCommand("playTime", "/playTime"), function(originTextSource, unfilteredText)
        
        local playTime = math.floor(SessionVariables.getValue("playTime") or 0)

        SystemMessage.send("Play time: " .. tostring(playTime))
        

    end)

end

return ClientCommands
