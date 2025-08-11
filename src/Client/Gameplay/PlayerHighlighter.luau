local localPlayer = game.Players.LocalPlayer
local Root = localPlayer.PlayerScripts
local ClientModuleDirectory = require(Root.ClientModuleDirectory)
local RemoteEventHandler = require(ClientModuleDirectory.RemoteEventHandler)

local highlightTemplate : Highlight

local PlayerHighlighter = {}

local highlights : {Highlight} = {}

function PlayerHighlighter.init()
    highlightTemplate = game:GetService("ReplicatedStorage"):WaitForChild("HighlightTemplate")

    RemoteEventHandler.newEventConnection("HIGHLIGHT_PLAYERS" , function(players)
        print("HIGHLIGHT PLAYERS" , players)
        PlayerHighlighter.highlightPlayers(players)
    end)

end

function PlayerHighlighter.highlightPlayer(player: Player)
    -- Check if the player already has a highlight
    if highlights[player] then
        return -- Do nothing if already highlighted
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
