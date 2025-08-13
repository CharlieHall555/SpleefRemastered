
local Root = game.Players.LocalPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local SoundPlayer = require(ClientModuleDirectory.SoundPlayer)
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ClientSnowballAnimator = require(ClientModuleDirectory.ClientSnowballAnimator)
local HitboxManager = require(ClientModuleDirectory.HitBoxManager)

local ClientCommands = {}

local function muteSound(originTextSource: TextSource, unfilteredText: string)

    SoundPlayer.setInMuted(not SoundPlayer.getIsMuted())

end

local function snowBallAnims(originTextSource: TextSource, unfilteredText: string)

    ClientSnowballAnimator.toggle()

end

local function toggleHitboxVisible()
    local hitbox = HitboxManager.getHitbox()
    if hitbox then
        
        if hitbox.Transparency < 1 then
            hitbox.Transparency = 1
        else
            hitbox.Transparency = 0.5
        end

    end

end

function ClientCommands.init()
    print("bbb")
    
    local commandsFolder = Instance.new("Folder" , TextChatService) 
    commandsFolder.Name = "Commands"

    local muteCommand = Instance.new("TextChatCommand" , commandsFolder)
    muteCommand.Name = "muteCommand"
    muteCommand.PrimaryAlias = "/muteSFX"
    muteCommand.AutocompleteVisible = true
    muteCommand.Triggered:Connect(muteSound)

    local toggleSnowballAnimations = Instance.new("TextChatCommand" , commandsFolder)
    toggleSnowballAnimations.Name = "toggleSnowballAnim"
    toggleSnowballAnimations.PrimaryAlias = "/toggleSnowballAnims"
    toggleSnowballAnimations.AutocompleteVisible = true
    toggleSnowballAnimations.Triggered:Connect(snowBallAnims)

    local toggleSnowballAnimations = Instance.new("TextChatCommand" , commandsFolder)
    toggleSnowballAnimations.Name = "toggleHitboxVisible"
    toggleSnowballAnimations.PrimaryAlias = "/toggleHitboxVisible"
    toggleSnowballAnimations.AutocompleteVisible = true
    toggleSnowballAnimations.Triggered:Connect(toggleHitboxVisible)

end



return ClientCommands