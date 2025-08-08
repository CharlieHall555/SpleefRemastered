local Players = game:GetService("Players")

local PlayerData = {}

local ProfileTemplate = {
	onboardingStep = 0,
	onboardingComplete = true,
	wins = 0,
}

local ProfileService = require(game:GetService("ServerScriptService").External.ProfileStore)

local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local Profiles = {} -- [player] = profile

function PlayerData.onPlayerAdded(player: Player)
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick()
        end)
        if player:IsDescendantOf(Players) == true then
            Profiles[player] = profile
        else
            profile:Release()
        end
    else
        warn("Could not load user profile, User kicked.")
        player:Kick("Could not load profile.")
    end
end

function PlayerData.onPlayerRemoving(player: Player)
    local profile = Profiles[player]
    if profile ~= nil then
        profile:Release()
    end
end

function PlayerData.init() : nil
   
end

function PlayerData.getWins(player : Player) : number
	local profile = Profiles[player]
	if profile == nil then return 0 end	
	return profile.wins or 0
end

function PlayerData.setWins(player : Player , newValue : number) : nil
	local profile = Profiles[player]
	if profile == nil then return end	
	profile.wins = newValue
end

function PlayerData.incrementWins(player : Player , amount : number) : nil
	local starting = PlayerData.getWins(player) or 0
	local profile = Profiles[player]
	if profile == nil then return end	
	profile.wins = starting + amount
end




return PlayerData
