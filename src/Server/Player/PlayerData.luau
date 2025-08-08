local Players = game:GetService("Players")

local PlayerData = {}

local ProfileTemplate = {
	onboardingStep = 0,
	onboardingComplete = "true",
	wins = 0,
}

local ProfileService = require(game:GetService("ServerScriptService").External.ProfileStore)

local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local Profiles = {} -- [player] = profile

function PlayerData.onPlayerAdded(player: Player)
    print("PP0")
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    print("PP1")
    if profile ~= nil then
        print("PP2")
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        profile:ListenToRelease(function()
            Profiles[player.UserId] = nil
            player:Kick()
        end)
        if player:IsDescendantOf(Players) == true then
            print("PROFILES" , Profiles)
            Profiles[player.UserId] = profile
        else
            profile:Release()
        end
    else
        print("PP9")
        warn("Could not load user profile, User kicked.")
        player:Kick("Could not load profile.")
    end
end

function PlayerData.onPlayerRemoving(player: Player)
    local profile = Profiles[player.UserId]
    if profile ~= nil then
        profile:Release()
    end
end

function PlayerData.init() : nil
   
end

function PlayerData.getWins(player : Player) : number
    print(Profiles)
	local profile = Profiles[player.UserId]
	if profile == nil then 
        warn(player.Name .. " Profile is nil")
        return 0 
    end	
    print(profile.Data.wins)
	return profile.Data.wins or 0
end

function PlayerData.setWins(player : Player , newValue : number) : nil
	local profile = Profiles[player.UserId]
	if profile == nil then 
        warn(player.Name .. " Profile is nil")
        return 
    end	
    
	profile.Data.wins = newValue
end

function PlayerData.incrementWins(player : Player , amount : number) : nil
	local starting = PlayerData.getWins(player) or 0
	local profile = Profiles[player.UserId]
	if profile == nil then
        warn(player.Name .. " Profile is nil")
        return
    end	
	profile.Data.wins = starting + amount
end




return PlayerData
