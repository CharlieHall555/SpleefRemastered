local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local PlayerSessionVariables = require(ModuleDirectory.Player.SessionVariables)


local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Onboarding = {}

local callback : ((player : Player , newStep : number) -> nil)?

export type Action = "JOINED_GAME" | "JOINED_ROUND" | "SHOT" | "SNOWBALL_BROKEN_BLOCK" | "WON" | "SPADE_BROKEN_BLOCK"

local numberOfSteps = 5

export type Progress = {
    step: number,
    hasJoinedGame: boolean,
    hasJoinedRound: boolean,
    hasBrokenBlockWithSpade : boolean,
    hasShot: boolean,
    hasBrokenBlockWithSnowball: boolean,
    hasWon: boolean
}

local _progressByUserId: { [number]: Progress } = {}

-- Map actions to progress field names
local ACTION_TO_FIELD: { [Action]: string } = {
    JOINED_GAME = "hasJoinedGame",
    JOINED_ROUND = "hasJoinedRound",
    SPADE_BROKEN_BLOCK = "hasBrokenBlockWithSpade",
    SHOT = "hasShot",
    SNOWBALL_BROKEN_BLOCK = "hasBrokenBlockWithSnowball",
    WON = "hasWon"
}

-- Map actions to display names
local ACTION_TO_STEP_NAME: { [Action]: string } = {
    JOINED_GAME = "Joined Game",
    JOINED_ROUND = "Joined Round",
    SPADE_BROKEN_BLOCK = "Broke Block With Spade",
    SHOT = "First Shot",
    SNOWBALL_BROKEN_BLOCK = "Broke Block With Snowball",
    WON = "Won Round"
}

-- Fixed step ordering so we can handle out-of-order completion
local ACTION_TO_STEP_NUMBER: { [Action]: number } = {
    JOINED_GAME = 1,
    JOINED_ROUND = 2,
    SPADE_BROKEN_BLOCK = 3,
    SHOT = 4,
    SNOWBALL_BROKEN_BLOCK = 5,
    WON = 6
}

local function getOrCreateProgress(userId: number, defaultStep: number?): Progress
    local p = _progressByUserId[userId]
    if p then
        return p
    end
    p = {
        step = defaultStep or 1,
        hasJoinedGame = false,
        hasJoinedRound = false,
        hasShot = false,
        hasBrokenBlock = false,
        hasWon = false
    }
    _progressByUserId[userId] = p
    return p
end

local function logStep(player: Player, stepNumber: number, stepName: string, customFields: { [string]: any }?)
    local ok, err = pcall(function()
        AnalyticsService:LogOnboardingFunnelStepEvent(
            player,
            stepNumber,
            stepName,
            customFields
        )
    end)
    if not ok then
        warn("[Onboarding] Failed to log onboarding funnel step:", err)
    else
        print(player , stepNumber , stepNumber)

        if callback then
            print(stepNumber)
            callback(player , stepNumber)
        end
    end
end

function Onboarding.init()
    table.clear(_progressByUserId)

    Players.PlayerRemoving:Connect(Onboarding.cleanUpUser)
end

function Onboarding.registerUser(player: Player, previousStep: number?)
    getOrCreateProgress(player.UserId, previousStep or 1)
end

function Onboarding.getStep(player: Player): number?
    local progress = _progressByUserId[player.UserId]
    if progress == nil then
        return nil
    else
        return progress.step
    end
end

function Onboarding.action(player: Player, newAction: Action, customFields: { [string]: any }?)
    if not player or not player.Parent then
        return
    end
    customFields = customFields or {}

    local progress = _progressByUserId[player.UserId]
    if progress == nil then
        print("user not registered for noboarding")
        return
    end
    local field = ACTION_TO_FIELD[newAction]
    local stepNumber = ACTION_TO_STEP_NUMBER[newAction]
    local stepName = ACTION_TO_STEP_NAME[newAction] or ("Step " .. tostring(stepNumber))

    if not field or not stepNumber then
        return
    end

    -- Mark the step complete if not already
    if not progress[field] then
        progress[field] = true

        -- Advance stored step if this step is ahead of current
        if stepNumber > progress.step then
            progress.step = stepNumber
        end

        local SessionVariables = PlayerSessionVariables.get(player) or {}
        customFields.platform = SessionVariables.platform or "UNKNOWN"
        logStep(player, stepNumber, stepName, customFields)
    end
end

function Onboarding.completeStep(player: Player, stepNumber: number, customFields: { [string]: any }?)
    if not player or not player.Parent then
        return
    end
    for action, num in pairs(ACTION_TO_STEP_NUMBER) do
        if num == stepNumber then
            return Onboarding.action(player, action :: Action, customFields)
        end
    end
end

function Onboarding.cleanUpUser(player: Player)
    if not player then
        return
    end
    _progressByUserId[player.UserId] = nil
end

function Onboarding.setCallback(fn : (player : Player , newStep : number) -> nil)
    callback = fn
end

function Onboarding.getNumberOfSteps() : number
    return numberOfSteps
end



return Onboarding
