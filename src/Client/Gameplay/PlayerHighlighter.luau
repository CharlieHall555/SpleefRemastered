local localPlayer = game.Players.LocalPlayer
local Root = localPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)
local ClientStateTracker = require(ClientModuleDirectory.ClientStateTracker)

local highlightTemplate : Highlight

local PlayerHighlighter = {}

local highlights : {Highlight} = {}

function PlayerHighlighter.init()
    highlightTemplate = game:GetService("ReplicatedStorage"):WaitForChild("HighlightTemplate")

    RemoteEventHandler.newEventConnection("SEND_STARTING_PLAYERS" , function(players)
        print("HIGHLIGHT PLAYERS" , players)
        PlayerHighlighter.highlightPlayers(players)
    end)

    RemoteEventHandler.newEventConnection("SEND_STARTING_AGENTS" , function(agentModels : {Model})
        

        for _ , eachModel in agentModels do
            
            PlayerHighlighter.highlightModel(eachModel)

        end
        
    end)

    RemoteEventHandler.newEventConnection("REHIGHLIGHT_PLAYERS" , function(players)
        PlayerHighlighter.highlightPlayers(players)
    end)

    RemoteEventHandler.newEventConnection("PLAYER_REVIVED" , function(player)
        if ClientStateTracker.getState() == "ACTIVE" then
            PlayerHighlighter.highlightPlayer(player)
        end
    end)

    ClientStateTracker.connectIntermission(function()
        PlayerHighlighter.reset()
    end)

end

function PlayerHighlighter.highlightPlayer(player: Player)
    -- Check if the player already has a highlight
    if highlights[player] then
        pcall(function()
            highlights[player]:Destroy()
            highlights[player] = nil
        end)
        warn("Player " .. player.Name .. " is already highlighted.")
    end

    local character = player.Character
    if character then
        -- Clone the template and set its parent
        local newHighlight = highlightTemplate:Clone()
        newHighlight.Parent = localPlayer.PlayerGui
        newHighlight.Adornee = character
        newHighlight.Enabled = true

        highlights[player] = newHighlight
    end
end

function PlayerHighlighter.highlightModel(model : Model)
    -- Check if the model already has a highlight
    if highlights[model] then
        pcall(function()
            highlights[model]:Destroy()
            highlights[model] = nil
        end)
        warn("Model " .. model.Name .. " is already highlighted.")
    end

    -- Clone the template and set its parent
    local newHighlight = highlightTemplate:Clone()
    newHighlight.Parent = localPlayer.PlayerGui
    newHighlight.Adornee = model
    newHighlight.Enabled = true

    highlights[model] = newHighlight
end

function PlayerHighlighter.highlightPlayers(players: {Player})
    for _, player in ipairs(players) do
        if player == localPlayer then
            continue 
        end
        PlayerHighlighter.highlightPlayer(player)
    end
end

function PlayerHighlighter.unhighlightPlayer(player: Player)
    -- Check if the player has a highlight to remove
    local existingHighlight = highlights[player]
    if existingHighlight then
        existingHighlight:Destroy()
        highlights[player] = nil -- Remove the reference from our table
    end
end

function PlayerHighlighter.reset()
    for _, highlight in pairs(highlights) do
        highlight:Destroy()
    end
    highlights = {} -- Clear the entire table
end

return PlayerHighlighter
