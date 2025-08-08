local ModuleDirectory = require(game:GetService("ServerScriptService").ModuleDirectory)
local RemoteEventHandler = require(ModuleDirectory.RemoteEventHandler)

local TRACKED_STATS = {
    { name = "Wins", dataType = "number" }
}

local DATA_TYPE_TO_CLASS = {
    number = "NumberValue",
    integer = "IntValue",
    string = "StringValue",
    boolean = "BoolValue"
}

local _trackedByName: { [string]: string } = {}
for _, def in ipairs(TRACKED_STATS) do
    _trackedByName[def.name] = def.dataType
end

local function _ensureLeaderstatsFolder(player: Player): Folder
    local folder = player:FindFirstChild("leaderstats")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player
    end
    return folder
end

local function _createStatObject(statName: string, dataType: string)
    local className = DATA_TYPE_TO_CLASS[dataType]
    if not className then
        className = "NumberValue"
    end
    local obj = Instance.new(className)
    obj.Name = statName
    if className == "NumberValue" or className == "IntValue" then
        obj.Value = 0
    elseif className == "StringValue" then
        obj.Value = ""
    elseif className == "BoolValue" then
        obj.Value = false
    end
    return obj
end

local function _coerceValue(dataType: string, newValue: any)
    if dataType == "integer" then
        return tonumber(newValue) and math.floor(tonumber(newValue)) or 0
    elseif dataType == "number" then
        return tonumber(newValue) or 0
    elseif dataType == "boolean" then
        return not not newValue
    elseif dataType == "string" then
        return tostring(newValue or "")
    else
        return newValue
    end
end

local Leaderstats = {}

function Leaderstats.newPlayer(newPlayer: Player): nil
    local folder = _ensureLeaderstatsFolder(newPlayer)
    for _, def in ipairs(TRACKED_STATS) do
        if not folder:FindFirstChild(def.name) then
            local statObj = _createStatObject(def.name, def.dataType)
            statObj.Parent = folder
        end
    end
end

function Leaderstats.updateStat(player: Player, statName: string, newValue: any): nil
    local dataType = _trackedByName[statName]
    if not dataType then
        return
    end

    local folder = _ensureLeaderstatsFolder(player)
    local statObj = folder:FindFirstChild(statName)
    if not statObj then
        statObj = _createStatObject(statName, dataType)
        statObj.Parent = folder
    end

    local ok, coerced = pcall(_coerceValue, dataType, newValue)
    if ok then
        statObj.Value = coerced
    else
        warn("failed to coerce type, Target: " .. dataType .. " Value: ".. newValue)
    end
end

return Leaderstats