export type NumberConstraint = {
    type: "number",
    min: number?,
    max: number?
}

export type WhitelistConstraint = {
    type: "whitelist",
    allowedValues: { any }
}

export type StringConstraint = {
    type: "string"
}

export type BoolConstraint = {
    type: "boolean"
}

export type FieldConstraint = NumberConstraint | WhitelistConstraint | StringConstraint | BoolConstraint


local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local KickManager = require(ModuleDirectory.Gameplay.KickManager)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local ProfileTemplate = {
    onboardingStep = 0,
    onboardingComplete = false,
    shovel = "DEFAULT",
    xp = 0,
    coins = 0,
    level = 1,
    respawns = 0,
    wins = 0,
    roundsPlayed = 0,
    hasJoinedBefore = false
}

local ProfileService = require(game:GetService("ServerScriptService").External.ProfileStore)

local database = "PRODUCTION"
if RunService:IsStudio() then
    database = "TEST15"
else
    database = "PRODUCTION"
end

local ProfileStore = ProfileService.GetProfileStore(database, ProfileTemplate)

local profiles: { [number]: any } = {}
local loading: { [number]: boolean } = {}

local fieldConstraints: { [string]: FieldConstraint } = {}

local function normalizeConstraint(constraint: any): FieldConstraint?
    local ctype = constraint and constraint.type
    if ctype == "number" then
        return {
            type = "number",
            min = constraint.min,
            max = constraint.max
        }
    elseif ctype == "string" then
        return { type = "string" }
    elseif ctype == "boolean" then
        return { type = "boolean" }
    elseif ctype == "whitelist" or constraint.allowedValue ~= nil or constraint.allowedValues ~= nil then
        local list = constraint.allowedValues or constraint.allowedValue
        if type(list) ~= "table" then
            return nil
        end
        return {
            type = "whitelist",
            allowedValues = list
        }
    end
    return nil
end

local function getTemplateDefault(fieldName: string): any
    return (ProfileTemplate :: any)[fieldName]
end

local function applyConstraint(fieldName: string, value: any): any
    local constraint = fieldConstraints[fieldName]
    if not constraint then
        return value
    end

    if constraint.type == "number" then
        if typeof(value) ~= "number" then
            local fallback = getTemplateDefault(fieldName)
            if typeof(fallback) == "number" then
                value = fallback
            else
                return nil
            end
        end
        if constraint.min ~= nil and value < constraint.min then
            value = constraint.min
        end
        if constraint.max ~= nil and value > constraint.max then
            value = constraint.max
        end
        return value
    elseif constraint.type == "string" then
        if typeof(value) ~= "string" then
            local fallback = getTemplateDefault(fieldName)
            if typeof(fallback) == "string" then
                return fallback
            end
            return tostring(value)
        end
        return value
    elseif constraint.type == "boolean" then
        if typeof(value) ~= "boolean" then
            return value == true
        end
        return value
    elseif constraint.type == "whitelist" then
        local list = constraint.allowedValues
        for _, v in ipairs(list) do
            if v == value then
                return value
            end
        end
        return list[1]
    end

    return value
end

local function parseProfile(profileData: {}): nil
    for fieldName, current in pairs(profileData) do
        local coerced = applyConstraint(fieldName, current)
        if coerced ~= nil then
            (profileData :: any)[fieldName] = coerced
        end
    end
end

local callback: (playerWhoLoaded: Player) -> nil = function() end

local ProfileManager = {} :: any

function ProfileManager.setField(userId: number, fieldName: string, fieldValue: any): boolean
    local profile = profiles[userId]
    if not profile then
        return false
    end

    local newValue = applyConstraint(fieldName, fieldValue)
    if newValue == nil then
        return false
    end

    profile.Data[fieldName] = newValue
    return true
end

function ProfileManager.setFieldConstraint(fieldName: string, constraint: FieldConstraint): boolean
    local normalized = normalizeConstraint(constraint)
    if not normalized then
        return false
    end
    fieldConstraints[fieldName] = normalized

    -- backfill any loaded profiles to comply immediately
    for _, profile in pairs(profiles) do
        local current = profile.Data[fieldName]
        if current ~= nil then
            local coerced = applyConstraint(fieldName, current)
            if coerced ~= nil then
                profile.Data[fieldName] = coerced
            end
        end
    end

    return true
end

function ProfileManager.setCallback(fn: (playerWhoLoaded: Player) -> nil)
    callback = fn
end

function ProfileManager.onPlayerAdded(player: Player)
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
                KickManager.safeKick(player, "Could not load user profile, try again later.")
            end
            return
        end

        profile:AddUserId(userId)
        profile:Reconcile()

        -- enforce constraints on load
        if profile.Data then
            parseProfile(profile.Data)
        end

        profile:ListenToRelease(function()
            profiles[userId] = nil
            loading[userId] = nil
            if player.Parent == Players then
                KickManager.safeKick(player, "User profile released. Possibly joined from another place.")
            end
        end)

        if player:IsDescendantOf(Players) then
            profiles[userId] = profile
            if callback then
                callback(player)
            end
        else
            profile:Release()
        end

        loading[userId] = nil
    end)
end

function ProfileManager.onPlayerRemoving(player: Player)
    local userId = player.UserId
    local profile = profiles[userId]
    if profile ~= nil then
        profile:Release()
    end
    profiles[userId] = nil
    loading[userId] = nil
end

function ProfileManager.init(): nil
    RemoteEventHandler.newEventConnection("QUERY_PROFILE_DATA", function(player: Player)
        if ProfileManager.isProfileLoaded(player) then
            local profile = profiles[player.UserId]
            return HttpService:JSONEncode(profile.Data or {})
        end
        return HttpService:JSONEncode({})
    end)
end

function ProfileManager.isProfileLoaded(player: Player): boolean
    return profiles[player.UserId] ~= nil
end

function ProfileManager.getProfile(player: Player) : {}
    return profiles[player.UserId]
    
end

return ProfileManager

-- Suggestions:
-- - Consider adding explicit getters for fields to reduce direct Data access.
-- - Split constraint logic into a dedicated Utility module if reused elsewhere.
-- - Add persistence hooks or throttled manual save calls if ProfileService library supports them.
