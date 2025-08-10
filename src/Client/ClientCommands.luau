
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)
local TextChatService = game:GetService("TextChatService")
local ClientSnowballAnimator = require(ClientModuleDirectory.ClientSnowballAnimator)

local ClientCommands = {}

local function muteSound(originTextSource: TextSource, unfilteredText: string)

    SoundPlayer.setInMuted(not SoundPlayer.getIsMuted())

end

local function snowBallAnims(originTextSource: TextSource, unfilteredText: string)

    ClientSnowballAnimator.toggle()

end

function ClientCommands.init()
    
    local commandsFolder = Instance.new("Folder" , TextChatService) 
    commandsFolder.Name = "Commands"

    local muteCommand = Instance.new("TextChatCommand" , commandsFolder)
    muteCommand.Name = "muteCommand"
    muteCommand.PrimaryAlias = "/muteSFX"
    muteCommand.AutocompleteVisible = true
    muteCommand.Triggered:Connect(muteSound)

    local toggleSnowballAnimations = Instance.new("TextChatCommand" , commandsFolder)
    muteCommand.Name = "toggleSnowballAnim"
    muteCommand.PrimaryAlias = "/toggleSnowballAnims"
    muteCommand.AutocompleteVisible = true
    muteCommand.Triggered:Connect(snowBallAnims)

    local toggleSnowballAnimations = Instance.new("TextChatCommand" , commandsFolder)

end



return ClientCommands