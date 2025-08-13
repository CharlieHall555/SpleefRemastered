local Players = game:GetService("Players")
local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local KickManager = require(ModuleDirectory.Gameplay.KickManager)


local ProfileTemplate = {
    onboardingStep = 0,
    onboardingComplete = false,
    wins = 0
}

local ProfileService = require(game:GetService("ServerScriptService").External.ProfileStore)

local ProfileStore = ProfileService.GetProfileStore("TestDatabase5", ProfileTemplate)

local profiles: { [number]: any } = {}
local loading: { [number]: boolean } = {}
local callback : (playerWhoLoaded : Player) -> (nil)

local PlayerData: PlayerData = {} :: any

function PlayerData.setCallback(fn : (playerWhoLoaded : Player) -> (nil))
    callback = fn
end

function PlayerData.onPlayerAdded(player: Player? )
    local userId = player.UserId
    if profiles[userId] or loading[userId] then
        return
    end

    loading[userId] = true

    task.spawn(function()
        local ok, profile = pcall(function()
            return ProfileStore:LoadProfileAsync("Player_" .. userId)
        end)

        if not ok or profile == nil then
            loading[userId] = nil
            warn("Could not load user profile, user kicked.")
            if player.Parent == Players then
                KickManager.safeKick(player , "Could not load user profile, try again later.")
            end
            return
        end

        profile:AddUserId(userId)
        profile:Reconcile()
        profile:ListenToRelease(function()
            profiles[userId] = nil
            loading[userId] = nil
            if player.Parent == Players then
                KickManager.safeKick(player , "User profile release, Possibly joined from another place?")
            end
        end)

        if player:IsDescendantOf(Players) then
            profiles[userId] = profile
            callback(player)
        else
            profile:Release()
        end

        loading[userId] = nil
    end)
end

function PlayerData.onPlayerRemoving(player: Player)
    local userId = player.UserId
    local profile = profiles[userId]
    if profile ~= nil then
        profile:Release()
    end
    profiles[userId] = nil
    loading[userId] = nil
end

function PlayerData.init(): nil
 
end

function PlayerData.isProfileLoaded(player: Player): boolean
    return profiles[player.UserId] ~= nil
end

function PlayerData.getWins(player: Player): number
    local profile = profiles[player.UserId]
    if profile == nil then
        warn(player.Name .. " profile is nil")
        return 0
    end
    return profile.Data.wins or 0
end

function PlayerData.setWins(player: Player, newValue: number): nil
    local profile = profiles[player.UserId]
    if profile == nil then
        warn(player.Name .. " profile is nil")
        return
    end
    profile.Data.wins = newValue
end

function PlayerData.incrementWins(player: Player, amount: number): nil
    local profile = profiles[player.UserId]
    if profile == nil then
        warn(player.Name .. " profile is nil")
        return
    end
    profile.Data.wins = (profile.Data.wins or 0) + amount
end

function PlayerData.getProfile(player: Player) : {}
    return profiles[player.UserId]
end

return PlayerData