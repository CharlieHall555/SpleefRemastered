local AnalyticsService = game:GetService("AnalyticsService")

local EventAnalytics = {}

function EventAnalytics.logEvent(player: Player, eventName: string, data: {[string]: any}?)
    if not player or not player:IsDescendantOf(game.Players) then
        warn("[EventAnalytics] Invalid player provided for event:", eventName)
        return
    end
    if typeof(eventName) ~= "string" then
        warn("[EventAnalytics] Event name must be a string")
        return
    end

    local success, err = pcall(function()
        AnalyticsService:LogCustomEvent(player, eventName, data or {})
    end)

    if not success then
        warn("[EventAnalytics] Failed to log event:", eventName, "-", err)
    end
end

return EventAnalytics